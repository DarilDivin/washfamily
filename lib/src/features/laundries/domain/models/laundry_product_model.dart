class LaundryProductModel {
  final String id;
  final String laundryId;
  final String name;
  final String category; // 'DETERGENT' | 'SOFTENER' | 'ACCESSORY'
  final String? description;
  final double pricePerUnit;
  final int stockQuantity;
  final String unit; // 'dose' | 'unité'
  final String? photoUrl;
  final bool isAvailable;

  const LaundryProductModel({
    required this.id,
    required this.laundryId,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.stockQuantity,
    this.description,
    this.unit = 'dose',
    this.photoUrl,
    this.isAvailable = true,
  });

  bool get isInStock => stockQuantity > 0 && isAvailable;

  factory LaundryProductModel.fromJson(Map<String, dynamic> json, String docId) {
    return LaundryProductModel(
      id: docId,
      laundryId: json['laundryId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'DETERGENT',
      description: json['description'] as String?,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'dose',
      photoUrl: json['photoUrl'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'laundryId': laundryId,
        'name': name,
        'category': category,
        if (description != null) 'description': description,
        'pricePerUnit': pricePerUnit,
        'stockQuantity': stockQuantity,
        'unit': unit,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isAvailable': isAvailable,
      };

  LaundryProductModel copyWith({
    String? id,
    String? laundryId,
    String? name,
    String? category,
    String? description,
    double? pricePerUnit,
    int? stockQuantity,
    String? unit,
    String? photoUrl,
    bool? isAvailable,
  }) =>
      LaundryProductModel(
        id: id ?? this.id,
        laundryId: laundryId ?? this.laundryId,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        pricePerUnit: pricePerUnit ?? this.pricePerUnit,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        unit: unit ?? this.unit,
        photoUrl: photoUrl ?? this.photoUrl,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
