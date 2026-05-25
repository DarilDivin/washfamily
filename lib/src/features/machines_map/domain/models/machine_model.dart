import 'wash_program_model.dart';

class MachineModel {
  final String id;
  final String ownerId;
  final String laundryId;     // dénormalisé pour les queries
  final String nickname;       // "Machine du couloir", "LG Bleue"
  final String? model;         // référence constructeur ex: "F4WV510S0E"
  final int? manufactureYear;
  final bool isAvailable;      // disponible ou en cours d'utilisation

  final double latitude;
  final double longitude;
  final String? address;
  final String? geohash;

  final int capacityKg;
  final String brand;
  final String description;
  final double pricePerWash;
  final String currency;

  final List<String> photoUrls;
  final String status; // "AVAILABLE", "IN_USE", "MAINTENANCE" — conservé pour compatibilité

  final double rating;
  final int reviewCount;

  // Disponibilités
  final List<int> availableDays;
  final int startTimeHour;
  final int endTimeHour;

  // Programmes de lavage disponibles sur cette machine
  final List<WashProgram> programs;

  MachineModel({
    required this.id,
    required this.ownerId,
    this.laundryId = '',
    this.nickname = '',
    this.model,
    this.manufactureYear,
    this.isAvailable = true,
    required this.latitude,
    required this.longitude,
    this.address,
    this.geohash,
    required this.capacityKg,
    required this.brand,
    required this.description,
    required this.pricePerWash,
    this.currency = 'EUR',
    required this.photoUrls,
    this.status = 'AVAILABLE',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.availableDays = const [1, 2, 3, 4, 5, 6, 7],
    this.startTimeHour = 8,
    this.endTimeHour = 21,
    this.programs = const [],
  });

  factory MachineModel.fromJson(Map<String, dynamic> json, String documentId) {
    final status = json['status'] as String? ?? 'AVAILABLE';
    final serviceJson = json['service'] as Map<String, dynamic>?;

    return MachineModel(
      id: documentId,
      ownerId: json['ownerId'] as String? ?? '',
      laundryId: json['laundryId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      model: json['model'] as String?,
      manufactureYear: (json['manufactureYear'] as num?)?.toInt(),
      // Pour les docs existants sans isAvailable, on calcule depuis status
      isAvailable: json['isAvailable'] as bool? ?? (status == 'AVAILABLE'),
      latitude: (json['location']?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['location']?['address'] as String?,
      geohash: json['location']?['geohash'] as String?,
      capacityKg: (json['characteristics']?['capacityKg'] as num?)?.toInt() ?? 0,
      brand: json['characteristics']?['brand'] as String? ?? '',
      description: json['characteristics']?['description'] as String? ?? '',
      pricePerWash: (json['pricing']?['pricePerWash'] as num?)?.toDouble() ?? 0.0,
      currency: json['pricing']?['currency'] as String? ?? 'EUR',
      photoUrls: List<String>.from(json['media']?['photoUrls'] as List? ?? []),
      status: status,
      rating: (json['stats']?['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['stats']?['reviewCount'] as num?)?.toInt() ?? 0,
      availableDays: json['availability']?['availableDays'] != null
          ? List<int>.from(json['availability']['availableDays'] as List)
          : const [1, 2, 3, 4, 5, 6, 7],
      startTimeHour: (json['availability']?['startTimeHour'] as num?)?.toInt() ?? 8,
      endTimeHour: (json['availability']?['endTimeHour'] as num?)?.toInt() ?? 21,
      programs: (serviceJson?['programs'] as List<dynamic>?)
              ?.map((e) => WashProgram.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'laundryId': laundryId,
      'nickname': nickname,
      'model': model,
      'manufactureYear': manufactureYear,
      'isAvailable': isAvailable,
      'location': {
        'lat': latitude,
        'lng': longitude,
        'address': address,
        'geohash': geohash,
      },
      'characteristics': {
        'capacityKg': capacityKg,
        'brand': brand,
        'description': description,
      },
      'pricing': {
        'pricePerWash': pricePerWash,
        'currency': currency,
      },
      'media': {
        'photoUrls': photoUrls,
      },
      'status': status,
      'stats': {
        'rating': rating,
        'reviewCount': reviewCount,
      },
      'availability': {
        'availableDays': availableDays,
        'startTimeHour': startTimeHour,
        'endTimeHour': endTimeHour,
      },
      'service': {
        'programs': programs.map((p) => p.toJson()).toList(),
      },
    };
  }

  MachineModel copyWith({
    String? id,
    String? ownerId,
    String? laundryId,
    String? nickname,
    String? model,
    int? manufactureYear,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? address,
    String? geohash,
    int? capacityKg,
    String? brand,
    String? description,
    double? pricePerWash,
    String? currency,
    List<String>? photoUrls,
    String? status,
    double? rating,
    int? reviewCount,
    List<int>? availableDays,
    int? startTimeHour,
    int? endTimeHour,
    List<WashProgram>? programs,
  }) {
    return MachineModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      laundryId: laundryId ?? this.laundryId,
      nickname: nickname ?? this.nickname,
      model: model ?? this.model,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      geohash: geohash ?? this.geohash,
      capacityKg: capacityKg ?? this.capacityKg,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      pricePerWash: pricePerWash ?? this.pricePerWash,
      currency: currency ?? this.currency,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availableDays: availableDays ?? this.availableDays,
      startTimeHour: startTimeHour ?? this.startTimeHour,
      endTimeHour: endTimeHour ?? this.endTimeHour,
      programs: programs ?? this.programs,
    );
  }
}
