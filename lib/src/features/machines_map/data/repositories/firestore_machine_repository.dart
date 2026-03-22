import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/machine_model.dart';

class FirestoreMachineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ajoute une nouvelle machine dans Firestore
  /// Utilise un ID auto-généré par Firebase (plus robuste que les timestamps)
  Future<String> addMachine(MachineModel machine) async {
    try {
      // On laisse Firestore générer l'ID automatiquement
      final docRef = await _firestore.collection('machines').add(machine.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la machine : $e');
    }
  }

  /// Met à jour une machine existante
  Future<void> updateMachine(String machineId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('machines').doc(machineId).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour : $e');
    }
  }

  /// Supprime une machine
  Future<void> deleteMachine(String machineId) async {
    try {
      await _firestore.collection('machines').doc(machineId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression : $e');
    }
  }

  /// Récupère toutes les machines (pour la carte)
  Future<List<MachineModel>> getAllMachines() async {
    try {
      final snapshot = await _firestore
          .collection('machines')
          .where('status', isNotEqualTo: 'DELETED')
          .get();
      return snapshot.docs
          .map((doc) => MachineModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des machines : $e');
    }
  }

  /// Récupère les machines d'un propriétaire spécifique
  Future<List<MachineModel>> getMachinesByOwner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('machines')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MachineModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Fallback sans orderBy si l'index n'est pas encore créé
      final snapshot = await _firestore
          .collection('machines')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      return snapshot.docs
          .map((doc) => MachineModel.fromJson(doc.data(), doc.id))
          .toList();
    }
  }

  /// Récupère une machine par son ID
  Future<MachineModel?> getMachineById(String machineId) async {
    try {
      final doc = await _firestore.collection('machines').doc(machineId).get();
      if (!doc.exists) return null;
      return MachineModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }
}

/// Helper pour récupérer l'UID de l'utilisateur courant
String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
