import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/services/gs1_hid_scanner_service.dart';

void main() {
  test('feedLine emits the line to listeners', () async {
    final service = HidGs1ScannerService();
    final received = <String>[];
    final subscription = service.scanRawPayloads().listen(received.add);

    service.feedLine('0105412345678900');
    await Future<void>.delayed(Duration.zero);

    expect(received, ['0105412345678900']);
    await subscription.cancel();
    service.dispose();
  });

  test('feedLine ignores an empty line', () async {
    final service = HidGs1ScannerService();
    final received = <String>[];
    final subscription = service.scanRawPayloads().listen(received.add);

    service.feedLine('');
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
    await subscription.cancel();
    service.dispose();
  });
}
