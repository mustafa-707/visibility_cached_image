import 'dart:async';
import 'dart:collection';

class _QueueItem {
  final Future Function() task;
  final Completer completer;

  _QueueItem(this.task, this.completer);
}

class ImageRequestQueue {
  static final ImageRequestQueue _instance = ImageRequestQueue._internal();
  factory ImageRequestQueue() => _instance;
  ImageRequestQueue._internal({int maxConcurrent = 32}) {
    _maxConcurrent = maxConcurrent;
  }

  final _queue = Queue<_QueueItem>();
  bool _processing = false;
  late int _maxConcurrent;
  int _currentRequests = 0;

  set maxConcurrent(int value) {
    if (value > 0) {
      _maxConcurrent = value;
      _processQueue();
    }
  }

  Future<T> enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue.add(_QueueItem(task, completer));
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_processing || _currentRequests >= _maxConcurrent) return;
    _processing = true;

    while (_queue.isNotEmpty && _currentRequests < _maxConcurrent) {
      final item = _queue.removeFirst();
      _currentRequests++;

      try {
        final result = await item.task();
        item.completer.complete(result);
      } catch (e) {
        item.completer.completeError(e);
      } finally {
        _currentRequests--;
      }
    }

    _processing = false;
    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }
}
