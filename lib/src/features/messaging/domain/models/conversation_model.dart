import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String reservationId;
  final String machineId;
  final String laundryId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.reservationId,
    required this.machineId,
    this.laundryId = '',
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String docId) {
    final rawUnread = json['unreadCount'] as Map<String, dynamic>? ?? {};
    final unread = rawUnread.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));

    return ConversationModel(
      id: docId,
      reservationId: json['reservationId'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      laundryId: json['laundryId'] as String? ?? '',
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] is Timestamp
          ? (json['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastSenderId: json['lastSenderId'] as String? ?? '',
      unreadCount: unread,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'machineId': machineId,
      'laundryId': laundryId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? reservationId,
    String? machineId,
    String? laundryId,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      machineId: machineId ?? this.machineId,
      laundryId: laundryId ?? this.laundryId,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
