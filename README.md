# Door Radar 앱

현관 레이더(RETINA-4SN)와 라즈베리파이가 내린 판정을 보여주는 Flutter 앱. 시연은 같은 공유기 Wi-Fi 안의 Android 폰.

- 명세: [`docs/SPEC.md`](docs/SPEC.md) (팀 문서 「도어 레이더 앱 구현 문서 (Flutter)」에서 옮김)
- 디자인: [`docs/DESIGN.md`](docs/DESIGN.md), 화면별 와이어프레임 [`docs/wireframe/`](docs/wireframe/)
- 가짜 파이 서버: [`mock_server/`](mock_server/) (레이더·파이 없이 앱 개발)
- 정답 → 재학습 → 모델 배포, 푸시 알림 계획: [`docs/TRAINING_PIPELINE.md`](docs/TRAINING_PIPELINE.md)
- Claude 작업 규칙: [`CLAUDE.md`](CLAUDE.md)

## 처음 한 번

필요한 것: Flutter SDK 3.47 이상(`material_ui` 때문. 팀은 3.50), Android Studio(SDK·에뮬레이터) 또는 USB 디버깅 켠 Android 폰, Python 3.10 이상.

Flutter를 여러 개 깔았으면 PATH 맨 앞의 것이 불린다. `(Get-Command flutter).Source`와 `flutter --version`으로 확인한다(옛 SDK가 불리면 `flutter run`이 멈춘 듯 보인다).

```powershell
cd C:\Users\HGray\Desktop\SG\4th\Capstone\door_radar_app
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

`setup.ps1`이 하는 일: `flutter create`로 android/ios 폴더 생성(이미 있는 `lib/` 등은 그대로), 패키지 추가, AndroidManifest에 http 허용·권한 추가, `flutter analyze`·`flutter test`.

## 가짜 파이 서버

```powershell
cd mock_server
py -3.11 -m venv .venv          # Windows용 Python. MSYS2 python 은 venv 가 bin\ 에 생기고 pydantic 설치가 느리다
.venv\Scripts\activate
pip install -r requirements.txt
$env:MOCK_PAIR_CODE="482913"   # 안 정하면 실행할 때마다 새 코드가 출력됨
python server.py
```

두 번째부터는 설치 없이 `cd mock_server; $env:MOCK_PAIR_CODE="482913"; .\.venv\Scripts\python.exe server.py` 한 줄이면 된다(activate 불필요). 끌 때는 `Ctrl+C`. 이미 켜 둔 서버가 있으면 8080 포트가 겹쳐 시작하지 못한다.

- 주소: 에뮬레이터는 `10.0.2.2:8080`, 실제 폰은 PC와 같은 Wi-Fi에서 `<PC IP>:8080` (서버가 시작할 때 출력).
- 실제 폰에서 안 붙으면 Windows 방화벽에서 Python의 8080 포트(개인 네트워크)를 허용한다.
- 실시간 대본은 통과 → 방문 → 장시간 체류(15초 머무르면 이상, 1초 뒤 촬영 이벤트)를 반복한다. 최종 판정은 실제 파이처럼 사람이 사라지고 3초 뒤에 온다. `$env:MOCK_SPEED="10"`이면 10배 빨리 돈다.
- 이벤트·사진은 메모리에만 있어서 서버를 끄면 처음 상태(오늘 이벤트 6개)로 돌아간다. 토큰과 다음 이벤트 번호는 실제 파이처럼 `mock_server/mock_state.json`에 남아서 다시 켜도 앱은 그대로 붙는다(다시 페어링하려면 이 파일을 지운다). 번호를 이어 매기므로 다시 켤 때마다 오늘치 6개가 새 번호로 폰 기록에 더해진다.
- 서버를 켠 채로 앱 데이터 층 통합 테스트: `$env:DOOR_RADAR_MOCK="127.0.0.1:8080"; flutter test test/mock_server_test.dart` (변수가 없으면 건너뜀)

## 실행

```powershell
flutter emulators --launch door_radar   # 에뮬레이터가 꺼져 있으면 (켜지다 꺼지면 emulator.exe -avd door_radar -gpu swiftshader_indirect)
flutter devices                         # 폰이 "not authorized"면 폰 화면의 USB 디버깅 허용 창을 누른다
flutter run                             # 기기가 여럿이면 -d emulator-5554 / -d <폰 id>
```

- 켜 둔 채 코드를 고치면 터미널에서 `r`(화면만 갱신) 또는 `R`(앱 처음부터). 앱 아이콘으로 직접 켜면 마지막에 설치된 빌드가 뜬다.
- 앱이 화면에서 사라지면(홈 버튼, 다른 앱) 실시간 연결을 끊고, 돌아오면 다시 붙어 빈 기간을 채운다(배터리). 그래서 **앱을 안 보고 있을 때는 이상 상황 알림이 오지 않는다.** 푸시 알림은 `docs/TRAINING_PIPELINE.md` TODO 5.

모델(freezed/json_serializable)을 고치면 코드를 다시 생성한다(`*.freezed.dart`, `*.g.dart` 는 커밋):

```powershell
dart run build_runner watch --delete-conflicting-outputs
```

## 폴더

```
lib/
  main.dart
  app/        app.dart, router.dart(go_router, 탭 3개), theme.dart(디자인 토큰), constants.dart
  data/       models/(freezed), api/pi_api.dart(REST), api/live_socket.dart(/ws/live), storage.dart(토큰·마지막 기기)
              notifications.dart(이상 상황 알림, flutter_local_notifications)
              local_store.dart(폰 보관: sqflite + photos/{id}.jpg), photo_sync.dart(pending → 받기 → ack)
              discovery.dart(mDNS _doorradar._tcp, nsd)
  state/      connection.dart(연결 상태·현재 기기·연결 해제·백그라운드에서 끊기), live.dart(사람별 5초 궤적·/api/status),
              events.dart(최근 기록·이상 배너·폰 보관 동기화·기록/상세), settings.dart(/api/settings 읽기·바꾸기)
  features/   connect/(자동 찾기 + IP), home/(door_map_painter.dart), events/(기록·상세·지나간 길 재생), settings/(설정·기기 상태)
  widgets/    app_shell.dart(하단 탭), pill_switch.dart, situation_chip.dart
