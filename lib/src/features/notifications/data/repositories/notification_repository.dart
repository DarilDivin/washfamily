import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';

class NotificationRepository {
  final _col = FirebaseFirestore.instance.collection('notifications');

  /// Envoie une notification In-App
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _col.add({
        'userId': userId,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignorer silencieusement pour ne pas bloquer l'usage
    }
  }

  /// Récupère le flux de notifications pour un utilisateur
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromJson(d.data(), d.id))
            .toList());
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  /// Marque toutes les notifications de l'utilisateur comme lues
  Future<void> markAllAsRead(String userId) async {
    final unread = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
