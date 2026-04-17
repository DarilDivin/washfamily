import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Erreur lors de la création du profil : $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil : $e');
    }
  }

  /// Ajoute un rôle à l'utilisateur (idempotent via arrayUnion)
  Future<void> addRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'roles': FieldValue.arrayUnion([role]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du rôle : $e');
    }
  }

  /// Retire un rôle à l'utilisateur (idempotent via arrayRemove)
  Future<void> removeRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'roles': FieldValue.arrayRemove([role]),
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait du rôle : $e');
    }
  }
}
