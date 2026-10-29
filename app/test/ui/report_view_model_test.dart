import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart_report.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/reports/report_view_model.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

SessionController _session(AppServices services, String uid) => SessionController(
      services: services,
      user: AuthUser(uid: uid, email: '$uid@h.pt'),
      institution: _institution,
      membership: Membership(uid: uid, institutionId: 'inst', role: Role.user, status: MembershipStatus.active, displayName: uid),
      institutionCount: 1,
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

/// Creates a pending monthly-check report performed by [author] and returns its id.
Future<String> _report(AppServices services, String author) async {
  final created = await services.reports.createReport(CartReport(
    id: '',
    institutionId: 'inst',
    cartId: 'c1',
    cartName: 'Carro 1',
    kind: ReportKind.monthlyCheck,
    status: ReportStatus.pendingSignature,
    createdAt: DateTime(2026, 10, 29),
    createdByUid: author,
    createdByName: author,
  ));
  return created.id;
}

void main() {
  group('A9 ReportViewModel: the person who performed the check signs it (DB4)', () {
    test('the author can sign with their PIN', () async {
      final services = buildTestServices();
      final id = await _report(services, 'ana');
      await services.deviceSession.setPin('ana', '1234');
      final vm = ReportViewModel(services, _session(services, 'ana'), id);
      await _settle();
      expect(vm.canSign, isTrue);
      vm.setConfirmed(true);
      final result = await vm.sign('1234');
      expect(result.isOk, isTrue);
      await _settle();
      expect(vm.report!.isSigned, isTrue);
      expect(vm.report!.signedByUid, 'ana');
      vm.dispose();
    });

    test('anyone else sees the report but can\'t sign it', () async {
      final services = buildTestServices();
      final id = await _report(services, 'ana');
      await services.deviceSession.setPin('rui', '1234');
      final vm = ReportViewModel(services, _session(services, 'rui'), id);
      await _settle();
      expect(vm.report, isNotNull);
      expect(vm.canSign, isFalse);
      vm.setConfirmed(true);
      final result = await vm.sign('1234');
      expect(result.code, 'notAuthor');
      await _settle();
      expect(vm.report!.isSigned, isFalse);
      vm.dispose();
    });
  });
}
