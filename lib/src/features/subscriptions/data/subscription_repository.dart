import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/subscription_plan_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer tous les forfaits disponibles et actifs
  Future<List<SubscriptionPlanModel>> getActivePlans() async {
    try {
      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des forfaits : $e');
    }
  }

  // Obtenir un forfait spécifique par son ID
  Future<SubscriptionPlanModel?> getPlanById(String planId) async {
    try {
      final doc = await _firestore.collection('subscription_plans').doc(planId).get();
      if (doc.exists && doc.data() != null) {
        return SubscriptionPlanModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du forfait : $e');
    }
  }

  // Souscrire l'utilisateur à un plan
  Future<void> subscribeUserToPlan(String userId, SubscriptionPlanModel plan) async {
    try {
      final endDate = DateTime.now().add(const Duration(days: 30));
      await _firestore.collection('users').doc(userId).update({
        'currentSubscriptionId': plan.id,
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'remainingReservations': plan.maxReservationsPerMonth,
      });
    } catch (e) {
      throw Exception('Erreur lors de la souscription au forfait : $e');
    }
  }

  /// Vérifie si l'abonnement a expiré et, si c'est le cas, remet l'utilisateur
  /// sur le tier gratuit (2 réservations, pas de plan actif).
  /// Appelé côté client au chargement des écrans sensibles.
  Future<void> checkAndResetIfExpired(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;
      final data = doc.data()!;

      final endRaw = data['subscriptionEndDate'];
      if (endRaw == null) return; // Pas d'abonnement → rien à faire

      final endDate = (endRaw as Timestamp).toDate();
      if (!endDate.isBefore(DateTime.now())) return; // Pas encore expiré

      // Expiration détectée → retour au tier gratuit
      await _firestore.collection('users').doc(userId).update({
        'currentSubscriptionId': FieldValue.delete(),
        'subscriptionEndDate': FieldValue.delete(),
        'remainingReservations': 2,
      });
    } catch (_) {
      // Non critique : on ne bloque pas l'app si la vérification échoue
    }
  }
}
