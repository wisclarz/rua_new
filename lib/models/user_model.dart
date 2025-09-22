import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final HealthData? healthData;
  final UserPreferences preferences;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.healthData,
    required this.preferences,
    this.isEmailVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'healthData': healthData?.toJson(),
      'preferences': preferences.toJson(),
      'isEmailVerified': isEmailVerified,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      healthData: json['healthData'] != null 
          ? HealthData.fromJson(json['healthData']) 
          : null,
      preferences: json['preferences'] != null 
          ? UserPreferences.fromJson(json['preferences'])
          : UserPreferences.defaultPreferences(),
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    HealthData? healthData,
    UserPreferences? preferences,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      healthData: healthData ?? this.healthData,
      preferences: preferences ?? this.preferences,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class HealthData {
  final DateTime? bedTime;
  final DateTime? wakeTime;
  final int sleepQuality; // 1-10 scale
  final double sleepDuration; // hours
  final bool isHealthKitConnected;
  final DateTime? lastSyncAt;

  HealthData({
    this.bedTime,
    this.wakeTime,
    this.sleepQuality = 5,
    this.sleepDuration = 8.0,
    this.isHealthKitConnected = false,
    this.lastSyncAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'bedTime': bedTime?.toIso8601String(),
      'wakeTime': wakeTime?.toIso8601String(),
      'sleepQuality': sleepQuality,
      'sleepDuration': sleepDuration,
      'isHealthKitConnected': isHealthKitConnected,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      bedTime: json['bedTime'] != null ? DateTime.parse(json['bedTime']) : null,
      wakeTime: json['wakeTime'] != null ? DateTime.parse(json['wakeTime']) : null,
      sleepQuality: json['sleepQuality'] ?? 5,
      sleepDuration: (json['sleepDuration'] ?? 8.0).toDouble(),
      isHealthKitConnected: json['isHealthKitConnected'] ?? false,
      lastSyncAt: json['lastSyncAt'] != null ? DateTime.parse(json['lastSyncAt']) : null,
    );
  }
}

class UserPreferences {
  final bool notificationsEnabled;
  final TimeOfDay? dreamReminderTime;
  final bool voiceRecordingEnabled;
  final String language;
  final bool darkModeEnabled;
  final bool analyticsEnabled;

  UserPreferences({
    this.notificationsEnabled = true,
    this.dreamReminderTime,
    this.voiceRecordingEnabled = true,
    this.language = 'tr',
    this.darkModeEnabled = false,
    this.analyticsEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'dreamReminderTime': dreamReminderTime != null 
          ? '${dreamReminderTime!.hour}:${dreamReminderTime!.minute}'
          : null,
      'voiceRecordingEnabled': voiceRecordingEnabled,
      'language': language,
      'darkModeEnabled': darkModeEnabled,
      'analyticsEnabled': analyticsEnabled,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminderTime;
    if (json['dreamReminderTime'] != null) {
      final timeParts = json['dreamReminderTime'].split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      dreamReminderTime: reminderTime,
      voiceRecordingEnabled: json['voiceRecordingEnabled'] ?? true,
      language: json['language'] ?? 'tr',
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      analyticsEnabled: json['analyticsEnabled'] ?? true,
    );
  }

  static UserPreferences defaultPreferences() {
    return UserPreferences(
      notificationsEnabled: true,
      dreamReminderTime: const TimeOfDay(hour: 9, minute: 0),
      voiceRecordingEnabled: true,
      language: 'tr',
      darkModeEnabled: false,
      analyticsEnabled: true,
    );
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    TimeOfDay? dreamReminderTime,
    bool? voiceRecordingEnabled,
    String? language,
    bool? darkModeEnabled,
    bool? analyticsEnabled,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dreamReminderTime: dreamReminderTime ?? this.dreamReminderTime,
      voiceRecordingEnabled: voiceRecordingEnabled ?? this.voiceRecordingEnabled,
      language: language ?? this.language,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

// TimeOfDay helper class for material design
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
