class SubscriptionPlanModel {
  final String id;
  final String name;
  final double price;
  final String targetRole;       // 'USER' | 'OWNER'
  final int reservationQuota;    // -1 = illimité
  final int maxMachines;         // -1 = illimité, 0 = non applicable
  final double commissionRate;   // 0.0 à 1.0
  final bool hasVerifiedBadge;
  final String analyticsLevel;   // 'NONE' | 'BASIC' | 'FULL'
  final List<String> features;
  final int durationDays;
  final bool isActive;

  // Backward compat — alias de reservationQuota
  int get maxReservationsPerMonth => reservationQuota;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    this.targetRole = 'USER',
    this.reservationQuota = 0,
    this.maxMachines = 0,
    this.commissionRate = 0.0,
    this.hasVerifiedBadge = false,
    this.analyticsLevel = 'NONE',
    required this.features,
    this.durationDays = 30,
    this.isActive = true,
  });

  factory SubscriptionPlanModel.fromJson(
      Map<String, dynamic> json, String docId) {
    return SubscriptionPlanModel(
      id: docId,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      targetRole: json['targetRole'] as String? ?? 'USER',
      reservationQuota: (json['reservationQuota'] as num?)?.toInt() ??
          (json['maxReservationsPerMonth'] as num?)?.toInt() ??
          0,
      maxMachines: (json['maxMachines'] as num?)?.toInt() ?? 0,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.0,
      hasVerifiedBadge: json['hasVerifiedBadge'] as bool? ?? false,
      analyticsLevel: json['analyticsLevel'] as String? ?? 'NONE',
      features: List<String>.from(json['features'] as List? ?? []),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'targetRole': targetRole,
        'reservationQuota': reservationQuota,
        'maxMachines': maxMachines,
        'commissionRate': commissionRate,
        'hasVerifiedBadge': hasVerifiedBadge,
        'analyticsLevel': analyticsLevel,
        'features': features,
        'durationDays': durationDays,
        'isActive': isActive,
      };
}
