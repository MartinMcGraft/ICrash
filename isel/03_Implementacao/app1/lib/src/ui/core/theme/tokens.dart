import 'package:flutter/material.dart';

/// Design tokens from the Figma file "I-Crash · Design v2"
/// (collections `v2 · Primitivos`, `v2 · Cor`, `v2 · Dimensões` and the
/// `v2/*` text styles). Keep names aligned with Figma so a token change there
/// maps 1:1 to a change here.
abstract final class IcColors {
  // Primitives
  static const navy900 = Color(0xFF0F2A3D);
  static const navy800 = Color(0xFF16384F);
  static const navy700 = Color(0xFF1F4E6B);
  static const navy600 = Color(0xFF2A6286);
  static const navy500 = Color(0xFF3B7AA3);
  static const navy200 = Color(0xFFB9D0E1);
  static const navy100 = Color(0xFFDCE8F1);
  static const navy50 = Color(0xFFEEF4F8);
  static const warm0 = Color(0xFFFFFFFF);
  static const warm25 = Color(0xFFFBFAF7);
  static const warm50 = Color(0xFFF6F4EF);
  static const warm100 = Color(0xFFEEEBE4);
  static const warm200 = Color(0xFFE2DED5);
  static const warm300 = Color(0xFFCDC8BD);
  static const warm500 = Color(0xFF8C877D);
  static const warm700 = Color(0xFF555149);
  static const warm900 = Color(0xFF1E1D1A);
  static const red800 = Color(0xFF7F1322);
  static const red700 = Color(0xFFA6192E);
  static const red600 = Color(0xFFC62034);
  static const red100 = Color(0xFFF9DEE1);
  static const red50 = Color(0xFFFCEFF1);
  static const amber800 = Color(0xFF6E4700);
  static const amber700 = Color(0xFF8A5A00);
  static const amber500 = Color(0xFFD99A1E);
  static const amber100 = Color(0xFFFBEFD3);
  static const green800 = Color(0xFF17543A);
  static const green700 = Color(0xFF1F6B45);
  static const green500 = Color(0xFF2F9A63);
  static const green100 = Color(0xFFDDF1E5);

  // Semantic (v2 · Cor)
  static const bgCanvas = warm50;
  static const bgSurface = warm0;
  static const bgSurfaceMuted = warm100;
  static const bgSurfaceSunken = warm200;
  static const bgSidebar = navy900;
  static const bgSidebarActive = navy700;
  static const textPrimary = warm900;
  static const textSecondary = warm700;
  static const textMuted = warm500;
  static const textOnDark = warm0;
  static const textOnDarkMuted = navy200;
  static const textLink = navy700;
  static const borderDefault = warm200;
  static const borderStrong = warm300;
  static const borderFocus = navy500;
  static const actionPrimary = navy700;
  static const actionPrimaryPressed = navy800;
  static const actionSecondary = navy50;
  static const actionDanger = red700;
  static const okFg = green700;
  static const okBg = green100;
  static const warningFg = amber700;
  static const warningBg = amber100;
  static const warningAccent = amber500;
  static const dangerFg = red700;
  static const dangerBg = red100;
  static const neutralFg = warm700;
  static const neutralBg = warm100;
  static const infoFg = navy700;
  static const infoBg = navy50;
  static const emergencyBg = red700;
  static const emergencyBgDeep = red800;
  static const emergencyFg = warm0;
}

abstract final class IcSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
}

abstract final class IcRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double full = 999;
}

abstract final class IcSize {
  /// Minimum touch target (gloved use).
  static const double touchMin = 48;
  static const double railTablet = 96;
  static const double railPhone = 72;
  static const double sidebar = 240;
}

abstract final class IcFonts {
  static const sans = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';
}

/// `v2/*` text styles. Colours are left to the caller (default: primary).
abstract final class IcText {
  static const display = TextStyle(fontFamily: IcFonts.sans, fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600, color: IcColors.textPrimary);
  static const titleL = TextStyle(fontFamily: IcFonts.sans, fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: IcColors.textPrimary);
  static const titleM = TextStyle(fontFamily: IcFonts.sans, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600, color: IcColors.textPrimary);
  static const titleS = TextStyle(fontFamily: IcFonts.sans, fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w600, color: IcColors.textPrimary);
  static const bodyL = TextStyle(fontFamily: IcFonts.sans, fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w400, color: IcColors.textPrimary);
  static const bodyM = TextStyle(fontFamily: IcFonts.sans, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400, color: IcColors.textPrimary);
  static const bodyS = TextStyle(fontFamily: IcFonts.sans, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: IcColors.textPrimary);
  static const labelL = TextStyle(fontFamily: IcFonts.sans, fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w500, color: IcColors.textPrimary);
  static const labelM = TextStyle(fontFamily: IcFonts.sans, fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w500, color: IcColors.textPrimary);
  static const labelS = TextStyle(fontFamily: IcFonts.sans, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: IcColors.textPrimary);
  static const numberL = TextStyle(fontFamily: IcFonts.sans, fontSize: 28, height: 32 / 28, fontWeight: FontWeight.w600, color: IcColors.textPrimary);
  static const mono = TextStyle(fontFamily: IcFonts.mono, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: IcColors.textMuted);
}

/// `v2/Elevação 1`.
const List<BoxShadow> icElevation1 = [
  BoxShadow(color: Color(0x0F1E1D1A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x141E1D1A), offset: Offset(0, 1), blurRadius: 3),
];
