# Design System — Clarté Domestique
## WashFamily · Version 1.1

---

## 1. Philosophie

| Principe | Description |
|---|---|
| **Zéro surcharge** | Pas d'ombres massives ni de dégradés agressifs. Elevation = 0 partout. |
| **Espaces de respiration** | Marges généreuses pour réduire la fatigue cognitive. |
| **Bordures fines** | Délimitations par des traits fins (1px) plutôt que par des reliefs. |
| **Confiance** | Couleurs stables et professionnelles inspirées d'Apple, Airbnb, Uber. |
| **Tokens sémantiques** | Toujours utiliser les constantes nommées — jamais de valeurs hex en dur dans les widgets. |

---

## 2. Palette de Couleurs

### 2.1 Couleurs principales

| Rôle | Nom | Hex | Usage |
|---|---|---|---|
| **Primaire** | Royal Blue | `#2563EB` | Boutons d'action, icônes actives, liens |
| **Fond de page** | Ghost White | `#F8FAFC` | `scaffoldBackgroundColor` |
| **Surface** | White | `#FFFFFF` | Cartes, BottomSheets, BarreNav |
| **Bordure** | Slate 200 | `#E2E8F0` | Séparateurs, champs, cartes |
| **Input Bg** | Slate 100 | `#F1F5F9` | Fond des TextFields |
| **Texte Principal** | Dark Navy | `#0F172A` | Titres |
| **Texte Corps** | Navy 800 | `#1E293B` | Corps de texte |
| **Texte Secondaire** | Slate Gray | `#64748B` | Sous-titres, labels, icônes inactives |

### 2.2 Couleurs d'état (obligatoires)

| État | Hex | Usage Flutter |
|---|---|---|
| **Succès** | `#16A34A` | Réservation confirmée, paiement OK, badge CONFIRMED |
| **Erreur** | `#DC2626` | Champ invalide, action impossible, badge CANCELLED |
| **Warning** | `#D97706` | Machine bientôt indisponible, quota faible |
| **Info** | `#0EA5E9` | Messages neutres, notifications informatives |

### 2.3 Couleurs de statut des réservations

| Statut | Couleur Fond | Couleur Texte | Hex Fond | Hex Texte |
|---|---|---|---|---|
| `PENDING` | Amber 100 | Amber 800 | `#FEF3C7` | `#92400E` |
| `CONFIRMED` | Green 100 | Green 800 | `#DCFCE7` | `#166534` |
| `COMPLETED` | Blue 100 | Blue 800 | `#DBEAFE` | `#1E40AF` |
| `CANCELLED` | Red 100 | Red 800 | `#FEE2E2` | `#991B1B` |

### 2.4 Règle d'usage

```dart
// ✅ BON — token sémantique
color: AppColors.primary
color: AppColors.success

// ❌ MAUVAIS — valeur en dur
color: Color(0xFF2563EB)
color: Colors.green
```

---

## 3. Typographie

**Police principale : `Inter`** (Google Fonts)

### Hiérarchie complète

| Niveau | Taille | Poids | Usage |
|---|---|---|---|
| `displayLarge` | 32pt | Bold (700) | Splash, onboarding |
| `headlineLarge` | 24pt | Bold (700) | Titres d'écran principaux |
| `titleLarge` | 18pt | SemiBold (600) | Titres de cartes, AppBar |
| `titleMedium` | 16pt | SemiBold (600) | Sous-sections |
| `bodyLarge` | 15pt | Regular (400) | Texte courant |
| `bodyMedium` | 14pt | Regular (400) | Descriptions, listes |
| `labelLarge` | 13pt | Medium (500) | Boutons |
| `labelSmall` | 12pt | Medium (500) | Navigation, badges, meta-info |
| `caption` | 11pt | Regular (400) | Dates, mentions légales |

### Règle d'usage
```dart
// ✅ BON
Text('Titre', style: Theme.of(context).textTheme.headlineLarge)

// ❌ MAUVAIS
Text('Titre', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
```

---

## 4. Système d'Espacement

Base : **8px**. Toujours utiliser des multiples de 4 ou 8.

| Token | Valeur | Usage |
|---|---|---|
| `spacing2xs` | 4px | Gap entre icône et label |
| `spacingXs` | 8px | Padding interne léger |
| `spacingSm` | 12px | Gap entre éléments d'une ligne |
| `spacingMd` | 16px | Padding standard des conteneurs |
| `spacingLg` | 24px | Espacement entre sections |
| `spacingXl` | 32px | Marges majeures |
| `spacing2xl` | 48px | Espacement entre blocs |

