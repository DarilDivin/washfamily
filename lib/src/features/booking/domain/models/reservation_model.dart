import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationProduct {
  final String productId;
  final String name;
  final double pricePerUnit;

  const ReservationProduct({
    required this.productId,
    required this.name,
    required this.pricePerUnit,
  });

  factory ReservationProduct.fromJson(Map<String, dynamic> json) =>
      ReservationProduct(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'pricePerUnit': pricePerUnit,
      };
}

class ReservationModel {
  final String id;
  final String machineId;
  final String laundryId; // dénormalisé — évite de remonter à la machine
  final String machineBrand;
  final String? machineAddress;
  final String ownerId;
  final String renterId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  // PENDING      → demande en attente de confirmation
  // CONFIRMED    → propriétaire a accepté
  // PICKED_UP    → linge récupéré ou déposé
  // IN_PROGRESS  → lavage en cours
  // READY        → linge prêt, en attente de récupération ou livraison
  // COMPLETED    → linge rendu, service terminé
  // CANCELLED    → annulé
  final String status;
  final String? renterNote;
  final DateTime createdAt;
  final bool reminderSent;
  final bool hasBeenReviewed;

  // Choix du locataire au moment de la réservation
  final String pickupMethod; // 'DROP_OFF' ou 'COLLECTED'
  final bool requestedFolding;
  final bool requestedDelivery;
  final String? deliveryAddress;
  final String? washInstructions;
  final String? selectedProgramId;
  final List<ReservationProduct> selectedProducts;
  final double productsTotal;

  ReservationModel({
    required this.id,
    required this.machineId,
    this.laundryId = '',
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
    this.hasBeenReviewed = false,
    this.pickupMethod = 'DROP_OFF',
    this.requestedFolding = false,
    this.requestedDelivery = false,
    this.deliveryAddress,
    this.washInstructions,
    this.selectedProgramId,
    this.selectedProducts = const [],
    this.productsTotal = 0.0,
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
      laundryId: json['laundryId'] as String? ?? '',
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
      hasBeenReviewed: json['hasBeenReviewed'] as bool? ?? false,
      pickupMethod: json['pickupMethod'] as String? ?? 'DROP_OFF',
      requestedFolding: json['requestedFolding'] as bool? ?? false,
      requestedDelivery: json['requestedDelivery'] as bool? ?? false,
      deliveryAddress: json['deliveryAddress'] as String?,
      washInstructions: json['washInstructions'] as String?,
      selectedProgramId: json['selectedProgramId'] as String?,
      selectedProducts: (json['selectedProducts'] as List<dynamic>?)
              ?.map((e) =>
                  ReservationProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      productsTotal:
          (json['productsTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'laundryId': laundryId,
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
      'hasBeenReviewed': hasBeenReviewed,
      'pickupMethod': pickupMethod,
      'requestedFolding': requestedFolding,
      'requestedDelivery': requestedDelivery,
      'deliveryAddress': deliveryAddress,
      'washInstructions': washInstructions,
      'selectedProgramId': selectedProgramId,
      'selectedProducts': selectedProducts.map((p) => p.toJson()).toList(),
      'productsTotal': productsTotal,
    };
  }

  ReservationModel copyWith({
    String? id,
    String? machineId,
    String? laundryId,
    String? machineBrand,
    String? machineAddress,
    String? ownerId,
    String? renterId,
    DateTime? startTime,
    DateTime? endTime,
    double? totalPrice,
    String? status,
    String? renterNote,
    DateTime? createdAt,
    bool? reminderSent,
    bool? hasBeenReviewed,
    String? pickupMethod,
    bool? requestedFolding,
    bool? requestedDelivery,
    String? deliveryAddress,
    String? washInstructions,
    String? selectedProgramId,
    List<ReservationProduct>? selectedProducts,
    double? productsTotal,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      laundryId: laundryId ?? this.laundryId,
      machineBrand: machineBrand ?? this.machineBrand,
      machineAddress: machineAddress ?? this.machineAddress,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      renterNote: renterNote ?? this.renterNote,
      createdAt: createdAt ?? this.createdAt,
      reminderSent: reminderSent ?? this.reminderSent,
      hasBeenReviewed: hasBeenReviewed ?? this.hasBeenReviewed,
      pickupMethod: pickupMethod ?? this.pickupMethod,
      requestedFolding: requestedFolding ?? this.requestedFolding,
      requestedDelivery: requestedDelivery ?? this.requestedDelivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      washInstructions: washInstructions ?? this.washInstructions,
      selectedProgramId: selectedProgramId ?? this.selectedProgramId,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      productsTotal: productsTotal ?? this.productsTotal,
    );
  }
}
