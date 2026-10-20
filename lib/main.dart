import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'content/content_repository.dart';
import 'core/audio/audio_service.dart';
import 'core/persistence/progress_store.dart';
import 'core/purchases/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final store = await ProgressStore.load();
  await AudioService.instance.init();
  // Xarita kontentini FONда (await'siz) isitamiz — splash ko'rsatilayotgan
  // paytda yuklanib bo'ladi, shuning uchun xarita ochilishida bo'sh osmon
  // kadri bo'lmaydi. await qilinmaydi — aks holda kirish splashi cho'ziladi.
  final content = ContentRepository();
  content.loadAll().then((_) {}, onError: (Object _, StackTrace _) {});
  // Do'kon faqat Android/iOS'da; init await'siz — splash kutib qolmaydi.
  final mobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final PurchaseService purchases =
      mobile ? StorePurchaseService(store) : UnavailablePurchaseService();
  unawaited(purchases.init());
  runApp(MathFarmApp(store: store, content: content, purchases: purchases));
}
