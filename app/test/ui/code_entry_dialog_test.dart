import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/ui/core/theme/app_theme.dart';
import 'package:icrash_app/src/ui/core/widgets/dialogs.dart';

/// 2 Nov 2026: "Cancelar" in the manual-entry dialog (A11 "Manual", A3
/// "Introduzir código") crashed the app: the text field's controller was
/// disposed while the dialog was still closing.
void main() {
  Future<List<String?>> open(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(await showCodeEntryDialog(context, title: 'Manual', label: 'Código do carro')),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('Cancelar closes the dialog with no error and returns nothing', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), 'hospital-a/carro-a1');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(results, [null]);
  });

  testWidgets('Confirmar returns the trimmed code, with no error', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), '  hospital-a/carro-a1 ');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(results, ['hospital-a/carro-a1']);
  });

  testWidgets('an empty code counts as cancelled', (tester) async {
    final results = await open(tester);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
