import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../persistence/progress_store.dart';

/// Xarid jarayoni holati (UI uchun).
enum UnlockStatus { idle, busy, pending, error }

/// «To'liq versiya» xaridi. UI faqat shu interfeysni ko'radi — testlarda
/// soxta servis beriladi, qo'llab-quvvatlanmaydigan platformada
/// [UnavailablePurchaseService].
abstract class PurchaseService extends ChangeNotifier {
  /// Google Play / App Store'dagi mahsulot idsi (ikkalasida bir xil).
  static const fullUnlockId = 'full_unlock';

  /// Do'kon ulangan va mahsulot topilgan — sotib olish mumkin.
  bool get available;

  /// Do'kon qaytargan mahalliy narx (masalan «25 900 so'm»); topilmasa `null`.
  String? get priceLabel;

  UnlockStatus get status;

  Future<void> init();

  /// To'lov oynasini ochadi. Natija keyin [ProgressStore.setFullUnlocked]
  /// orqali keladi.
  Future<void> buyFullUnlock();

  /// Avvalgi xaridlarni tiklaydi; tugagach to'liq versiya ochiqmi — qaytaradi.
  Future<bool> restore();
}

/// Do'kon yo'q (veb, desktop, testlar) — hech narsa sotilmaydi.
class UnavailablePurchaseService extends PurchaseService {
  @override
  bool get available => false;

  @override
  String? get priceLabel => null;

  @override
  UnlockStatus get status => UnlockStatus.idle;

  @override
  Future<void> init() async {}

  @override
  Future<void> buyFullUnlock() async {}

  @override
  Future<bool> restore() async => false;
}

/// Haqiqiy servis: `in_app_purchase` (Android — Play Billing, iOS — StoreKit).
///
/// Xarid holati serverda tekshirilmaydi — ProgressStore'dagi bayroq mahalliy
/// kesh, har ishga tushishda [init] uni do'kondan jim tiklaydi.
class StorePurchaseService extends PurchaseService {
  StorePurchaseService(this._store, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final ProgressStore _store;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _storeAvailable = false;
  ProductDetails? _product;
  UnlockStatus _status = UnlockStatus.idle;

  @override
  bool get available => _storeAvailable && _product != null;

  @override
  String? get priceLabel => _product?.price;

  @override
  UnlockStatus get status => _status;

  @override
  Future<void> init() async {
    // Obuna birinchi: ilova yopiq paytda tugagan xaridlar ham shu oqimga
    // keladi va yakunlanmasa Play ularni 3 kundan keyin qaytaradi.
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) => _setStatus(UnlockStatus.error),
    );
    try {
      _storeAvailable = await _iap.isAvailable();
      if (!_storeAvailable) {
        notifyListeners();
        return;
      }
      final res =
          await _iap.queryProductDetails({PurchaseService.fullUnlockId});
      for (final p in res.productDetails) {
        if (p.id == PurchaseService.fullUnlockId) _product = p;
      }
      notifyListeners();
      // Qayta o'rnatish / yangi qurilma — xarid jim tiklanadi.
      await _iap.restorePurchases();
    } on Exception catch (e, st) {
      debugPrint('IAP init xatosi: $e\n$st');
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID == PurchaseService.fullUnlockId) {
        switch (p.status) {
          case PurchaseStatus.pending:
            _status = UnlockStatus.pending;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _store.setFullUnlocked(true);
            _status = UnlockStatus.idle;
          case PurchaseStatus.error:
            _status = UnlockStatus.error;
          case PurchaseStatus.canceled:
            _status = UnlockStatus.idle;
        }
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  @override
  Future<void> buyFullUnlock() async {
    final product = _product;
    if (product == null || _store.fullUnlocked) return;
    _setStatus(UnlockStatus.busy);
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) _setStatus(UnlockStatus.error);
    } on Exception catch (e) {
      debugPrint('IAP xarid xatosi: $e');
      _setStatus(UnlockStatus.error);
    }
  }

  @override
  Future<bool> restore() async {
    if (!_storeAvailable) return _store.fullUnlocked;
    _setStatus(UnlockStatus.busy);
    final done = Completer<void>();
    void check() {
      if (_store.fullUnlocked && !done.isCompleted) done.complete();
    }

    _store.addListener(check);
    check();
    try {
      await _iap.restorePurchases();
      // Natija purchaseStream orqali keladi; xarid bo'lmasa hech narsa
      // kelmaydi — shuning uchun qisqa kutamiz.
      await done.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    } on Exception catch (e) {
      debugPrint('IAP tiklash xatosi: $e');
    } finally {
      _store.removeListener(check);
    }
    if (_status == UnlockStatus.busy) _setStatus(UnlockStatus.idle);
    return _store.fullUnlocked;
  }

  void _setStatus(UnlockStatus s) {
    if (s == _status) return;
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
