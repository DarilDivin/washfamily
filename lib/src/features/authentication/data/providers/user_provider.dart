import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../../domain/models/user_model.dart';
import '../../../subscriptions/data/subscription_repository.dart';

/// Provider global pour l'utilisateur connecté.
/// Vérifie automatiquement l'expiration de l'abonnement à chaque lecture.
/// Utilisé partout en remplacement des appels directs à UserRepository().getUser().
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    await SubscriptionRepository().checkAndResetIfExpired(uid);
    return UserRepository().getUser(uid);
  }
}
