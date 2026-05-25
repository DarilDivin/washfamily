import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hiérarchie typographique — police Inter (Google Fonts).
///
/// Usage recommandé : Theme.of(context).textTheme.*
/// Usage direct possible : AppTextStyles.headlineLarge
///
/// Ne jamais utiliser TextStyle inline avec des valeurs en dur.
class AppTextStyles {
  // ── Styles individuels ────────────────────────────────────────────────────────

  /// 32pt · Bold — Splash, onboarding
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// 24pt · Bold — Titres d'écran principaux
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  /// 20pt · SemiBold — Titres intermédiaires
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 18pt · SemiBold — Titres de cartes, AppBar
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 16pt · SemiBold — Sous-sections
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 14pt · Medium — Titres secondaires de listes
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 15pt · Regular — Texte courant
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textBody,
        height: 1.55,
      );

  /// 14pt · Regular — Descriptions, listes
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textBody,
        height: 1.55,
      );

  /// 13pt · Regular — Texte secondaire discret
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// 13pt · Medium — Labels de boutons
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 12pt · Medium — Navigation, badges, meta-info
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  /// 12pt · Medium — Navigation, badges, meta-info (alias labelSmall du DS)
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
        letterSpacing: 0.3,
      );

  /// 11pt · Regular — Dates, mentions légales (alias "caption" du DS)
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ── TextTheme Flutter ─────────────────────────────────────────────────────────
  /// À passer dans ThemeData.textTheme pour que Theme.of(context).textTheme.* fonctionne.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: headlineLarge,
        displaySmall: headlineMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: titleLarge,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: caption,        // "caption" du DS → bodySmall Flutter
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
