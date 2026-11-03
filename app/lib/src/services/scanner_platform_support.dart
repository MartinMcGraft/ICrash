import 'package:flutter/foundation.dart';

/// `mobile_scanner` has no Windows/Linux desktop support (spec section 32
/// calls this out explicitly for Windows); any camera-scan entry point must
/// hide itself there and fall back to manual entry, matching the legacy QR
/// reader's own platform gating. Shared by both scanning domains (GS1 Data
/// Matrix and internal cart QR) so the check is defined once.
bool get isCameraScanningSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
