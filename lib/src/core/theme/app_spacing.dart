import 'package:flutter/material.dart';

/// Système d'espacement — base 8px.
/// Toujours utiliser ces constantes. Jamais de valeurs numériques en dur dans les widgets.
class AppSpacing {
  // ── Espacements ──────────────────────────────────────────────────────────────
  /// 4px — gap icône / label
  static const double xs = 4;

  /// 8px — padding interne léger
  static const double sm = 8;

  /// 12px — gap entre éléments d'une ligne
  static const double md = 12;

  /// 16px — padding standard des conteneurs
  static const double lg = 16;

  /// 24px — espacement entre sections
  static const double xl = 24;

  /// 32px — marges majeures
  static const double xxl = 32;

  /// 48px — espacement entre blocs
  static const double xxxl = 48;

  // ── Rayons de bordure ────────────────────────────────────────────────────────
  /// 8px — TextFields, petits boutons
  static const double radiusSm = 8;

  /// 12px — boutons primaires
  static const double radiusMd = 12;

  /// 16px — cartes standard
  static const double radiusLg = 16;

  /// 24px — cartes larges (MachineCard)
  static const double radiusXl = 24;

  /// 32px — BottomSheets, pill buttons
  static const double radius2xl = 32;

  /// 999px — badges, avatars, pill nav
  static const double radiusFull = 999;

  // ── Helpers EdgeInsets ───────────────────────────────────────────────────────
  /// Padding de page standard : horizontal 20 · vertical 16
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  /// Padding interne des cartes : 16px sur tous les côtés
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  // ── SizedBox helpers ─────────────────────────────────────────────────────────
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}
