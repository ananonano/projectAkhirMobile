class VoucherModel {
  final int? id;
  final String username;
  final int percentDiscount; // 1, 2, 3, ... 10, etc
  final int earnedScore; // Score yang menghasilkan voucher ini (misal 1000, 2000, 10000)
  final bool isUsed;
  final String? usedAt; // timestamp saat voucher dipakai
  final String createdAt;

  VoucherModel({
    this.id,
    required this.username,
    required this.percentDiscount,
    required this.earnedScore,
    this.isUsed = false,
    this.usedAt,
    required this.createdAt,
  });

  // Convert to Map untuk database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'percent_discount': percentDiscount,
      'earned_score': earnedScore,
      'is_used': isUsed ? 1 : 0,
      'used_at': usedAt,
      'created_at': createdAt,
    };
  }

  // Convert dari Map database
  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      percentDiscount: map['percent_discount'] as int,
      earnedScore: map['earned_score'] as int,
      isUsed: (map['is_used'] as int) == 1,
      usedAt: map['used_at'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  // Copy with untuk modifikasi
  VoucherModel copyWith({
    int? id,
    String? username,
    int? percentDiscount,
    int? earnedScore,
    bool? isUsed,
    String? usedAt,
    String? createdAt,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      username: username ?? this.username,
      percentDiscount: percentDiscount ?? this.percentDiscount,
      earnedScore: earnedScore ?? this.earnedScore,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
