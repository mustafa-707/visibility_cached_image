import 'dart:developer' as console;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_cached_image/src/lru.dart';
import 'package:visibility_cached_image/src/queue_manager.dart';

class VisibilityCacheImageConfig {
  static LazyBox? _imageKeyBox;
  static LazyBox? _imageBox;
  static bool _isInitialized = false;
  static LRUMap<String, ImageCacheEntry> _memoryCache = LRUMap(128);
  static const _maxMemoryCacheSize = 64 * 1024 * 1024;
  static int _currentMemorySize = 0;
  static late ImageRequestQueue requestQueue;
  static late Dio dio;

  static Future<void> init({
    String? subDir,
    Duration? clearCacheAfter,
    int? maxMemoryCacheEntries,
    Dio? dioInstance,
    int? maxConcurrentRequests,
  }) async {
    if (_isInitialized) return;
    dio = dioInstance ?? Dio();
    clearCacheAfter ??= const Duration(days: 30);
    requestQueue = ImageRequestQueue();

    if (maxConcurrentRequests != null) {
      requestQueue.maxConcurrent = maxConcurrentRequests;
    }

    _memoryCache = maxMemoryCacheEntries == null
        ? _memoryCache
        : LRUMap(
            maxMemoryCacheEntries,
          );

    await Hive.initFlutter(subDir);
    _imageKeyBox = await Hive.openLazyBox('cachedImagesKeys');
    _imageBox = await Hive.openLazyBox('cachedImages');
    _isInitialized = true;

    _clearOldCache(clearCacheAfter);
  }

  static Future<Uint8List?> getImage(String url,
      {bool isVisible = false}) async {
    _checkInit();
    final key = _keyFromUrl(url);

    final entry = _memoryCache[key];
    if (entry != null) {
      entry.updateAccess();
      entry.isVisible = isVisible;
      return entry.data;
    }

    final image = await _getFromDisk(url);
    if (image != null) {
      _addToMemoryCache(url, image, isVisible: isVisible);
      return image;
    }

    return null;
  }

  static Future<Uint8List?> _getFromDisk(String url) async {
    final key = _keyFromUrl(url);
    if (_imageBox!.containsKey(key)) {
      try {
        final data = await _imageBox!.get(key);
        return data is Uint8List ? data : null;
      } catch (e) {
        console.log('Error reading from disk cache: $e');
        return null;
      }
    }
    return null;
  }

  static void _addToMemoryCache(String url, Uint8List image,
      {bool isVisible = false}) {
    final entry = ImageCacheEntry(image, isVisible: isVisible);
    if (_canAddToMemoryCache(entry.size)) {
      _ensureMemorySpace(entry.size);
      _memoryCache[url] = entry;
      _currentMemorySize += entry.size;
    }
  }

  static bool _canAddToMemoryCache(int size) {
    return size > 0 && size <= _maxMemoryCacheSize * 0.4;
  }

  static void _ensureMemorySpace(int requiredSize) {
    while (_currentMemorySize + requiredSize > _maxMemoryCacheSize) {
      if (_memoryCache.length == 0) break;
      final oldestKey = _memoryCache.keys.first;
      final oldestEntry = _memoryCache.remove(oldestKey);
      if (oldestEntry != null) {
        _currentMemorySize -= oldestEntry.size;
      }
    }
  }

  static Future<void> saveImage(String url, Uint8List bytes) async {
    final key = _keyFromUrl(url);
    await _imageBox?.put(key, bytes);
    await _imageKeyBox?.put(key, DateTime.now());
    _addToMemoryCache(url, bytes);
  }

  static Future<void> deleteCachedImage(String url) async {
    _checkInit();
    final key = _keyFromUrl(url);
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      _currentMemorySize -= entry.size;
    }
    await Future.wait([
      _imageKeyBox?.delete(key) ?? Future.value(),
      _imageBox?.delete(key) ?? Future.value(),
    ]);
  }

  static Future<void> _compactAllBoxes() async {
    await Future.wait([
      _imageKeyBox?.compact() ?? Future.value(),
      _imageBox?.compact() ?? Future.value(),
    ]);
  }

  static Future<void> clearAllCachedImages() async {
    _checkInit();
    await _compactAllBoxes();
    _memoryCache.clear();
    _currentMemorySize = 0;
    await Future.wait([
      _imageKeyBox?.deleteFromDisk() ?? Future.value(),
      _imageBox?.deleteFromDisk() ?? Future.value(),
    ]);
    _imageKeyBox = await Hive.openLazyBox('cachedImagesKeys');
    _imageBox = await Hive.openLazyBox('cachedImages');
  }

  static Future<void> _clearOldCache(Duration clearCacheAfter) async {
    final now = DateTime.now();
    await _compactAllBoxes();

    final futures = _imageKeyBox!.keys.map((key) async {
      final dateCreated = await _imageKeyBox!.get(key);
      if (dateCreated != null &&
          now.difference(dateCreated) > clearCacheAfter) {
        await deleteCachedImage(key as String);
      }
    });

    await Future.wait(futures);
  }

  static void _checkInit() {
    if (!_isInitialized || _imageKeyBox == null || _imageBox == null) {
      throw Exception(
        'AppCacheImageConfig is not initialized. Please call AppCacheImageConfig.init.',
      );
    }
  }

  static String _keyFromUrl(String url) =>
      const Uuid().v5(Namespace.dns.value, url);
}
