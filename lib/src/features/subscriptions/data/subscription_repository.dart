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
      // Calculer la date de fin (ex: + 30 jours)
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
}
