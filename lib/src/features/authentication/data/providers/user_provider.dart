import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../../domain/models/user_model.dart';
import '../../../subscriptions/data/subscription_repository.dart';

/// Provider global pour l'utilisateur connecté.
/// Basé sur un Stream Firestore — l'UI se reconstruit automatiquement
/// dès qu'un champ change (quota, rôle, abonnement…).
final currentUserProvider =
    StreamNotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends StreamNotifier<UserModel?> {
  @override
  Stream<UserModel?> build() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    // Vérification d'expiration en fire-and-forget : ne bloque pas le stream.
    SubscriptionRepository().checkAndResetIfExpired(uid).ignore();

    return UserRepository().streamUser(uid);
  }
}
