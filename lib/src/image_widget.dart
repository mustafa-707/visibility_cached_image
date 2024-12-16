import 'dart:async';
import 'dart:developer' as console;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:visibility_cached_image/src/config.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/services.dart';
import 'package:async/async.dart';

import 'package:dio/dio.dart';

class VisibilityCachedImage extends HookWidget {
  final String imageUrl;
  final String? assetPath;
  final Map<String, String>? headers;
  final Widget Function(BuildContext, double)? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? cacheHeight;
  final int? cacheWidth;
  final bool disableVisibility;

  const VisibilityCachedImage({
    super.key,
    this.imageUrl = '',
    this.assetPath,
    this.headers,
    this.loadingBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit,
    this.cacheHeight,
    this.cacheWidth,
    this.disableVisibility = false,
  }) : assert(
          imageUrl != '' || assetPath != null,
          'Either imageUrl or assetPath must be provided.',
        );

  @override
  Widget build(BuildContext context) {
    final image = useState<Uint8List?>(null);
    final error = useState<String?>(null);
    final progress = useState(0.0);
    final isVisible = useState(false);
    final loadTask = useState<CancelableOperation<void>?>(null);
    final isMounted = useRef(true);

    useEffect(() {
      isMounted.value = true;
      return () {
        isMounted.value = false;
        loadTask.value?.cancel();
      };
    }, []);

    if (disableVisibility && image.value == null && error.value == null) {
      loadTask.value?.cancel();
      loadTask.value = CancelableOperation.fromFuture(
        _loadImageIfNeeded(
          image: image,
          error: error,
          progress: progress,
          isVisible: isVisible,
          isMounted: isMounted,
        ),
      );
    }

    void onVisibilityChanged(VisibilityInfo info) {
      if (!isMounted.value || disableVisibility) return;

      final visible = info.visibleFraction > 0;
      if (visible != isVisible.value) {
        isVisible.value = visible;

        if (visible) {
          if (image.value == null && error.value == null) {
            loadTask.value?.cancel();
            loadTask.value = CancelableOperation.fromFuture(
              _loadImageIfNeeded(
                image: image,
                error: error,
                progress: progress,
                isVisible: isVisible,
                isMounted: isMounted,
              ),
            );
          }
        } else {
          loadTask.value?.cancel();
          loadTask.value = null;
        }
      }
    }

    return VisibilityDetector(
      key: ValueKey(imageUrl.isNotEmpty ? imageUrl : assetPath),
      onVisibilityChanged: disableVisibility ? null : onVisibilityChanged,
      child: _buildImage(
        context,
        image.value,
        error.value,
        progress.value,
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    Uint8List? image,
    String? errorMsg,
    double progress,
  ) {
    if (errorMsg != null && errorBuilder != null) {
      return errorBuilder!(context, Exception(errorMsg), StackTrace.current);
    }

    if (assetPath != null) {
      return Image.memory(
        image ?? Uint8List(0),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        cacheHeight: cacheHeight,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      );
    }

    if (image == null) {
      return loadingBuilder?.call(context, progress) ??
          Center(
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2,
            ),
          );
    }

    return RepaintBoundary(
      child: Image.memory(
        image,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        cacheHeight: cacheHeight,
        cacheWidth: cacheWidth,
        errorBuilder: assetPath != null
            ? (context, __, ___) =>
                loadingBuilder?.call(context, progress) ??
                Center(
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 2,
                  ),
                )
            : errorBuilder,
      ),
    );
  }

  Future<void> _loadImageIfNeeded({
    required ValueNotifier<Uint8List?> image,
    required ValueNotifier<String?> error,
    required ValueNotifier<double> progress,
    required ValueNotifier<bool> isVisible,
    required ObjectRef<bool> isMounted,
  }) async {
    if (!isMounted.value || !isVisible.value) return;

    try {
      if (assetPath != null) {
        final byteData = await rootBundle.load(assetPath!);
        final bytes = byteData.buffer.asUint8List();
        image.value = bytes;
        return;
      }

      final cachedImage = await VisibilityCacheImageConfig.getImage(
        imageUrl,
        isVisible: true,
      );

      if (cachedImage != null) {
        image.value = cachedImage;
        return;
      }

      final result = await VisibilityCacheImageConfig.requestQueue.enqueue(
        () async {
          if (!isMounted.value || !isVisible.value) return null;

          try {
            final stream = await VisibilityCacheImageConfig.dio.get<List<int>>(
              imageUrl,
              options: Options(
                responseType: ResponseType.bytes,
                headers: headers,
                sendTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
              onReceiveProgress: (received, total) {
                if (isMounted.value && total > 0) {
                  progress.value = received / total;
                }
              },
            );

            if (!isMounted.value || !isVisible.value) return null;

            return stream.data;
          } catch (e) {
            error.value = 'Failed to load image from network: $e';
            console.log('Dio error loading image: $imageUrl - $e');
            return null;
          }
        },
      );

      if (result != null && isMounted.value && isVisible.value) {
        final bytes = Uint8List.fromList(result);
        image.value = bytes;
        unawaited(VisibilityCacheImageConfig.saveImage(imageUrl, bytes));
      }
    } catch (e) {
      if (isMounted.value && isVisible.value) {
        error.value = 'Error loading image: $e';
        console.log('Error loading image: $imageUrl - $e');
      }
    }
  }
}
