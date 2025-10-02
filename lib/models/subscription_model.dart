// lib/models/subscription_model.dart

enum SubscriptionPlan {
  free,
  weeklyPro,
  monthlyPro,
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get name {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Ücretsiz';
      case SubscriptionPlan.weeklyPro:
        return 'Haftalık Pro';
      case SubscriptionPlan.monthlyPro:
        return 'Aylık Pro';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Rüya analizleri blurlu, reklam izle';
      case SubscriptionPlan.weeklyPro:
        return 'Tüm özellikler, reklamsız';
      case SubscriptionPlan.monthlyPro:
        return 'Tüm özellikler, reklamsız, %20 indirim';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.weeklyPro:
        return 50.0;
      case SubscriptionPlan.monthlyPro:
        return 120.0;
    }
  }

  String get priceText {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Ücretsiz';
      case SubscriptionPlan.weeklyPro:
        return '50 TL/hafta';
      case SubscriptionPlan.monthlyPro:
        return '120 TL/ay';
    }
  }

  // Product ID for In-App Purchase
  String get productId {
    switch (this) {
      case SubscriptionPlan.free:
        return '';
      case SubscriptionPlan.weeklyPro:
        return 'weekly_pro_plan';
      case SubscriptionPlan.monthlyPro:
        return 'monthly_pro_plan';
    }
  }

  bool get isPro {
    return this == SubscriptionPlan.weeklyPro || 
           this == SubscriptionPlan.monthlyPro;
  }
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? transactionId;
  final int? adWatchCount; // Free plan için reklam izleme sayısı

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.transactionId,
    this.adWatchCount,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.toString() == map['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isActive: map['isActive'] ?? false,
      transactionId: map['transactionId'],
      adWatchCount: map['adWatchCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'transactionId': transactionId,
      'adWatchCount': adWatchCount,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? transactionId,
    int? adWatchCount,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      transactionId: transactionId ?? this.transactionId,
      adWatchCount: adWatchCount ?? this.adWatchCount,
    );
  }

  bool get hasExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isPro => plan.isPro && isActive && !hasExpired;
}