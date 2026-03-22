import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crée un nouvel utilisateur en base de données après son inscription
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Erreur lors de la création du profil : $e');
    }
  }

  /// Récupère les données de l'utilisateur connecté
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

  /// Modifie le rôle de l'utilisateur (ex: pour devenir Propriétaire)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle : $e');
    }
  }
}
