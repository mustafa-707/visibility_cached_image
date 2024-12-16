import 'dart:async';
import 'dart:collection';
import 'dart:math';

class _QueueItem {
  final Future Function() task;
  final Completer completer;

  _QueueItem(this.task, this.completer);
}

enum LoadingType { sequential, random, all, noQueue }

class ImageRequestQueue {
  static final ImageRequestQueue _instance = ImageRequestQueue._internal();
  factory ImageRequestQueue() => _instance;

  ImageRequestQueue._internal({
    int maxConcurrent = 2,
    LoadingType loadingType = LoadingType.sequential,
  }) {
    _maxConcurrent = maxConcurrent;
    _loadingType = loadingType;
  }

  final _queue = Queue<_QueueItem>();
  int _currentRequests = 0;
  late int _maxConcurrent;
  late LoadingType _loadingType;
  bool _isStopped = false;

  set maxConcurrent(int value) {
    if (value > 0) {
      _maxConcurrent = value;
      _processQueue();
    }
  }

  set loadingType(LoadingType value) {
    _loadingType = value;
  }

  set isStopped(bool value) {
    _isStopped = value;
  }

  Future<T> enqueue<T>(Future<T> Function() task) {
    if (_isStopped) {
      return Future.error('Queue is stopped');
    }

    final completer = Completer<T>();
    _queue.add(_QueueItem(task, completer));

    if (_loadingType != LoadingType.noQueue) {
      _processQueue();
    } else {
      _processImmediate();
    }

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_currentRequests >= _maxConcurrent || _isStopped) return;

    if (_loadingType == LoadingType.sequential) {
      await _processSequential();
    } else if (_loadingType == LoadingType.random) {
      await _processRandom();
    } else if (_loadingType == LoadingType.all) {
      await _processAll();
    }
  }

  /// Processes tasks sequentially, one after another
  Future<void> _processSequential() async {
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

    if (_queue.isNotEmpty && !_isStopped) {
      _processQueue();
    }
  }

  /// Randomly selects tasks from the queue and executes them
  Future<void> _processRandom() async {
    final random = Random();

    while (_queue.isNotEmpty && _currentRequests < _maxConcurrent) {
      final randomIndex = random.nextInt(_queue.length);
      final item = _queue.elementAt(randomIndex);
      _queue.remove(item); // Remove the random item from the queue
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

    if (_queue.isNotEmpty && !_isStopped) {
      _processQueue();
    }
  }

  /// Processes multiple tasks concurrently, up to the max limit
  Future<void> _processAll() async {
    final tasksToProcess = <_QueueItem>[];

    while (_queue.isNotEmpty && _currentRequests < _maxConcurrent) {
      final item = _queue.removeFirst();
      tasksToProcess.add(item);
      _currentRequests++;
    }

    final futures = tasksToProcess.map((item) {
      return item.task().then((result) {
        item.completer.complete(result);
      }).catchError((e) {
        item.completer.completeError(e);
      }).whenComplete(() {
        _currentRequests--;
      });
    }).toList();

    await Future.wait(futures);

    if (_queue.isNotEmpty && !_isStopped) {
      _processQueue();
    }
  }

  Future<void> _processImmediate() async {
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
  }
}
