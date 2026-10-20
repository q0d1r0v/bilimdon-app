import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/core/purchases/purchase_service.dart';

/// Testlar uchun do'kon: chaqiruvlarni sanaydi, xarid darhol muvaffaqiyatli
/// ([succeed] = false bo'lsa — xato holati).
class FakePurchaseService extends PurchaseService {
  FakePurchaseService(
    this.store, {
    this.available = true,
    this.priceLabel = r'$1.99',
    this.succeed = true,
    this.restorable = false,
  });

  final ProgressStore store;
  final bool succeed;

  /// [restore] chaqirilganda do'konda avvalgi xarid bormi.
  final bool restorable;

  @override
  final bool available;

  @override
  final String? priceLabel;

  @override
  UnlockStatus status = UnlockStatus.idle;

  int buyCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> buyFullUnlock() async {
    buyCalls++;
    if (succeed) {
      await store.setFullUnlocked(true);
    } else {
      status = UnlockStatus.error;
      notifyListeners();
    }
  }

  @override
  Future<bool> restore() async {
    restoreCalls++;
    if (restorable) await store.setFullUnlocked(true);
    return store.fullUnlocked;
  }
}
