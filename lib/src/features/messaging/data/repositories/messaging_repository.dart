import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';

part 'messaging_repository.g.dart';

@Riverpod(keepAlive: true)
MessagingRepository messagingRepository(MessagingRepositoryRef ref) =>
    MessagingRepository();

@riverpod
Stream<List<ConversationModel>> conversationsStream(
    ConversationsStreamRef ref, String userId) =>
    ref.watch(messagingRepositoryProvider).streamConversations(userId);

@riverpod
Stream<List<MessageModel>> messagesStream(
    MessagesStreamRef ref, String conversationId) =>
    ref.watch(messagingRepositoryProvider).streamMessages(conversationId);

@riverpod
Stream<int> totalUnreadCount(TotalUnreadCountRef ref, String userId) =>
    ref.watch(messagingRepositoryProvider).streamTotalUnreadCount(userId);

class MessagingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _conversations => _db.collection('conversations');
  CollectionReference get _messages => _db.collection('messages');

  Future<ConversationModel> createConversation({
    required String reservationId,
    required String machineId,
    required String locataireId,
    required String proprietaireId,
    String laundryId = '',
  }) async {
    final now = DateTime.now();
    const systemMessage =
        'Réservation confirmée. Vous pouvez maintenant organiser la collecte de votre linge.';

    final convData = {
      'reservationId': reservationId,
      'machineId': machineId,
      'laundryId': laundryId,
      'participantIds': [locataireId, proprietaireId],
      'lastMessage': systemMessage,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastSenderId': 'SYSTEM',
      'unreadCount': {locataireId: 0, proprietaireId: 0},
      'createdAt': Timestamp.fromDate(now),
    };

    final convRef = _conversations.doc();
    await convRef.set(convData);

    // Add system message
    await _messages.add({
      'conversationId': convRef.id,
      'senderId': 'SYSTEM',
      'content': systemMessage,
      'type': 'SYSTEM',
      'createdAt': Timestamp.fromDate(now),
      'readBy': [],
    });

    return ConversationModel.fromJson(convData, convRef.id);
  }

  Stream<List<ConversationModel>> streamConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ConversationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<ConversationModel?> getConversationByReservationId(
      String reservationId) async {
    final snap = await _conversations
        .where('reservationId', isEqualTo: reservationId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return ConversationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<ConversationModel?> getConversationById(String conversationId) async {
    final doc = await _conversations.doc(conversationId).get();
    if (!doc.exists) return null;
    return ConversationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _messages
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MessageModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());

    await _db.runTransaction((tx) async {
      final convRef = _conversations.doc(conversationId);
      final convDoc = await tx.get(convRef);

      if (!convDoc.exists) return;

      final convData = convDoc.data() as Map<String, dynamic>;
      final participants =
          List<String>.from(convData['participantIds'] as List? ?? []);
      final otherParticipantId =
          participants.firstWhere((id) => id != senderId, orElse: () => '');

      final msgRef = _messages.doc();
      tx.set(msgRef, {
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'type': 'TEXT',
        'createdAt': now,
        'readBy': [senderId],
      });

      final Map<String, dynamic> convUpdate = {
        'lastMessage': content,
        'lastMessageAt': now,
        'lastSenderId': senderId,
      };

      if (otherParticipantId.isNotEmpty) {
        final rawUnread =
            convData['unreadCount'] as Map<String, dynamic>? ?? {};
        final currentUnread =
            (rawUnread[otherParticipantId] as num?)?.toInt() ?? 0;
        convUpdate['unreadCount.$otherParticipantId'] = currentUnread + 1;
      }

      tx.update(convRef, convUpdate);
    });
  }

  Future<void> sendSystemMessage({
    required String conversationId,
    required String content,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());

    await _messages.add({
      'conversationId': conversationId,
      'senderId': 'SYSTEM',
      'content': content,
      'type': 'SYSTEM',
      'createdAt': now,
      'readBy': [],
    });

    await _conversations.doc(conversationId).update({
      'lastMessage': content,
      'lastMessageAt': now,
      'lastSenderId': 'SYSTEM',
    });
  }

  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _conversations.doc(conversationId).update({
      'unreadCount.$userId': 0,
    });
  }

  Stream<int> streamTotalUnreadCount(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unread =
            (data['unreadCount'] as Map<String, dynamic>?)?[userId];
        if (unread is int) total += unread;
      }
      return total;
    });
  }
}
