import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic Cache Service
///
/// SOLID Principles:
/// - Single Responsibility: Sadece cache işlemlerini yönetir
/// - Open/Closed: Yeni cache stratejileri eklenebilir
/// - Liskov Substitution: Interface pattern kullanır
///
/// Usage:
/// ```dart
/// final cache = CacheService.instance;
/// await cache.put('key', {'data': 'value'}, ttl: Duration(hours: 1));
/// final data = await cache.get<Map>('key');
/// ```
class CacheService {
  static CacheService? _instance;
  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  CacheService._();

  SharedPreferences? _prefs;
  final Map<String, _CacheEntry> _memoryCache = {};

  /// Initialize cache service
  Future<void> initialize() async {
    if (_prefs != null) return;

    debugPrint('🗄️ Initializing CacheService...');
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ CacheService initialized');
  }

  /// Put data into cache with optional TTL
  ///
  /// [key]: Cache key
  /// [value]: Data to cache (must be JSON serializable)
  /// [ttl]: Time to live (default: 1 hour)
  /// [useMemory]: Use in-memory cache (default: true)
  Future<void> put<T>(
    String key,
    T value, {
    Duration ttl = const Duration(hours: 1),
    bool useMemory = true,
  }) async {
    try {
      await _ensureInitialized();

      final now = DateTime.now();
      final expiresAt = now.add(ttl);

      // Memory cache
      if (useMemory) {
        _memoryCache[key] = _CacheEntry(
          value: value,
          expiresAt: expiresAt,
        );
        debugPrint('💾 Cached in memory: $key (TTL: ${ttl.inMinutes}min)');
      }

      // Persistent cache (SharedPreferences)
      final cacheData = {
        'value': value,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      };

      await _prefs!.setString(key, jsonEncode(cacheData));
      debugPrint('💾 Cached persistently: $key');

    } catch (e) {
      debugPrint('❌ Cache put error for $key: $e');
    }
  }

  /// Get data from cache
  ///
  /// Returns null if:
  /// - Key doesn't exist
  /// - Cache expired
  /// - Deserialization failed
  Future<T?> get<T>(String key) async {
    try {
      await _ensureInitialized();

      // Try memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;

        if (entry.isExpired) {
          _memoryCache.remove(key);
          debugPrint('⏰ Memory cache expired: $key');
        } else {
          debugPrint('✅ Cache HIT (memory): $key');
          return entry.value as T;
        }
      }

      // Try persistent cache
      final cachedString = _prefs!.getString(key);
      if (cachedString == null) {
        debugPrint('❌ Cache MISS: $key');
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        cacheData['expiresAt'] as int,
      );

      if (DateTime.now().isAfter(expiresAt)) {
        await _prefs!.remove(key);
        debugPrint('⏰ Persistent cache expired: $key');
        return null;
      }

      debugPrint('✅ Cache HIT (persistent): $key');
      return cacheData['value'] as T;

    } catch (e) {
      debugPrint('❌ Cache get error for $key: $e');
      return null;
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    try {
      await _ensureInitialized();

      _memoryCache.remove(key);
      await _prefs!.remove(key);

      debugPrint('🗑️ Cache removed: $key');
    } catch (e) {
      debugPrint('❌ Cache remove error for $key: $e');
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    try {
      await _ensureInitialized();

      _memoryCache.clear();
      await _prefs!.clear();

      debugPrint('🗑️ All cache cleared');
    } catch (e) {
      debugPrint('❌ Cache clear error: $e');
    }
  }

  /// Clear expired entries
  Future<void> clearExpired() async {
    try {
      await _ensureInitialized();

      // Clear memory cache
      _memoryCache.removeWhere((key, entry) {
        if (entry.isExpired) {
          debugPrint('🗑️ Removed expired memory cache: $key');
          return true;
        }
        return false;
      });

      // Clear persistent cache
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        final cachedString = _prefs!.getString(key);
        if (cachedString == null) continue;

        try {
          final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            cacheData['expiresAt'] as int,
          );

          if (DateTime.now().isAfter(expiresAt)) {
            await _prefs!.remove(key);
            debugPrint('🗑️ Removed expired persistent cache: $key');
          }
        } catch (e) {
          // Invalid format, remove it
          await _prefs!.remove(key);
        }
      }

      debugPrint('✅ Expired cache cleared');
    } catch (e) {
      debugPrint('❌ Clear expired error: $e');
    }
  }

  /// Check if key exists and is not expired
  Future<bool> has(String key) async {
    final value = await get(key);
    return value != null;
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }
}

/// Cache entry with expiration
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache keys for the app
class CacheKeys {
  // Dreams
  static const String userDreams = 'user_dreams';
  static String previousDreams(String userId) => 'previous_dreams_$userId';
  static String dreamDetail(String dreamId) => 'dream_detail_$dreamId';

  // Analysis
  static String dreamAnalysis(String dreamId) => 'dream_analysis_$dreamId';
  static String transcription(String audioHash) => 'transcription_$audioHash';

  // User
  static String userProfile(String userId) => 'user_profile_$userId';
  static const String authToken = 'auth_token';

  // Settings
  static const String appSettings = 'app_settings';
  static const String recordingSettings = 'recording_settings';
}
