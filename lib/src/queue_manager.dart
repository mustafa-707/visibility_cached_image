import 'dart:async';
import 'dart:collection';
import 'dart:math';

class _QueueItem {
  final Future Function() task;
  final Completer completer;

  _QueueItem(this.task, this.completer);
}

enum LoadingType { sequential, random, all }

class ImageRequestQueue {
  static final ImageRequestQueue _instance = ImageRequestQueue._internal();
  factory ImageRequestQueue() => _instance;

  ImageRequestQueue._internal({
    int maxConcurrent = 32,
    LoadingType loadingType = LoadingType.sequential,
  }) {
    _maxConcurrent = maxConcurrent;
    _loadingType = loadingType;
  }

  final _queue = Queue<_QueueItem>();
  bool _processing = false;
  late int _maxConcurrent;
  int _currentRequests = 0;
  late LoadingType _loadingType;

  set maxConcurrent(int value) {
    if (value > 0) {
      _maxConcurrent = value;
      _processQueue();
    }
  }

  set loadingType(LoadingType value) {
    _loadingType = value;
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

    if (_loadingType == LoadingType.sequential) {
      await _processSequential();
    } else if (_loadingType == LoadingType.random) {
      await _processRandom();
    } else if (_loadingType == LoadingType.all) {
      await _processAll();
    }

    _processing = false;
  }

  Future<void> _processSequential() async {
    // Process tasks one by one (sequential)
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

    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }

  Future<void> _processRandom() async {
    // Process tasks randomly
    final random = Random();
    while (_queue.isNotEmpty && _currentRequests < _maxConcurrent) {
      final randomIndex = random.nextInt(_queue.length);
      final item = _queue.elementAt(randomIndex);
      _queue.remove(item); // Remove the item from the queue
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

    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }

  Future<void> _processAll() async {
    // Process all tasks concurrently up to the max limit
    final tasksToProcess = <_QueueItem>[];
    while (_queue.isNotEmpty && _currentRequests < _maxConcurrent) {
      final item = _queue.removeFirst();
      tasksToProcess.add(item);
      _currentRequests++;
    }

    // Run all selected tasks concurrently
    final futures = tasksToProcess.map((item) {
      return item.task().then((result) {
        item.completer.complete(result);
      }).catchError((e) {
        item.completer.completeError(e);
      }).whenComplete(() {
        _currentRequests--;
      });
    }).toList();

    // Wait for all tasks to finish
    await Future.wait(futures);

    // Continue processing the queue if there are more tasks
    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }
}
