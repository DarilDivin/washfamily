import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
  final Map<String, String> openingHours;
  final double rating;
  final int reviewCount;
  final bool offersFolding;
  final bool offersPickup;
  final bool offersDelivery;
  final double? deliveryFee;
  final int? deliveryZoneKm;
  final bool isActive;
  final DateTime createdAt;

  bool get hasDelivery =>
      offersDelivery && deliveryFee != null && deliveryZoneKm != null;

  LaundryModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoUrls = const [],
    this.openingHours = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.offersFolding = false,
    this.offersPickup = false,
    this.offersDelivery = false,
    this.deliveryFee,
    this.deliveryZoneKm,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LaundryModel.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    final service = json['service'] as Map<String, dynamic>? ?? {};

    return LaundryModel(
      id: docId,
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrls: List<String>.from(json['photoUrls'] as List? ?? []),
      openingHours: Map<String, String>.from(
        (json['openingHours'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      offersFolding: service['offersFolding'] as bool? ?? false,
      offersPickup: service['offersPickup'] as bool? ?? false,
      offersDelivery: service['offersDelivery'] as bool? ?? false,
      deliveryFee: (service['deliveryFee'] as num?)?.toDouble(),
      deliveryZoneKm: (service['deliveryZoneKm'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrls': photoUrls,
      'openingHours': openingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'service': {
        'offersFolding': offersFolding,
        'offersPickup': offersPickup,
        'offersDelivery': offersDelivery,
        'deliveryFee': deliveryFee,
        'deliveryZoneKm': deliveryZoneKm,
      },
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  LaundryModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    Map<String, String>? openingHours,
    double? rating,
    int? reviewCount,
    bool? offersFolding,
    bool? offersPickup,
    bool? offersDelivery,
    double? deliveryFee,
    int? deliveryZoneKm,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LaundryModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      offersFolding: offersFolding ?? this.offersFolding,
      offersPickup: offersPickup ?? this.offersPickup,
      offersDelivery: offersDelivery ?? this.offersDelivery,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryZoneKm: deliveryZoneKm ?? this.deliveryZoneKm,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
