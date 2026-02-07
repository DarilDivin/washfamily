# WashFamily

Application de location de lave-linge entre particuliers.

## Démarrage

### Prérequis

*   Flutter SDK (Dernière version stable)
*   Compte Firebase configuré (voir section Configuration)

### Lancement

1.  Installer les dépendances :
    ```bash
    flutter pub get
    ```

2.  Générer le code (Riverpod / GoRouter) :
    ```bash
    dart run build_runner build -d
    ```

3.  Lancer l'application :
    ```bash
    flutter run
    ```

## Architecture

Projet structuré en **Feature-First** dans `lib/src/`.
- `features/` : Modules fonctionnels (Auth, Booking, Map, Profile).
- `core/` : Configuration globale.
- `shared/` : Widgets réutilisables.

## Stack Technique

*   **Framework** : Flutter
*   **State Management** : Riverpod (w/ generator)
*   **Navigation** : GoRouter
*   **Backend** : Firebase
