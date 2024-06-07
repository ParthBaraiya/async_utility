import 'dart:async';

typedef AsyncDebouncerCallback<T, S> = Future<T?> Function([S?]);

class AsyncDebouncer<T, S> {
  final AsyncDebouncer<T, S> _callback;

  AsyncDebouncer({
    required AsyncDebouncer<T, S> callback,
  }) : _callback = callback;

  Completer<T?>? _completer;

  Future<T?> call([S? args]) {
    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }

    _completer = Completer<T?>();
    _call(args);

    return _completer!.future;
  }

  Future<void> _call(S? args) async {
    try {
      final result = await _callback(args);
      if (!_completer!.isCompleted) {
        _completer!.complete(result);
      }
    } catch (e, stack) {
      if (!_completer!.isCompleted) {
        _completer!.completeError(e, stack);
      }
    }
  }
}
