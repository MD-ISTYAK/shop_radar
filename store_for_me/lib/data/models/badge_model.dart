class BadgeModel {
  final String badgeName;
  final String description;
  final int target;
  final int progress;
  final bool earned;
  final DateTime? earnedAt;

  BadgeModel({
    required this.badgeName,
    required this.description,
    required this.target,
    this.progress = 0,
    this.earned = false,
    this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeName: json['badgeName'] ?? '',
      description: json['description'] ?? '',
      target: json['target'] ?? 0,
      progress: json['progress'] ?? 0,
      earned: json['earned'] ?? false,
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt']) : null,
    );
  }

  double get progressPercent => target > 0 ? (progress / target).clamp(0, 1).toDouble() : 0;
}

class ReferralModel {
  final String id;
  final String referralCode;
  final List<ReferralEntry> referrals;
  final int totalReferrals;
  final int completedReferrals;
  final double totalRewards;

  ReferralModel({
    required this.id,
    required this.referralCode,
    this.referrals = const [],
    this.totalReferrals = 0,
    this.completedReferrals = 0,
    this.totalRewards = 0,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: '',
      referralCode: json['referralCode'] ?? '',
      referrals: json['referrals'] != null
          ? (json['referrals'] as List).map((r) => ReferralEntry.fromJson(r)).toList()
          : [],
      totalReferrals: json['totalReferrals'] ?? 0,
      completedReferrals: json['completedReferrals'] ?? 0,
      totalRewards: (json['totalRewards'] ?? 0).toDouble(),
    );
  }
}

class ReferralEntry {
  final String id;
  final String refereeName;
  final String refereeAvatar;
  final String status;
  final double rewardAmount;
  final DateTime createdAt;

  ReferralEntry({
    required this.id,
    this.refereeName = '',
    this.refereeAvatar = '',
    this.status = 'pending',
    this.rewardAmount = 50,
    required this.createdAt,
  });

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    final referee = json['refereeId'];
    return ReferralEntry(
      id: json['_id'] ?? '',
      refereeName: referee is Map ? (referee['name'] ?? '') : '',
      refereeAvatar: referee is Map ? (referee['avatar'] ?? '') : '',
      status: json['status'] ?? 'pending',
      rewardAmount: (json['rewardAmount'] ?? 50).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
