import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Drives the design v2 "Sincronização" indicator: Sincronizado /
/// "N alterações por enviar" / "Sem ligação · a trabalhar offline".
///
/// Firestore queues writes while offline and only completes a write's
/// Future once the server has acknowledged it, so counting writes that are
/// still in flight is an honest "pending changes" number.
class SyncStatus extends ChangeNotifier {
  bool _online = true;
  int _pending = 0;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get online => _online;
  int get pendingWrites => _pending;

  /// Tracks a write until the backend acknowledges it.
  Future<T> track<T>(Future<T> write) {
    _pending++;
    notifyListeners();
    return write.whenComplete(() {
      _pending--;
      notifyListeners();
    });
  }

  /// Starts listening to the platform connectivity plugin. Not called in
  /// widget tests (the plugin has no test implementation).
  void attachConnectivity([Connectivity? connectivity]) {
    final source = connectivity ?? Connectivity();
    _subscription = source.onConnectivityChanged.listen(_update);
    unawaited(source.checkConnectivity().then(_update));
  }

  /// For tests and the A12 state.
  @visibleForTesting
  void setOnline(bool value) {
    _online = value;
    notifyListeners();
  }

  void _update(List<ConnectivityResult> results) {
    final next = !results.every((r) => r == ConnectivityResult.none);
    if (next == _online) return;
    _online = next;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
