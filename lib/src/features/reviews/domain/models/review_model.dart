import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String machineId;
  final String ownerId;
  final String renterId;
  final String reservationId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.machineId,
    required this.ownerId,
    required this.renterId,
    required this.reservationId,
    required this.rating,
    this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReviewModel.fromJson(Map<String, dynamic> json, String docId) {
    return ReviewModel(
      id: docId,
      machineId: json['machineId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      renterId: json['renterId'] as String? ?? '',
      reservationId: json['reservationId'] as String? ?? docId,
      rating: (json['rating'] as num?)?.toInt() ?? 1,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'ownerId': ownerId,
      'renterId': renterId,
      'reservationId': reservationId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? machineId,
    String? ownerId,
    String? renterId,
    String? reservationId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      reservationId: reservationId ?? this.reservationId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
