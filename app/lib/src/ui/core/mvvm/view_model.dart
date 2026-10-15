import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../common/app_services.dart';
import '../../../common/repository_failure.dart';

/// Base class for every ViewModel (MVVM, following Flutter's official
/// architecture guide: one View ↔ one ViewModel, ViewModels talk to
/// repositories, Views only render state and forward user intents).
///
/// A ViewModel never imports Material widgets or `BuildContext`; it exposes
/// plain state plus async actions that return an [ActionResult], and the View
/// turns failures into localised messages. That keeps ViewModels unit-testable
/// with the fakes in `test/fakes/`.
abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// True while an action started through [run] is in flight.
  bool get busy => _busyCount > 0;
  int _busyCount = 0;

  /// Safe to call after dispose (async callbacks often land late).
  void notify() {
    if (!_disposed) notifyListeners();
  }

  /// Subscribes to [stream] for the ViewModel's lifetime.
  void listen<T>(Stream<T> stream, void Function(T value) onData, {void Function(Object error)? onError}) {
    _subscriptions.add(
      stream.listen(
        (value) {
          if (_disposed) return;
          onData(value);
        },
        onError: (Object error) {
          if (_disposed) return;
          onError?.call(error);
        },
      ),
    );
  }

  /// Runs [action], tracking [busy] and converting [RepositoryFailure]s into a
  /// failed [ActionResult] instead of throwing at the View.
  Future<ActionResult<T>> run<T>(Future<T> Function() action) async {
    _busyCount++;
    notify();
    try {
      final value = await action();
      return ActionResult.ok(value);
    } on RepositoryFailure catch (failure) {
      return ActionResult.failed(failure.reason);
    } on ActionError catch (error) {
      return ActionResult.failed(RepositoryFailureReason.invalidInput, code: error.code);
    } finally {
      _busyCount--;
      notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}

/// Validation error raised inside a ViewModel action. [code] lets the View
/// pick the right message (e.g. `'pinMismatch'`).
class ActionError implements Exception {
  const ActionError(this.code);
  final String code;
  @override
  String toString() => 'ActionError($code)';
}

/// Outcome of a ViewModel action.
class ActionResult<T> {
  const ActionResult.ok(this.value)
      : failure = null,
        code = null;
  const ActionResult.failed(RepositoryFailureReason this.failure, {this.code}) : value = null;

  final T? value;
  final RepositoryFailureReason? failure;

  /// Optional, more specific error identifier (see [ActionError]).
  final String? code;

  bool get isOk => failure == null;
}

/// Load state for screens that wait on a first stream emission.
enum LoadState { loading, ready, error }

/// Creates a ViewModel once (with access to [AppServices] and route
/// arguments), rebuilds [builder] whenever it notifies, and disposes it with
/// the widget.
class ViewModelBuilder<T extends ViewModel> extends StatefulWidget {
  const ViewModelBuilder({super.key, required this.create, required this.builder, this.onReady});

  final T Function(AppServices services) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  /// Called once after creation (e.g. to start loading).
  final void Function(T viewModel)? onReady;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends ViewModel> extends State<ViewModelBuilder<T>> {
  T? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final vm = widget.create(AppServicesScope.of(context));
      _viewModel = vm;
      widget.onReady?.call(vm);
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel!;
    return ListenableBuilder(listenable: vm, builder: (context, _) => widget.builder(context, vm));
  }
}