```dart
// Constantes à définir dans app_spacing.dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

---

## 5. Rayons de Bordure

| Token | Valeur | Usage |
|---|---|---|
| `radiusSm` | 8px | TextFields, petits boutons |
| `radiusMd` | 12px | Boutons primaires |
| `radiusLg` | 16px | Cartes standard |
| `radiusXl` | 24px | Cartes grandes (MachineCard) |
| `radius2xl` | 32px | BottomSheets, Pill buttons |
| `radiusFull` | 999px | Badges, avatars, Pill nav |

---

## 6. Composants Signature

### 6.1 Animated Bottom Navigation Bar (Pill Flottante)

- **Forme** : Pilule flottante (`borderRadius: 32px`) avec `margin: EdgeInsets.all(16)`
- **Fond** : `Colors.white` avec bordure `1px #E2E8F0`
- **Animation** : Sliding Glow Indicator — indicateur bleu translucide qui glisse entre les onglets
- **État actif** : icône Solid + label `labelSmall` en `primaryBlue`
- **État inactif** : icône Outlined + label en `Slate Gray (#64748B)`
- **Icônes** : Phosphor Icons (style `fill` pour actif, `regular` pour inactif)
- **Élévation** : 0 (pas d'ombre — cohérence avec la philosophie)

### 6.2 Boutons

**Primary**
```
Fond : Royal Blue (#2563EB)
Texte : White
Radius : 12px
Padding : horizontal 24px, vertical 16px
Elevation : 0
État disabled : opacity 0.5
```

**Secondary**
```
Fond : White
Bordure : 1px Slate 200 (#E2E8F0)
Texte : Dark Navy (#0F172A)
Radius : 12px
Padding : horizontal 24px, vertical 16px
```

**Destructive**
```
Fond : Red 50 (#FEE2E2)
Texte : Red 700 (#B91C1C)
Pas de bordure
Radius : 12px
```

**Ghost / Text**
```
Fond : transparent
Texte : Royal Blue (#2563EB)
Pas de bordure
```

### 6.3 TextFields

```
Fond : Slate 100 (#F1F5F9)
Bordure au repos : aucune
Bordure au focus : 2px Royal Blue (#2563EB)
Bordure en erreur : 1px Red (#DC2626)
Radius : 8px
Padding : horizontal 16px, vertical 16px
Placeholder : Slate Gray (#64748B)
Pas de label flottant — uniquement des placeholders clairs
```

### 6.4 MachineCard

```
Fond : White (#FFFFFF)
Bordure : 1px Slate 200 (#E2E8F0)
Radius : 24px
Elevation : 0
Image : height 160px, radius top-left/right 24px, objectFit: cover
Padding interne : 16px
Layout :
  - Image (160px)
  - Row [Brand + capacité] — titleMedium
  - Row [Rating ⭐ + nbAvis] — labelSmall, Slate Gray
  - Row [Adresse] — bodyMedium, Slate Gray, icône phosphor MapPin
  - Row [Prix/lavage] — titleMedium Bold Blue + badge AVAILABLE/IN_USE
```

### 6.5 Badges de statut

Toujours un Container avec `borderRadius: 999` (pill) :
```dart
// Structure type
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: statusBackgroundColor,  // voir tableau section 2.3
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(label, style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
)
```

### 6.6 StarRatingWidget

- Étoiles : icône Phosphor `Star` (fill pour remplies, regular pour vides)
- Couleur active : `#F59E0B` (Amber)
- Couleur inactive : `#E2E8F0` (Slate 200)
- Taille par défaut : 20px
- Interactif si `onChanged != null`, read-only sinon

### 6.7 ReviewCard

```
Fond : White
Bordure : 1px Slate 200
Radius : 16px
Padding : 16px
Layout :
  - Row [Avatar initiales + Prénom + Date] — labelSmall Slate Gray
  - StarRatingWidget (read-only, size 16)
  - Text commentaire — bodyMedium (si présent)
```

---

## 7. Iconographie

**Package retenu : `phosphor_flutter`**

| Contexte | Style Phosphor |
|---|---|
| Navigation inactive | `PhosphorIconsRegular` |
| Navigation active | `PhosphorIconsFill` |
| Actions principales | `PhosphorIconsRegular` |
| Indicateurs d'état | `PhosphorIconsFill` |

**Épaisseur** : Regular (jamais Bold dans ce design system)
**Taille standard** : 24px pour les icônes d'action, 20px pour les icônes dans le texte, 16px pour les badges

---

## 8. Dark Mode — Tokens Sémantiques

Préparer le dark mode dès maintenant en utilisant `ColorScheme` plutôt que des couleurs hardcodées.

```dart
// Dans app_theme.dart — mapping sémantique
ColorScheme.light(
  primary: Color(0xFF2563EB),        // Royal Blue
  surface: Color(0xFFFFFFFF),        // Blanc pur
  surfaceContainerLow: Color(0xFFF8FAFC),  // Ghost White (scaffold)
  onSurface: Color(0xFF0F172A),      // Dark Navy
  onSurfaceVariant: Color(0xFF64748B), // Slate Gray
  outline: Color(0xFFE2E8F0),        // Slate 200
  error: Color(0xFFDC2626),
)

ColorScheme.dark(
  primary: Color(0xFF3B82F6),        // Blue légèrement plus clair
  surface: Color(0xFF1E293B),
  surfaceContainerLow: Color(0xFF0F172A),
  onSurface: Color(0xFFF8FAFC),
  onSurfaceVariant: Color(0xFF94A3B8),
  outline: Color(0xFF334155),
  error: Color(0xFFF87171),
)
```

---

## 9. Règles de Construction des Écrans

1. **Toujours `Scaffold` avec `backgroundColor: AppColors.scaffoldBackground`**
2. **AppBar transparente** (`elevation: 0, backgroundColor: Colors.transparent`)
3. **Pas d'ombre sur les cartes** — uniquement des bordures fines
4. **Pas de `Colors.red`, `Colors.green`** en dur — utiliser `AppColors.error`, `AppColors.success`
5. **Padding de page standard** : `EdgeInsets.symmetric(horizontal: 20, vertical: 16)`
6. **Séparateurs** : `Divider(color: AppColors.border, thickness: 1, height: 1)` — jamais d'espacement arbitraire
7. **Loading states** : `CircularProgressIndicator(color: AppColors.primary)` centré, taille 24px
8. **Empty states** : icône Phosphor 48px en Slate Gray + texte `bodyMedium` centré

---

## 10. Où Placer ce Fichier

```
lib/
  src/
    core/
      theme/
        app_theme.dart          ← ThemeData Flutter (déjà existant)
        app_colors.dart         ← À CRÉER : toutes les constantes Color
        app_spacing.dart        ← À CRÉER : constantes d'espacement
        app_text_styles.dart    ← À CRÉER : styles TextStyle nommés
      DESIGN_SYSTEM.md          ← CE FICHIER (référence pour Claude Code)
```

### `app_colors.dart` à créer

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primaires
  static const Color primary = Color(0xFF2563EB);
  static const Color scaffoldBackground = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Texte
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // États
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0EA5E9);

  // Statuts réservations
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingText = Color(0xFF92400E);
  static const Color confirmedBg = Color(0xFFDCFCE7);
  static const Color confirmedText = Color(0xFF166534);
  static const Color completedBg = Color(0xFFDBEAFE);
  static const Color completedText = Color(0xFF1E40AF);
  static const Color cancelledBg = Color(0xFFFEE2E2);
  static const Color cancelledText = Color(0xFF991B1B);

  // StarRating
  static const Color starActive = Color(0xFFF59E0B);
  static const Color starInactive = Color(0xFFE2E8F0);
}
```

---

## 11. Instructions pour Claude Code

Quand tu génères un écran ou un composant pour WashFamily, respecte impérativement ces règles :

1. **Couleurs** → uniquement via `AppColors.*` ou `Theme.of(context).colorScheme.*`. Jamais de hex en dur.
2. **Textes** → uniquement via `Theme.of(context).textTheme.*`. Jamais de `TextStyle` custom inline.
3. **Espacements** → uniquement via `AppSpacing.*`. Jamais de valeurs numériques en dur sauf pour les bordures (1px).
4. **Icônes** → `PhosphorIconsRegular` ou `PhosphorIconsFill` uniquement. Jamais `Icons.*` de Material.
5. **Boutons** → `FilledButton`, `OutlinedButton`, ou `TextButton` stylisés par le thème. Jamais de `GestureDetector` avec un Container coloré pour simuler un bouton.
6. **Cartes** → `Card` avec le thème global (elevation: 0, borderRadius: 24, border: 1px). Jamais de `Container` avec `BoxDecoration` + `boxShadow`.
7. **Statuts** → utiliser les helpers `AppColors.pendingBg`, `AppColors.confirmedBg`, etc.
8. **Elevation** → toujours `0`. Jamais de `boxShadow`.
9. **États vides** → icône Phosphor 48px + texte centré. Jamais de placeholder texte seul.
10. **Responsive** → utiliser `MediaQuery.of(context).size` pour adapter les layouts. Préférer `Expanded` et `Flexible` aux tailles fixes.
