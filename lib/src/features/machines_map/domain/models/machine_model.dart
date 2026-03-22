class MachineModel {
  final String id;
  final String ownerId;
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
  final String status; // "AVAILABLE", "IN_USE", "MAINTENANCE"
  
  final double rating;
  final int reviewCount;
  
  MachineModel({
    required this.id,
    required this.ownerId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.geohash,
    required this.capacityKg,
    required this.brand,
    required this.description,
    required this.pricePerWash,
    this.currency = "EUR",
    required this.photoUrls,
    this.status = "AVAILABLE",
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  // Future factorisation pour Firestore
  factory MachineModel.fromJson(Map<String, dynamic> json, String documentId) {
    return MachineModel(
      id: documentId,
      ownerId: json['ownerId'] ?? '',
      latitude: json['location']?['lat']?.toDouble() ?? 0.0,
      longitude: json['location']?['lng']?.toDouble() ?? 0.0,
      address: json['location']?['address'],
      geohash: json['location']?['geohash'],
      capacityKg: json['characteristics']?['capacityKg']?.toInt() ?? 0,
      brand: json['characteristics']?['brand'] ?? '',
      description: json['characteristics']?['description'] ?? '',
      pricePerWash: json['pricing']?['pricePerWash']?.toDouble() ?? 0.0,
      currency: json['pricing']?['currency'] ?? 'EUR',
      photoUrls: List<String>.from(json['media']?['photoUrls'] ?? []),
      status: json['status'] ?? 'AVAILABLE',
      rating: json['stats']?['rating']?.toDouble() ?? 0.0,
      reviewCount: json['stats']?['reviewCount']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
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
    };
  }
}
