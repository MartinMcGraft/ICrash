import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The red "IC" monogram (brand mark, Seal Red).
class Monogram extends StatelessWidget {
  const Monogram({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: IcColors.emergencyBg, borderRadius: BorderRadius.circular(size / 4)),
      child: Text(
        'IC',
        style: IcText.labelM.copyWith(color: IcColors.textOnDark, fontSize: size / 3, height: 1, fontWeight: FontWeight.w600),
      ),
    );
  }
}
