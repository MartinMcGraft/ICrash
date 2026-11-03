import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/support_access.dart';
import '../format.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';

/// D18: a bar above the whole shell while Super works in an institution
/// through its support window: "Acesso do suporte · Hospital X · termina às
/// 18:00". It takes the top safe area, so the shell below it doesn't.
class SupportBannerFrame extends StatelessWidget {
  const SupportBannerFrame({super.key, required this.institutionName, required this.window, required this.child});

  final String institutionName;
  final SupportWindow window;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final now = DateTime.now();
    final sameDay = window.endsAt.year == now.year && window.endsAt.month == now.month && window.endsAt.day == now.day;
    final until = sameDay ? format.time(window.endsAt) : format.dateTime(window.endsAt);
    final text = l10n.supportBanner(institutionName, until);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: text,
          excludeSemantics: true,
          child: ColoredBox(
            color: IcColors.amber500,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: 6),
                child: Row(
                  children: [
                    const IcIconView(IcIcon.escudo, size: 18, color: IcColors.textPrimary),
                    const SizedBox(width: IcSpace.s8),
                    Expanded(
                      child: Text(text, style: IcText.labelM, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}
