import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String machineId;
  final String machineBrand;
  final String? machineAddress;
  final String ownerId;
  final String renterId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status; // 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'
  final String? renterNote;
  final DateTime createdAt;
  final bool reminderSent;

  ReservationModel({
    required this.id,
    required this.machineId,
    required this.machineBrand,
    this.machineAddress,
    required this.ownerId,
    required this.renterId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.status = 'PENDING',
    this.renterNote,
    DateTime? createdAt,
    this.reminderSent = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReservationModel.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return ReservationModel(
      id: docId,
      machineId: json['machineId'] as String? ?? '',
      machineBrand: json['machineBrand'] as String? ?? 'Machine',
      machineAddress: json['machineAddress'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      renterId: json['renterId'] as String? ?? '',
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      renterNote: json['renterNote'] as String?,
      createdAt: parseDate(json['createdAt']),
      reminderSent: json['reminderSent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'machineBrand': machineBrand,
      'machineAddress': machineAddress,
      'ownerId': ownerId,
      'renterId': renterId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalPrice': totalPrice,
      'status': status,
      'renterNote': renterNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'reminderSent': reminderSent,
    };
  }

  ReservationModel copyWith({String? id, String? status, String? renterNote, bool? reminderSent}) {
    return ReservationModel(
      id: id ?? this.id,
      machineId: machineId,
      machineBrand: machineBrand,
      machineAddress: machineAddress,
      ownerId: ownerId,
      renterId: renterId,
      startTime: startTime,
      endTime: endTime,
      totalPrice: totalPrice,
      status: status ?? this.status,
      renterNote: renterNote ?? this.renterNote,
      createdAt: createdAt,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }
}
