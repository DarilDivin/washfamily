class WashProgram {
  final String id;
  final String name;
  final int temperatureCelsius;
  final int durationMinutes;
  final bool hasSpin;
  final int? spinSpeedRpm;
  final bool isDelicate;

  const WashProgram({
    required this.id,
    required this.name,
    required this.temperatureCelsius,
    required this.durationMinutes,
    required this.hasSpin,
    this.spinSpeedRpm,
    required this.isDelicate,
  });

  factory WashProgram.fromJson(Map<String, dynamic> json) {
    return WashProgram(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toInt() ?? 30,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      hasSpin: json['hasSpin'] as bool? ?? true,
      spinSpeedRpm: (json['spinSpeedRpm'] as num?)?.toInt(),
      isDelicate: json['isDelicate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'temperatureCelsius': temperatureCelsius,
      'durationMinutes': durationMinutes,
      'hasSpin': hasSpin,
      'spinSpeedRpm': spinSpeedRpm,
      'isDelicate': isDelicate,
    };
  }

  WashProgram copyWith({
    String? id,
    String? name,
    int? temperatureCelsius,
    int? durationMinutes,
    bool? hasSpin,
    int? spinSpeedRpm,
    bool? isDelicate,
  }) {
    return WashProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hasSpin: hasSpin ?? this.hasSpin,
      spinSpeedRpm: spinSpeedRpm ?? this.spinSpeedRpm,
      isDelicate: isDelicate ?? this.isDelicate,
    );
  }
}
