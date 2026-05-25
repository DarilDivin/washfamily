import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'TEXT' | 'SYSTEM'
  final DateTime createdAt;
  final List<String> readBy;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.readBy,
  });

  bool get isSystem => type == 'SYSTEM';

  factory MessageModel.fromJson(Map<String, dynamic> json, String docId) {
    return MessageModel(
      id: docId,
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      readBy: List<String>.from(json['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? type,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }
}
