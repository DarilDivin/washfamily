import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role; // "USER", "OWNER", ou "ADMIN"
  final DateTime createdAt;
  final String? currentSubscriptionId;
  final DateTime? subscriptionEndDate;
  final int remainingReservations;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.role = 'USER', // Rôle par défaut
    DateTime? createdAt,
    this.currentSubscriptionId,
    this.subscriptionEndDate,
    this.remainingReservations = 2, // 2 réservations d'essai
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid: documentId,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'USER',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentSubscriptionId: json['currentSubscriptionId'],
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? (json['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      remainingReservations: json['remainingReservations'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (currentSubscriptionId != null) 'currentSubscriptionId': currentSubscriptionId,
      if (subscriptionEndDate != null) 'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate!),
      'remainingReservations': remainingReservations,
    };
  }

  // Helper pour savoir si l'utilisateur est propriétaire
  bool get isOwner => role == 'OWNER';

  // Helper pour savoir si l'utilisateur est administrateur
  bool get isAdmin => role == 'ADMIN';
}
