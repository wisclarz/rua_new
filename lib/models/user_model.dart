import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;
  final UserPreferences preferences;
  final UserStats? stats;
  final bool isEmailVerified;
  final String? phoneNumber;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.updatedAt,
    required this.preferences,
    this.stats,
    this.isEmailVerified = false,
    this.phoneNumber,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'preferences': preferences.toJson(),
      'stats': stats?.toJson(),
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
    };
  }

  // Create from Firestore JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      phoneNumber: json['phoneNumber'],
    );
  }

  // CopyWith method
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
    UserStats? stats,
    bool? isEmailVerified,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, isEmailVerified: $isEmailVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserPreferences {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final String dateFormat;
  final String timeFormat;
  final bool analyticsEnabled;
  final int dreamReminderHour;
  final List<String> interests;

  const UserPreferences({
    this.isDarkMode = false,
    this.language = 'tr',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = '24',
    this.analyticsEnabled = true,
    this.dreamReminderHour = 9,
    this.interests = const [],
  });

  // Default preferences
  static UserPreferences defaultPreferences() {
    return const UserPreferences();
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'analyticsEnabled': analyticsEnabled,
      'dreamReminderHour': dreamReminderHour,
      'interests': interests,
    };
  }

  // Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      isDarkMode: json['isDarkMode'] ?? false,
      language: json['language'] ?? 'tr',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      timeFormat: json['timeFormat'] ?? '24',
      analyticsEnabled: json['analyticsEnabled'] ?? true,
      dreamReminderHour: json['dreamReminderHour'] ?? 9,
      interests: List<String>.from(json['interests'] ?? []),
    );
  }

  // CopyWith method
  UserPreferences copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    String? dateFormat,
    String? timeFormat,
    bool? analyticsEnabled,
    int? dreamReminderHour,
    List<String>? interests,
  }) {
    return UserPreferences(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      dreamReminderHour: dreamReminderHour ?? this.dreamReminderHour,
      interests: interests ?? this.interests,
    );
  }
}

class UserStats {
  final int totalDreams;
  final int totalAnalyses;
  final int streakDays;
  final int currentStreak;
  final DateTime? lastDreamDate;
  final int favoriteCount;
  final Map<String, int> moodCounts;
  final Map<String, int> tagCounts;
  final double averageRating;
  final int totalRecordingMinutes;

  const UserStats({
    this.totalDreams = 0,
    this.totalAnalyses = 0,
    this.streakDays = 0,
    this.currentStreak = 0,
    this.lastDreamDate,
    this.favoriteCount = 0,
    this.moodCounts = const {},
    this.tagCounts = const {},
    this.averageRating = 0.0,
    this.totalRecordingMinutes = 0,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalDreams': totalDreams,
      'totalAnalyses': totalAnalyses,
      'streakDays': streakDays,
      'currentStreak': currentStreak,
      'lastDreamDate': lastDreamDate != null ? Timestamp.fromDate(lastDreamDate!) : null,
      'favoriteCount': favoriteCount,
      'moodCounts': moodCounts,
      'tagCounts': tagCounts,
      'averageRating': averageRating,
      'totalRecordingMinutes': totalRecordingMinutes,
    };
  }

  // Create from JSON
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalDreams: json['totalDreams'] ?? 0,
      totalAnalyses: json['totalAnalyses'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      lastDreamDate: (json['lastDreamDate'] as Timestamp?)?.toDate(),
      favoriteCount: json['favoriteCount'] ?? 0,
      moodCounts: Map<String, int>.from(json['moodCounts'] ?? {}),
      tagCounts: Map<String, int>.from(json['tagCounts'] ?? {}),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRecordingMinutes: json['totalRecordingMinutes'] ?? 0,
    );
  }

  // CopyWith method
  UserStats copyWith({
    int? totalDreams,
    int? totalAnalyses,
    int? streakDays,
    int? currentStreak,
    DateTime? lastDreamDate,
    int? favoriteCount,
    Map<String, int>? moodCounts,
    Map<String, int>? tagCounts,
    double? averageRating,
    int? totalRecordingMinutes,
  }) {
    return UserStats(
      totalDreams: totalDreams ?? this.totalDreams,
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
      streakDays: streakDays ?? this.streakDays,
      currentStreak: currentStreak ?? this.currentStreak,
      lastDreamDate: lastDreamDate ?? this.lastDreamDate,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      moodCounts: moodCounts ?? this.moodCounts,
      tagCounts: tagCounts ?? this.tagCounts,
      averageRating: averageRating ?? this.averageRating,
      totalRecordingMinutes: totalRecordingMinutes ?? this.totalRecordingMinutes,
    );
  }
}