assets/fonts/ Inter Tight(400·500·600·700) + Noto Sans KR(400·500·700), OFL-*.txt (앱 '라이선스'에도 등록)
mock_server/  server.py (FastAPI), requirements.txt, mock_state.json(토큰·다음 이벤트 번호, git 제외)
docs/         SPEC.md, DESIGN.md, TRAINING_PIPELINE.md, wireframe/
```

## 실제 파이에서 확인할 것

목 서버는 mDNS를 알리지 않아서 자동 찾기는 "못 찾으면 IP 입력"까지만 확인했다. 실제 파이(`../pi_server`)와 Android 폰으로:

- [ ] 폰과 파이가 같은 공유기 Wi-Fi(게스트망·AP 격리 끔)에 있다
- [ ] 연결 화면 "같은 Wi-Fi에서 찾은 기기"에 `rad2pi.local`(또는 파이 이름)과 IP가 6초 안에 뜬다
- [ ] 카드를 누르면 IP 칸이 채워지고, 파이 화면/로그의 6자리 코드로 연결된다
- [ ] 안 뜨면: 파이 `config.toml`의 `mdns.enabled`, `avahi-browse -rt _doorradar._tcp`(파이·PC)로 광고 확인. 그래도 안 되면 IP 직접 입력
- [ ] 홈: 사람이 지나가면 1초 안에 점이 움직이고 판정이 바뀐다. 레이더 케이블을 빼면 칩이 "레이더 끊김/응답 없음"
- [ ] 파이 전원이나 Wi-Fi를 끊으면 2초쯤 뒤 "다시 연결하는 중", 다시 켜면 붙고 그동안의 기록이 채워진다
- [ ] 앱을 홈 버튼으로 내렸다가 다시 열면 잠깐 "연결 중" 뒤 다시 붙는다
- [ ] 카메라 없는 파이면 칩이 "카메라 없음"(`camera: none`)
- [ ] 기기 상태: 레이더 주소(`radar_host`)·카메라(`camera_backend`)·전송 대기 사진(`pending_photos`)이 보인다
- [ ] "레이더 다시 연결"(`POST /api/radar/reconnect`) 뒤 상태가 연결됨으로 돌아온다
- [ ] 설정: 알림 스위치·이상 상황 촬영을 바꾸면 파이 `/api/settings`에 반영되고, 다음 판정부터 적용된다
- [ ] 앱을 화면에 띄운 채 장시간 체류(15초 이상 머물기)에서 빨간 배너 + 소리·진동 알림, 사진이 폰에 저장된다(기록 → 상세 "이 폰에 저장됨")
- [ ] 상세 "지나간 길": ▶ 또는 지도를 누르면 실제 걸린 시간대로 재생, 1×·2×·4× 배속
- [ ] 정답 표시 후 파이 DB의 이벤트 `label`에 남는다(다시 열거나 `GET /api/events/{id}`로 확인). "되돌리기"는 파이가 `{"situation": null}`을 받아야 동작(아직 400이면 안내만 뜸)
- [ ] 갤러리 저장 후 사진 앱에 `doorradar_{id}`가 보인다
- [ ] 설정 → 연결 해제 → 연결 화면(입력칸 비어 있음), 기록 탭의 사진은 다시 연결해도 남아 있다

## 패키지 메모

- 글꼴은 패키지가 아니라 `assets/fonts`에 직접 넣었다(오프라인 시연). Google Fonts 정적 TTF, SIL OFL 1.1.
- `sqflite_common_ffi` (dev): `test/local_store_test.dart`에서 sqlite 저장소를 PC에서 돌려 보려고. 위젯 테스트는 `MemoryLocalStore`를 쓴다.
- `nsd`: 빌드할 때 "plugins that apply Kotlin Gradle Plugin (KGP): nsd_android" 경고가 나온다. 지금은 동작에 영향이 없고, 나중에 Flutter를 올릴 때 `nsd`도 새 버전으로 올린다.
- `material_ui`: Flutter 3.47부터 `package:flutter/material.dart` 가 deprecated 되고 Material 위젯이 이 패키지로 옮겨졌다. go_router·riverpod·cached_network_image 도 이미 이걸 쓰므로 `import 'package:material_ui/material_ui.dart'` 로 통일한다.
