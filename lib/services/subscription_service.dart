import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jadwal/pages/screens/PaywallPage/paywall_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

/// RevenueCat-backed Free / Pro subscription state.
class SubscriptionService extends ChangeNotifier {
  static const entitlementId = 'pro';
  static const offeringId = 'default';
  static const productMonthId = 'jadwal_pro_month';
  static const productYearId = 'jadwal_pro_year';
  static const freeQuizzesPerDay = 3;

  bool _configured = false;
  bool _isPro = false;
  bool _loading = false;
  Offering? _currentOffering;
  int _quizzesUsedToday = 0;
  String _usageDate = '';
  bool _lastPurchaseCancelled = false;
  String? _activeProductId;
  DateTime? _proExpirationDate;
  bool _willRenew = false;

  bool get isConfigured => _configured;
  bool get isPro => _isPro;
  bool get isLoading => _loading;
  Offering? get currentOffering => _currentOffering;
  int get quizzesUsedToday => _quizzesUsedToday;
  bool get lastPurchaseCancelled => _lastPurchaseCancelled;
  String? get activeProductId => _activeProductId;
  DateTime? get proExpirationDate => _proExpirationDate;
  bool get willRenew => _willRenew;
  int get quizzesRemainingToday =>
      _isPro ? freeQuizzesPerDay : (freeQuizzesPerDay - _quizzesUsedToday).clamp(0, freeQuizzesPerDay);

  bool get isOnYearlyPlan {
    if (!_isPro || _activeProductId == null) return false;
    final id = _activeProductId!;
    return id == productYearId ||
        id == yearlyPackage?.storeProduct.identifier ||
        id.toLowerCase().contains('year') ||
        id.toLowerCase().contains('annual');
  }

  bool get isOnMonthlyPlan {
    if (!_isPro || _activeProductId == null) return false;
    final id = _activeProductId!;
    return id == productMonthId ||
        id == monthlyPackage?.storeProduct.identifier ||
        id.toLowerCase().contains('month');
  }

  String? get renewalLabel {
    final date = _proExpirationDate;
    if (!_isPro || date == null) return null;
    final formatted =
        '${date.day} ${_monthShort(date.month)} ${date.year}';
    return _willRenew ? 'Renews $formatted' : 'Expires $formatted';
  }

