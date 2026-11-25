import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/constants.dart';
import 'data/local_store.dart';
import 'data/push.dart';
import 'data/storage.dart';
import 'state/connection.dart';
import 'state/events.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 번들한 글꼴의 라이선스 (SIL OFL 1.1)
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [('Inter Tight', 'OFL-InterTight.txt'), ('Noto Sans KR', 'OFL-NotoSansKR.txt')]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/fonts/$file'));
    }
  });

  // 첫 화면(/home 또는 /connect)을 정하려고 저장된 토큰을 먼저 읽는다
  final storage = AppStorage(SecureKv());
  SavedSession saved;
  int keepDays;
  try {
    saved = await storage.load();
    keepDays = await storage.loadKeepDays();
  } catch (_) {
    saved = const SavedSession(); // 키 저장소가 깨졌으면 새로 페어링
    keepDays = PhotoKeep.defaultDays;
  }

  // 폰에 보관하는 이벤트·사진 (SPEC 6장)
  LocalStore store;
  try {
    store = await SqliteLocalStore.open();
  } catch (_) {
    store = MemoryLocalStore(); // 기록은 보이되 앱을 끄면 사라진다
  }

  // 앱이 꺼져 있을 때 알림 (FCM, SPEC 9.4). android/app/google-services.json 이 없거나 실패하면 푸시 없이 돈다.
  PushMessaging push = const NoPush();
  try {
    await Firebase.initializeApp();
    push = FcmPush();
  } catch (e) {
    debugPrint('Firebase 초기화 실패, 푸시 없이 시작: $e');
  }

  runApp(ProviderScope(
    overrides: [
      pushMessagingProvider.overrideWithValue(push),
      appStorageProvider.overrideWithValue(storage),
      savedSessionProvider.overrideWithValue(saved),
      localStoreProvider.overrideWithValue(store),
      initialKeepDaysProvider.overrideWithValue(keepDays),
    ],
    child: const DoorRadarApp(),
  ));
}
