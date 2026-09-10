import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

/// A slim banner shown whenever the device has no network connectivity,
/// wrapped once around the whole app (see `main.dart`) rather than added to
/// every screen individually. Deliberately scoped to a simple offline
/// signal rather than a full per-query sync-state UI (synced/pending/
/// failed) — Firestore's own offline cache already keeps every screen
/// usable with the last-known data regardless of connectivity; this only
/// tells the user that's what is currently happening.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
    _connectivity.checkConnectivity().then(_update);
  }

  void _update(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(() => _offline = results.every((result) => result == ConnectivityResult.none));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          // `Material` because this sits directly under `MaterialApp` (via
          // its `builder`), outside any individual screen's own `Scaffold`
          // — without it, the debug build paints the default "missing
          // Material ancestor" underline under the text.
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).connectivityOfflineMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