  static String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> init() async {
    if (_configured) return;

    final iosKey = dotenv.env['REVENUECAT_IOS_API_KEY']?.trim() ?? '';
    final androidKey = dotenv.env['REVENUECAT_ANDROID_API_KEY']?.trim() ?? '';

    try {
      late final PurchasesConfiguration config;
      if (Platform.isIOS) {
        if (iosKey.isEmpty) {
          debugPrint('SubscriptionService: missing REVENUECAT_IOS_API_KEY');
          return;
        }
        config = PurchasesConfiguration(iosKey);
      } else if (Platform.isAndroid) {
        if (androidKey.isEmpty) {
          debugPrint(
              'SubscriptionService: Android key not set; purchases disabled');
          await _loadQuizUsageFromFirestore();
          return;
        }
        config = PurchasesConfiguration(androidKey);
      } else {
        return;
      }

      await Purchases.configure(config);
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      _configured = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await logIn(user.uid);
      } else {
        await refreshCustomerInfo();
      }
      await _loadQuizUsageFromFirestore();
    } catch (e, st) {
      debugPrint('SubscriptionService.init error: $e\n$st');
    }
  }

  Future<void> logIn(String uid) async {
    if (!_configured) {
      await _loadQuizUsageFromFirestore();
      return;
    }
    try {
      final result = await Purchases.logIn(uid);
      await _applyCustomerInfo(result.customerInfo);
      await loadOfferings();
      await _loadQuizUsageFromFirestore();
      if (_isPro) {
        await _syncProToServer();
      }
    } catch (e, st) {
      debugPrint('SubscriptionService.logIn error: $e\n$st');
      await _loadQuizUsageFromFirestore();
    }
  }

  Future<void> logOut() async {
    if (_configured) {
      try {
        final info = await Purchases.logOut();
        await _applyCustomerInfo(info);
      } catch (e) {
        debugPrint('SubscriptionService.logOut error: $e');
        _isPro = false;
        _activeProductId = null;
        _proExpirationDate = null;
        _willRenew = false;
        notifyListeners();
      }
    } else {
      _isPro = false;
      _activeProductId = null;
      _proExpirationDate = null;
      _willRenew = false;
      notifyListeners();
    }
    _quizzesUsedToday = 0;
    _usageDate = '';
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _applyCustomerInfo(info);
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    final entitlement = info.entitlements.active[entitlementId];
    final active = entitlement != null;
    final productId = entitlement?.productIdentifier;
    final expiration = entitlement?.expirationDate != null
        ? DateTime.tryParse(entitlement!.expirationDate!)
        : null;
    final renews = entitlement?.willRenew ?? false;

    final changed = active != _isPro ||
        productId != _activeProductId ||
        expiration != _proExpirationDate ||
        renews != _willRenew;

    _isPro = active;
    _activeProductId = active ? productId : null;
    _proExpirationDate = active ? expiration : null;
    _willRenew = active && renews;

    if (changed) {
      notifyListeners();
      await _mirrorProToFirestore();
    }
  }

  Future<void> refreshCustomerInfo() async {
    if (!_configured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info);
    } catch (e) {
      debugPrint('SubscriptionService.refreshCustomerInfo error: $e');
    }
  }

  Future<void> loadOfferings() async {
    if (!_configured) return;
    try {
      final offerings = await Purchases.getOfferings();
      _currentOffering = offerings.getOffering(offeringId) ?? offerings.current;
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService.loadOfferings error: $e');
    }
  }

  Package? get monthlyPackage {
    final offering = _currentOffering;
    if (offering == null) return null;
    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == productMonthId ||
          package.packageType == PackageType.monthly) {
        return package;
      }
    }
    return offering.monthly;
  }

  Package? get yearlyPackage {
    final offering = _currentOffering;
    if (offering == null) return null;
    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == productYearId ||
          package.packageType == PackageType.annual) {
        return package;
      }
    }
    return offering.annual;
  }

  Future<void> _syncProToServer() async {
    try {
      await FirebaseFunctions.instance.httpsCallable('syncProEntitlement').call();
    } catch (e) {
      debugPrint('SubscriptionService._syncProToServer error: $e');
    }
  }

  Future<bool> purchase(Package package) async {
    if (!_configured) return false;
    _loading = true;
    _lastPurchaseCancelled = false;
    notifyListeners();
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      await _applyCustomerInfo(result.customerInfo);
      if (_isPro) {
        await _syncProToServer();
      }
      return _isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        _lastPurchaseCancelled = true;
        return false;
      }
      debugPrint('SubscriptionService.purchase error: $e');
      return false;
    } catch (e) {
      debugPrint('SubscriptionService.purchase error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    _loading = true;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info);
      if (_isPro) {
        await _syncProToServer();
      }
      return _isPro;
    } catch (e) {
      debugPrint('SubscriptionService.restorePurchases error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _mirrorProToFirestore() async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'subscriptionSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('SubscriptionService._mirrorProToFirestore error: $e');
    }
  }

  Future<void> _loadQuizUsageFromFirestore() async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final snap = await doc.get();
      final data = snap.data();
      if (data == null) return;

      // When RevenueCat isn't configured (e.g. Android without key),
      // fall back to server-mirrored Pro flag from the webhook.
      if (!_configured && data['isPro'] == true) {
        _isPro = true;
      }

      final usage = data['quizUsage'];
      if (usage is Map) {
        final date = usage['date']?.toString() ?? '';
        final count = (usage['count'] is int)
            ? usage['count'] as int
            : int.tryParse('${usage['count']}') ?? 0;
        if (date == _todayKey) {
          _usageDate = date;
          _quizzesUsedToday = count;
        } else {
          _usageDate = _todayKey;
          _quizzesUsedToday = 0;
        }
      } else {
        _usageDate = _todayKey;
        _quizzesUsedToday = 0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService._loadQuizUsageFromFirestore error: $e');
    }
  }

  bool get canStartQuizNow {
    if (_isPro) return true;
    if (_usageDate != _todayKey) return true;
    return _quizzesUsedToday < freeQuizzesPerDay;
  }

  /// Refresh usage and return whether the user still has quiz quota (Pro always true).
  /// Shows paywall when blocked; does not record a quiz start.
  Future<bool> ensureHasQuizQuota(BuildContext context) async {
    await _loadQuizUsageFromFirestore();
    if (_isPro || canStartQuizNow) return true;
    if (context.mounted) {
      await openPaywall(context);
    }
    // Re-check after paywall in case they subscribed.
    return _isPro || canStartQuizNow;
  }

  /// Returns true if the quiz may start. Shows paywall when blocked.
  Future<bool> ensureCanStartQuiz(BuildContext context) async {
    final hasQuota = await ensureHasQuizQuota(context);
    if (!hasQuota) return false;
    await recordQuizStart();
    return true;
  }

  Future<void> recordQuizStart() async {
    if (_isPro) return;
    final today = _todayKey;
    if (_usageDate != today) {
      _usageDate = today;
      _quizzesUsedToday = 0;
    }
    _quizzesUsedToday += 1;
    notifyListeners();

    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'quizUsage': {
          'date': _usageDate,
          'count': _quizzesUsedToday,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('SubscriptionService.recordQuizStart error: $e');
    }
  }

  Future<void> openPaywall(BuildContext context) async {
    if (_currentOffering == null) {
      await loadOfferings();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
  }
}
