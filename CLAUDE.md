# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate Riverpod providers & GoRouter (run after any @riverpod annotation change)
dart run build_runner build -d

# Run app
flutter run

# Analyze
flutter analyze

# Deploy Firestore rules & indexes
firebase deploy --only firestore
```

## Architecture

**Feature-First** layout under `lib/src/features/`. Each feature follows:
```
feature/
  data/
    providers/   # Riverpod providers + .g.dart generated files
    repositories/
  domain/
    models/
  presentation/
    screens/
    widgets/
```

### Core domain hierarchy

```
LaundryModel (laundries/{id})
  └── MachineModel (laundries/{id}/machines/{id})
        └── WashProgram (embedded list in MachineModel)

ReservationModel (reservations/{id})
  ├── machineId
  └── laundryId  ← always denormalized for queries
```

Service options (folding, pickup, delivery) live on **LaundryModel**, not MachineModel.

### State management

Riverpod with code generation. Providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotations in `data/providers/`. Always run `build_runner` after changing annotations.

Key global providers:
- `currentUserProvider` — `StreamNotifierProvider<UserModel?>` watching current auth user from Firestore in real-time (`authentication/data/providers/user_provider.dart`)
- `machinesProvider(laundryId)` — stream of machines per laundry
- `activeLaundriesProvider`, `laundryProvider(id)` — laundry data
- `cartProvider` — shop cart

### Navigation

GoRouter with a `StatefulShellRoute` for the 5-tab bottom nav:

| Index | Path | Tab |
|-------|------|-----|
| 0 | `/home` | Accueil |
| 1 | `/shop` | Boutique |
| 2 | `/bookings` | Réservations |
| 3 | `/messages` | Messages |
| 4 | `/profile` | Profil |

Auth redirect: not logged in + private route → `/login`. Auth-only path + logged in → `/home`.

Router is defined in `lib/src/core/router_config.dart` with its generated counterpart `.g.dart`.

### User roles

`UserModel.roles: List<String>` — values: `'USER'`, `'OWNER'`, `'ADMIN'`. A user can hold multiple roles simultaneously. Checked via `.isOwner`, `.isAdmin`, `.isUser` getters.

### Reservation lifecycle

```
PENDING → CONFIRMED → PICKED_UP → IN_PROGRESS → READY → COMPLETED
                                                        → CANCELLED
```

`ReservationStatusHelper` provides FR labels, colors, and icons for all 7 statuses. Owner advances status via `updateStatusByOwner()` which auto-posts a system message to the linked conversation.

### Messaging

A `ConversationModel` is created automatically when a reservation reaches `CONFIRMED`. Each status change appends a `MessageModel` with `type: 'SYSTEM'`. User messages are `type: 'TEXT'`. Input is locked when the reservation is in a terminal state.

### Firestore structure

```
/users/{uid}
/laundries/{laundryId}
  /machines/{machineId}
/reservations/{reservationId}   ← root collection, laundryId denormalized
/conversations/{conversationId}
  /messages/{messageId}
/reviews/{reviewId}             ← laundryId field for queries
/notifications/{notificationId}
```

5 composite indexes deployed — see `firestore.indexes.json`. The `machines` index uses `COLLECTION_GROUP` scope to allow cross-laundry queries by `laundryId` + `isAvailable`.

### Theme & design system

Design tokens are in `lib/src/core/theme/` (`app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`). See `lib/src/core/DESIGN_SYSTEM.md` for usage guidelines.

Icon set: `phosphor_flutter`. Maps: `flutter_map` (primary) and `google_maps_flutter` (both present). Locale: French (`fr`).

## Firebase project

Project ID: `washfamily-001`. Secrets loaded from `.env` via `flutter_dotenv`. Generated config in `lib/firebase_options.dart` (do not edit manually).

Current Firestore security rules are permissive (any authenticated user can read/write any document) — scoped rules are not yet implemented.

## Generated files

Never edit `*.g.dart` files manually. After modifying any `@riverpod` annotated function or GoRouter `@TypedGoRoute` annotation, regenerate with `build_runner`.
