import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final List<String> roles; // ex: ['USER'], ['OWNER'], ['USER', 'OWNER'], ['ADMIN', 'OWNER']
  final DateTime createdAt;
  final String? currentSubscriptionId;
  final DateTime? subscriptionEndDate;
  final int remainingReservations;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    List<String>? roles,
    DateTime? createdAt,
    this.currentSubscriptionId,
    this.subscriptionEndDate,
    this.remainingReservations = 2,
  })  : roles = roles ?? ['USER'],
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    // Lit 'roles' (List) ou 'role' (List ou String pour rétrocompat)
    List<String> parsedRoles;
    final rolesVal = json['roles'];
    final roleVal = json['role'];
    if (rolesVal is List) {
      parsedRoles = List<String>.from(rolesVal);
    } else if (roleVal is List) {
      parsedRoles = List<String>.from(roleVal);
    } else {
      parsedRoles = [(roleVal as String? ?? 'USER')];
    }

    return UserModel(
      uid: documentId,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roles: parsedRoles,
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
      'roles': roles,
      'createdAt': Timestamp.fromDate(createdAt),
      if (currentSubscriptionId != null) 'currentSubscriptionId': currentSubscriptionId,
      if (subscriptionEndDate != null) 'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate!),
      'remainingReservations': remainingReservations,
    };
  }

  bool get isOwner => roles.contains('OWNER');
  bool get isAdmin => roles.contains('ADMIN');
  bool get isUser => roles.contains('USER');
}
