class SubscriptionPlanModel {
  final String id;
  final String name;
  final double price;
  final int maxReservationsPerMonth;
  final List<String> features;
  final bool isActive;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.maxReservationsPerMonth,
    required this.features,
    this.isActive = true,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json, String documentId) {
    return SubscriptionPlanModel(
      id: documentId,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      maxReservationsPerMonth: json['maxReservationsPerMonth'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'maxReservationsPerMonth': maxReservationsPerMonth,
      'features': features,
      'isActive': isActive,
    };
  }
}
