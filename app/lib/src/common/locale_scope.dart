import 'package:flutter/widgets.dart';

/// Exposes the app's current [Locale] and lets any descendant change it
/// (spec section 13: PT-PT + English, user-switchable) — a plain
/// [InheritedWidget], matching [AppServicesScope]'s own DI approach rather
/// than adding a state-management package for a single value.
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  final Locale locale;
  final ValueChanged<Locale> setLocale;

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(
      scope != null,
      'LocaleScope.of() called with no LocaleScope ancestor',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => locale != oldWidget.locale;
}
