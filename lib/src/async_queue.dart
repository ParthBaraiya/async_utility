import 'dart:async';

typedef AsyncQueueCallback<T> = Future<T?> Function();

enum CallbackReplacementPolicy {
  /// Ignore the upcoming invocation.
  ignore,

  /// Replace the callback added at first in the queue.
  ///
  /// This does not cancels the running callback. It replaces the next execution
  /// with current one.
  ///
  replaceFirst,

  /// Replace the callback added at last in the queue.
  replaceLast,
}

class AsyncQueue {
  final CallbackReplacementPolicy defaultReplacementPolicy;

  /// Maximum size of the callback that can be queued.
  /// If the queue is running, total number of callbacks will be,
  /// queue.length + 1.
  ///
  final int maxSize;

  AsyncQueue({
    this.defaultReplacementPolicy = CallbackReplacementPolicy.replaceLast,
    this.maxSize = 0,
  });

  final _queue = <_AsyncMethodRequest>[];

  _AsyncMethodRequest? _current;

  Future<T?> invoke<T>(AsyncQueueCallback<T> callback,
      {CallbackReplacementPolicy? replacement}) {
    final completer = Completer<T>();

    if (maxSize < 1 || _queue.length < maxSize) {
      _queue.add(_AsyncMethodRequest(
        callback: callback,
        completer: completer,
      ));
    } else {
      switch (replacement ?? defaultReplacementPolicy) {
        case CallbackReplacementPolicy.replaceFirst:
          _queue.removeAt(0);
          _queue.insert(
            0,
            _AsyncMethodRequest(
              callback: callback,
              completer: completer,
            ),
          );

          break;
        case CallbackReplacementPolicy.replaceLast:
          _queue.removeLast();
          _queue.add(_AsyncMethodRequest(
            callback: callback,
            completer: completer,
          ));

          break;
        case CallbackReplacementPolicy.ignore:
          completer.complete();
          break;
      }
    }

    if (_queue.isNotEmpty && _current == null) {
      _runQueue();
    }

    return completer.future;
  }

  Future<void> _runQueue() async {
    if (_current == null) return;

    while (_queue.isNotEmpty) {
      _current = _queue.first;
      _queue.removeLast();

      try {
        final result = await _current!.callback();

        if (_current != null && !_current!.completer.isCompleted) {
          _current!.completer.complete(result);
        }
      } catch (e, stack) {
        if (_current != null && !_current!.completer.isCompleted) {
          _current!.completer.completeError(e, stack);
        }
      } finally {
        _current = null;
      }
    }
  }
}

class _AsyncMethodRequest<T> {
  final Completer<T?> completer;
  final AsyncQueueCallback<T> callback;

  const _AsyncMethodRequest({
    required this.callback,
    required this.completer,
  });
}
