/// Do'kon katalogi — sof ma'lumot. Nomlar va ikonkalar UI/l10n da
/// hal qilinadi, bu yerda faqat id/narx/slot/tur.
library;

/// Buyum turi: ferma bezagi, hayvon aksessuari yoki sarflanadigan power-up.
enum ShopItemKind { decor, accessory, powerup }

/// Bitta do'kon buyumi.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.price,
    required this.kind,
    this.slot = '',
  });

  final String id;
  final int price;

  /// ProgressStore.shopSlots dagi slot nomi (decor/accessory uchun; power-up
  /// uchun bo'sh).
  final String slot;

  final ShopItemKind kind;

  bool get isDecor => kind == ShopItemKind.decor;
  bool get isAccessory => kind == ShopItemKind.accessory;
  bool get isPowerup => kind == ShopItemKind.powerup;
}

/// To'liq katalog. Power-uplar arzon (~20–50 tanga) — bir daraja ~100 tanga.
const shopCatalog = <ShopItem>[
  // Ferma bezaklari.
  ShopItem(id: 'flowerBed', price: 100, slot: 'decor1', kind: ShopItemKind.decor),
  ShopItem(id: 'tree', price: 300, slot: 'decor2', kind: ShopItemKind.decor),
  ShopItem(id: 'hay', price: 400, slot: 'decor3', kind: ShopItemKind.decor),
  ShopItem(id: 'pond', price: 500, slot: 'decor4', kind: ShopItemKind.decor),
  // Hayvon aksessuarlari.
  ShopItem(id: 'cowHat', price: 500, slot: 'cow', kind: ShopItemKind.accessory),
  ShopItem(id: 'chickBow', price: 200, slot: 'chick', kind: ShopItemKind.accessory),
  ShopItem(id: 'pigGlasses', price: 300, slot: 'pig', kind: ShopItemKind.accessory),
  ShopItem(id: 'sheepScarf', price: 300, slot: 'sheep', kind: ShopItemKind.accessory),
  // Power-uplar (sarflanadigan).
  ShopItem(id: 'powerHeart', price: 40, kind: ShopItemKind.powerup),
  ShopItem(id: 'powerHint', price: 20, kind: ShopItemKind.powerup),
  ShopItem(id: 'powerSkip', price: 30, kind: ShopItemKind.powerup),
  ShopItem(id: 'powerCoinX2', price: 50, kind: ShopItemKind.powerup),
];

/// Katalogdan id bo'yicha buyum (topilmasa `null`).
ShopItem? shopItemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
