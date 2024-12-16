import 'dart:collection';
import 'dart:typed_data';

class ImageCacheEntry {
  final Uint8List data;
  DateTime lastAccessed;
  bool isVisible;
  int accessCount;

  ImageCacheEntry(this.data, {this.isVisible = false})
      : lastAccessed = DateTime.now(),
        accessCount = 0;

  int get size => data.lengthInBytes;

  void updateAccess() {
    lastAccessed = DateTime.now();
    accessCount++;
  }
}

class LRUMap<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();
  final Duration _maxAge;

  LRUMap(this._maxSize, {Duration? maxAge})
      : _maxAge = maxAge ?? const Duration(days: 1);

  V? operator [](K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void operator []=(K key, V value) {
    if (_map.length >= _maxSize) {
      _evictOldest();
    }
    _map[key] = value;
  }

  void _evictOldest() {
    if (_map.isEmpty) return;

    // Check if we're storing ImageCacheEntry objects by looking at the first value
    if (_map.values.isNotEmpty && _map.values.first is ImageCacheEntry) {
      final entries = _map.entries.toList();
      entries.sort((a, b) {
        final aEntry = a.value as ImageCacheEntry;
        final bEntry = b.value as ImageCacheEntry;

        if (aEntry.isVisible != bEntry.isVisible) {
          return aEntry.isVisible ? 1 : -1;
        }

        final aAge = DateTime.now().difference(aEntry.lastAccessed);
        final bAge = DateTime.now().difference(bEntry.lastAccessed);

        if (aAge > _maxAge && bAge > _maxAge) {
          return bEntry.accessCount - aEntry.accessCount;
        }

        return aAge.compareTo(bAge);
      });

      _map.remove(entries.first.key);
    } else {
      _map.remove(_map.keys.first);
    }
  }

  bool containsKey(K key) => _map.containsKey(key);
  V? remove(K key) => _map.remove(key);
  Iterable<K> get keys => _map.keys;
  void clear() => _map.clear();
  int get length => _map.length;
}
