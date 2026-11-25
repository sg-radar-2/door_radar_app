# Door Radar 앱 — 작업 규칙

현관 레이더 + 라즈베리파이(이하 파이)가 내린 행동 판정을 보여주는 Flutter 앱이다. 1차 목표는 Android 폰.
앱은 **클라우드(`rad2-cloud`)를 통해서만** 파이와 통신한다(SPEC 9장). 집 Wi-Fi 직접 연결(IP 입력, mDNS)은 없다.
판정·촬영은 파이가 하고, 앱은 보여주기·설정·알림·사진 보관만 한다.

## 먼저 읽을 것

1. `docs/SPEC.md` — 화면, 우선순위(P0/P1/P2), 파이 API(클라우드가 그대로 제공), JSON 형식, 사진 보관 규칙, 클라우드 연결(9장). **계약의 기준.**
2. `docs/DESIGN.md` — 디자인 원칙과 토큰, 문 앞 지도 그리는 법.
3. `docs/wireframe/*.dc.html` — 화면별 와이어프레임(390×844). 인라인 스타일 값이 기준이다. 디자인 도구 전용 태그(`<x-dc>`, `<sc-for>`, `<sc-if>`, `{{…}}`)는 무시한다.

## 개발 환경

- Windows + PowerShell. 명령은 PowerShell 기준으로 쓴다(`;`로 잇기, 경로 `\`).
- 처음이면 `powershell -ExecutionPolicy Bypass -File .\setup.ps1` (flutter create, 패키지 추가, Manifest 패치).
- 클라우드·파이 없이 개발할 때는 `mock_server/`의 가짜 클라우드를 쓴다. 앱이 붙는 주소는 빌드 설정 `--dart-define=CLOUD_URL=...`이고, 안 주면 실제 클라우드 `https://rad2-cloud.onrender.com`. 목 서버는 에뮬레이터 `CLOUD_URL=http://10.0.2.2:8080`, 실제 폰 `CLOUD_URL=http://<PC IP>:8080`.
- 끝내기 전에 `flutter analyze`(경고 0)와 `flutter test`를 통과시킨다.

## 스택 (바꾸지 않는다)

- 상태: `flutter_riverpod` (Notifier / AsyncNotifier. riverpod_generator는 쓰지 않는다)
- 라우팅: `go_router` — `lib/app/router.dart`의 경로와 탭 3개 구조 유지
- 통신: `dio`(REST, 토큰 인터셉터), `web_socket_channel`(`/ws/live`)
- 모델: `freezed` + `json_serializable` (`*.freezed.dart`, `*.g.dart`는 커밋)
- 저장: `flutter_secure_storage`(토큰·파이 이름), `sqflite` + `path_provider`(폰에 보관하는 이벤트·사진), `gal`(갤러리 저장)
- 알림: `flutter_local_notifications`
- 사진: `cached_network_image` (클라우드에서 받을 때 토큰 헤더 포함)

새 패키지가 꼭 필요하면 `flutter pub add`로 넣고, 왜 필요한지 README의 폴더/패키지 설명에 한 줄 남긴다.

## 지킬 것

- **API 계약**: 경로·필드 이름은 `docs/SPEC.md` 그대로. 클라우드는 파이 API를 바꾸지 않고 더하기만 한다(9.1). 계약을 바꿔야 하면 `docs/SPEC.md`와 `mock_server/server.py`를 같은 변경에서 함께 고치고, 파이·클라우드 담당에게 알릴 내용을 작업 요약에 적는다.
- **상황 이름**은 한국어 문자열 그대로(`통과 귀가 외출 방문 배달 / 장시간 체류 배회 반복 접근 / 판단 중`). enum으로 감싸도 JSON 값은 그대로. 목록은 `lib/app/constants.dart`.
- **색**: 반드시 `AppColors`로. `alert`(빨강)는 이상 상황에만, `point`(라임)는 실시간 표시에만. 그림자·그라데이션·장식 겹치기 금지(DESIGN.md 원칙).
- **사진 보관**: 휴대폰 보관 기간(기본 300일, 7~730일)은 앱에만 저장한다. 파이는 `device_keep_days`(30), 클라우드는 모든 폰이 받으면 지우고 길어야 7일(SPEC 9.2). 동기화 순서는 SPEC 6장.
- **연결**: WebSocket 끊김은 1·2·4·8초 재시도, 다시 붙으면 `/api/events?since=`로 빈 기간을 채운다. 연결 상태와 파이 꺼짐(`pi: "offline"`)은 홈 상단 칩과 기기 상태 화면에 보인다.
- **UI 문구**는 한국어, 와이어프레임 문구를 그대로 쓴다. 코드 식별자는 영어, 주석은 한국어 가능.
- `docs/wireframe/`은 참고용 사본이라 사람이 요청할 때만 고친다(2026-11-25 클라우드 전환으로 `Main`·`Device` 수정). 디자인이 바뀌면 사람이 새 사본을 넣는다.
- 레이더/파이/클라우드 쪽 코드(레이더·클라우드 `..\sg-radar-tools`(`tools/cloud_backend`), 파이 서버 `..\pi_server`)는 이 작업에서 건드리지 않는다. 계약 확인용으로 읽는 것은 괜찮다.

## 구조

```
lib/app/        app.dart, router.dart, theme.dart(토큰), constants.dart
lib/data/       models/, api/pi_api.dart, api/live_socket.dart, notifications.dart,
                storage.dart, local_store.dart, photo_sync.dart
lib/state/      connection.dart, live.dart, events.dart, settings.dart
lib/features/   connect/, home/(door_map_painter.dart), events/, settings/
lib/widgets/    공통 위젯 (app_shell.dart, situation_chip.dart, photo_view.dart …)
test/           모델 JSON 왕복, 보관 기간 clamp, 지도 좌표 변환, 위젯 스모크
```
