import 'dart:async';

/// typedef for callback used in [AsyncDebouncer].
///
/// [T] defines the type of return value and [S] defines the type of argument.
typedef AsyncDebouncerCallback<T, S> = Future<T?> Function([S?]);

// {@macro async_debouncer_doc}
class AsyncDebouncer<T, S> {
  /// Callback which will run when the debouncer gets called.
  final AsyncDebouncer<T, S> _callback;

  // {@macro async_debouncer_doc}
  AsyncDebouncer({
    required AsyncDebouncer<T, S> callback,
  }) : _callback = callback;

  Completer<T?>? _completer;

  /// Runs the [_callback].
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

/// {@template async_debouncer_doc}
/// As name suggests, it debounces the simultaneous calls for same method.
///
/// If the [callback] is already running it will skip the new execution and
/// return the value of currently running callback once it's completed.
///
/// If the callback is not running, it will execute it should get executed.
///
/// How to Use,
///
/// ```dart
///
/// int a = 0;
///
/// // create an instance
/// final debouncer = AsyncDebouncer(callback: (value) async {
///   // Your async task...
///
///   await Future.delayed(Duration(seconds: 10));
///
///   a++;
///   return a;
/// });
///
/// // running the callback,
/// final value = await debouncer();
/// // or
/// final value = debouncer.call();
///
/// ```
///
/// In above example if you call the debouncer within 10 seconds of first call,
/// all calls will return 1. because the first time execution is
/// taking 10 seconds. and as other calls are being made while the first call
/// is running, they all will share the result of first call.
///
/// If the debouncer is called 10 seconds after the first call, it will return
/// 2. Because first call would have been executed once increasing the value of
/// a and second will get executed increasing it's value again.
///
/// {@endtemplate}
