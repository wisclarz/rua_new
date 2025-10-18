// lib/providers/subscription_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/subscription_model.dart';
import '../services/cache_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppPurchase _iap = InAppPurchase.instance;

  Subscription? _currentSubscription;
  bool _isLoading = false;
  bool _hasLoadedFromFirestore = false; // ⚡ Track if already loaded from Firestore
  String? _errorMessage;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 🔒 SECURITY: Always check expiration before granting Pro access
  bool get isPro {
    if (_currentSubscription == null) return false;

    // Check if subscription has expired
    if (_currentSubscription!.hasExpired) {
      // Trigger expiration in background (don't block UI)
      Future.microtask(() => _expireSubscriptionIfNeeded());
      return false; // Return false immediately for expired subscriptions
    }

    return _currentSubscription!.isPro;
  }

  SubscriptionPlan get currentPlan {
    if (_currentSubscription == null) return SubscriptionPlan.free;

    // Check if subscription has expired
    if (_currentSubscription!.hasExpired) {
      return SubscriptionPlan.free; // Return free plan for expired subscriptions
    }

    return _currentSubscription!.plan;
  }

  List<ProductDetails> get products => _products;
  bool get isAdLoaded => _isAdLoaded;

  SubscriptionProvider() {
    // ⚡ Set default free subscription (prevents null crashes)
    _currentSubscription = Subscription(
      id: 'temp',
      userId: '',
      plan: SubscriptionPlan.free,
      startDate: DateTime.now(),
      isActive: true,
    );

    // ⚡ CHANGED: Don't auto-load subscription in constructor
    // Subscription will be loaded by ChangeNotifierProxyProvider when auth is ready
    // Cache will replace this default instantly if available

    // Initialize In-App Purchase and AdMob in background
    Future.microtask(() async {
      try {
        // Initialize In-App Purchase
        final bool available = await _iap.isAvailable();
        if (available) {
          await _loadProducts();
          _listenToPurchaseUpdated();
        }

        // Initialize AdMob
        await MobileAds.instance.initialize();

        debugPrint('✅ IAP and AdMob initialized');
      } catch (e) {
        debugPrint('❌ IAP/AdMob initialization error: $e');
      }
    });
  }

  Future<void> loadUserSubscription() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentSubscription = Subscription(
        id: 'free',
        userId: '',
        plan: SubscriptionPlan.free,
        startDate: DateTime.now(),
        isActive: true,
      );
      notifyListeners();
      return;
    }

    // ⚡ Skip if already loaded from Firestore
    if (_hasLoadedFromFirestore) {
      debugPrint('⚡ Subscription already loaded from Firestore, skipping');
      return;
    }

    // ⚡ PERFORMANCE: Load cached subscription immediately for instant UI
    await _loadCachedSubscription(user.uid);

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        _currentSubscription = Subscription.fromMap(data);

        // Check if subscription has expired
        if (_currentSubscription!.hasExpired) {
          await _expireSubscription();
        }

        // ⚡ CACHE: Save to cache for next app launch
        await _cacheSubscription(user.uid, _currentSubscription!);
      } else {
        // Create free subscription for new users
        _currentSubscription = Subscription(
          id: user.uid,
          userId: user.uid,
          plan: SubscriptionPlan.free,
          startDate: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('subscriptions')
            .doc(user.uid)
            .set(_currentSubscription!.toMap());

        // ⚡ CACHE: Save free subscription
        await _cacheSubscription(user.uid, _currentSubscription!);
      }

      _errorMessage = null;
      _hasLoadedFromFirestore = true; // ⚡ Mark as loaded
      debugPrint('✅ Subscription loaded from Firestore: ${_currentSubscription!.plan.name}');
    } catch (e) {
      _errorMessage = 'Abonelik yüklenemedi: $e';
      debugPrint('❌ Load subscription error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ⚡ Load cached subscription for instant UI
  Future<void> _loadCachedSubscription(String userId) async {
    try {
      final cachedData = await CacheService.instance.get<Map>(
        'subscription_$userId',
      );

      if (cachedData != null) {
        final subscription = Subscription.fromMap(
          Map<String, dynamic>.from(cachedData),
        );

        // 🔒 SECURITY: Check if cached subscription has expired
        if (subscription.hasExpired) {
          debugPrint('⏰ Cached subscription EXPIRED, using free plan instead');

          // Remove expired cache
          await CacheService.instance.remove('subscription_$userId');

          // Set to free plan
          _currentSubscription = Subscription(
            id: userId,
            userId: userId,
            plan: SubscriptionPlan.free,
            startDate: DateTime.now(),
            isActive: true,
          );
          notifyListeners();

          debugPrint('✅ Switched to free plan due to expiration');
        } else {
          // Cache is valid, use it
          _currentSubscription = subscription;
          notifyListeners();

          debugPrint('⚡ UI populated with cached subscription: ${_currentSubscription!.plan.name} (instant load!)');
        }
      } else {
        debugPrint('📭 No cached subscription found');
      }
    } catch (e) {
      debugPrint('⚠️ Subscription cache load error: $e');
      // Continue without cache
    }
  }

  /// ⚡ Cache subscription for next app launch
  Future<void> _cacheSubscription(String userId, Subscription subscription) async {
    try {
      await CacheService.instance.put(
        'subscription_$userId',
        subscription.toMap(),
        ttl: const Duration(days: 7), // Cache for 7 days
      );

      debugPrint('💾 Cached subscription: ${subscription.plan.name}');
    } catch (e) {
      debugPrint('⚠️ Subscription cache save error: $e');
      // Continue without caching
    }
  }

  // ==================== IN-APP PURCHASE ====================
  
  Future<void> _loadProducts() async {
    try {
      const Set<String> productIds = {
        'weekly_pro_plan',
        'monthly_pro_plan',
      };

      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('❌ Product load error: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('✅ Loaded ${_products.length} products');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Load products error: $e');
    }
  }

  void _listenToPurchaseUpdated() {
    _purchaseSubscription = _iap.purchaseStream.listen(
      (List<PurchaseDetails> purchases) async {
        for (var purchase in purchases) {
          await _handlePurchase(purchase);
        }
      },
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => debugPrint('❌ Purchase stream error: $error'),
    );
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased) {
      // Verify purchase and activate subscription
      await _activateSubscription(purchase);
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> purchaseSubscription(SubscriptionPlan plan) async {
    if (plan == SubscriptionPlan.free) return;

    try {
      final product = _products.firstWhere(
        (p) => p.id == plan.productId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      _isLoading = true;
      notifyListeners();

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = 'Satın alma başarısız: $e';
      debugPrint('❌ Purchase error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _activateSubscription(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      SubscriptionPlan plan;
      DateTime endDate;

      if (purchase.productID == 'weekly_pro_plan') {
        plan = SubscriptionPlan.weeklyPro;
        endDate = DateTime.now().add(const Duration(days: 7));
      } else if (purchase.productID == 'monthly_pro_plan') {
        plan = SubscriptionPlan.monthlyPro;
        endDate = DateTime.now().add(const Duration(days: 30));
      } else {
        return;
      }

      final subscription = Subscription(
        id: user.uid,
        userId: user.uid,
        plan: plan,
        startDate: DateTime.now(),
        endDate: endDate,
        isActive: true,
        transactionId: purchase.purchaseID,
      );

      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .set(subscription.toMap());

      _currentSubscription = subscription;
      _errorMessage = null;
      
      debugPrint('✅ Subscription activated: ${plan.name}');
    } catch (e) {
      _errorMessage = 'Abonelik aktifleştirilemedi: $e';
      debugPrint('❌ Activate subscription error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _expireSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final freeSubscription = Subscription(
        id: user.uid,
        userId: user.uid,
        plan: SubscriptionPlan.free,
        startDate: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .set(freeSubscription.toMap());

      _currentSubscription = freeSubscription;
      _hasLoadedFromFirestore = true;

      // Update cache with free subscription
      await _cacheSubscription(user.uid, freeSubscription);

      debugPrint('⏰ Subscription expired, moved to free plan');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Expire subscription error: $e');
    }
  }

  /// 🔒 Expire subscription if needed (called from getter)
  /// Only runs once to prevent multiple Firestore writes
  bool _isExpiring = false;

  Future<void> _expireSubscriptionIfNeeded() async {
    if (_isExpiring) return; // Prevent duplicate expiration calls
    if (_currentSubscription == null) return;
    if (!_currentSubscription!.hasExpired) return;

    _isExpiring = true;
    debugPrint('🔒 Expiring subscription in background...');

    await _expireSubscription();

    _isExpiring = false;
  }

  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _iap.restorePurchases();
      await loadUserSubscription();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Satın almalar geri yüklenemedi: $e';
      debugPrint('❌ Restore purchases error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ADMOB REWARDED ADS ====================

  Future<void> loadRewardedAd() async {
    if (_isAdLoaded) {
      debugPrint('⚠️ Ad already loaded');
      return;
    }

    await RewardedAd.load(
      // Test Ad Unit ID - Production'da gerçek ID kullanın
      adUnitId: 'ca-app-pub-8382186556433873~1782125268', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          debugPrint('✅ Rewarded ad loaded');
          notifyListeners();

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              notifyListeners();
              loadRewardedAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              notifyListeners();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
          _isAdLoaded = false;
          notifyListeners();
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || !_isAdLoaded) {
      debugPrint('⚠️ Ad not loaded yet');
      await loadRewardedAd();
      return false;
    }

    bool adWatched = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint('✅ User earned reward: ${reward.amount} ${reward.type}');
        adWatched = true;
        
        // Increment ad watch count
        await _incrementAdWatchCount();
      },
    );

    return adWatched;
  }

  Future<void> _incrementAdWatchCount() async {
    final user = _auth.currentUser;
    if (user == null || _currentSubscription == null) return;

    try {
      final newCount = (_currentSubscription!.adWatchCount ?? 0) + 1;
      
      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .update({'adWatchCount': newCount});

      _currentSubscription = _currentSubscription!.copyWith(
        adWatchCount: newCount,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Increment ad count error: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _rewardedAd?.dispose();
    super.dispose();
  }
}