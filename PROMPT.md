# VS Code의 Claude에게 보낼 프롬프트

한 번에 다 시키면 검토하기 어려워서 4번에 나눴다. 하나 끝나면 앱을 직접 돌려 보고 다음 걸 보낸다.

---

## 1차: 세팅 + 데이터 층 + 연결 화면

```
이 폴더(door_radar_app)는 캡스톤 "도어 레이더" Flutter 앱이야. 먼저 CLAUDE.md, docs/SPEC.md, docs/DESIGN.md를 읽고, 화면 작업 전에는 해당 docs/wireframe/*.dc.html을 꼭 열어 봐.

이번에 할 일:
1. setup.ps1을 실행해서 android/ios 생성, 패키지 추가, Manifest 패치까지 끝내. 실패하면 원인을 고치고 다시 돌려. (flutter_local_notifications가 core library desugaring을 요구하면 android/app/build.gradle(.kts)에 켜 줘.)
2. 데이터 층을 만들어 줘.
   - lib/data/models/: SPEC 5장의 frame, event(목록/상세 겸용, camera에만 없는 필드는 nullable), settings, device_info, status를 freezed + json_serializable로.
   - lib/data/api/pi_api.dart: SPEC 4장 REST 전부. dio 인터셉터로 Bearer 토큰, 오류는 {"error","message"}를 PiApiException으로 바꿔서.
   - lib/data/api/live_socket.dart: /ws/live?token= 연결, frame/event 메시지를 스트림으로, 끊기면 1·2·4·8초 재시도, 다시 붙으면 콜백으로 알림.
   - lib/data/storage.dart: 토큰·마지막 기기 주소(flutter_secure_storage).
   - lib/state/connection.dart: 연결 상태(연결 안 됨 / 연결 중 / 연결됨 / 끊김-재시도 중)와 현재 기기.
3. 연결 화면(Main.dc.html)을 실제로 구현해 줘. IP 직접 입력 + 6자리 페어링 코드 → /api/info로 확인 → /api/pair → 토큰 저장 → /home. 저장된 토큰이 있으면 앱 시작 시 바로 /home으로 가도록 router redirect도. mDNS 목록은 이번엔 자리만 두고 P1에서 할게.
4. 테스트: 모델 JSON 왕복(SPEC 예시 그대로), PhotoKeep.clamp, 기존 위젯 테스트 갱신.
5. mock_server를 켜고(MOCK_PAIR_CODE=482913) Android 에뮬레이터에서 실제로 연결되는지 확인해. 에뮬레이터 주소는 10.0.2.2:8080.

끝나면 flutter analyze 경고 0, flutter test 통과 상태로, 바꾼 파일과 내가 직접 확인해야 할 것(실제 폰 테스트 등)을 짧게 정리해 줘. 명세와 다르게 해야 했던 게 있으면 따로 적어 줘.
```

---

## 2차: 홈 (실시간 지도, 이상 배너, 알림)

```
CLAUDE.md와 docs를 다시 확인하고 홈 화면을 만들어 줘. 와이어프레임은 docs/wireframe/Home.dc.html, HomeAlert.dc.html.

- lib/state/live.dart: live_socket의 frame을 받아 사람별 최근 궤적(최근 5초)과 진행 중 판정을 유지.
- lib/features/home/door_map_painter.dart: DESIGN.md "문 앞 지도" 그대로 CustomPainter로. 좌표 변환(m→px)은 순수 함수로 빼서 테스트 작성.
- 상단 칩(레이더 연결 / 카메라 정상)은 frame.radar와 /api/status로. 끊기면 칩이 바뀌고 지도 위에 "다시 연결하는 중"을 보여 줘.
- 진행 중 판정 카드: 사람이 여러 명이면 이상 상황인 사람 먼저, 그다음 가까운 사람.
- 이상 상황: notify 목록에 있는 camera 이벤트가 오면 빨간 배너(사진 보기 → 이벤트 상세, 확인 → 접기)와 flutter_local_notifications 알림(소리·진동). Android 13+ 알림 권한 요청도.
- 최근 기록 2개는 /api/events?limit=2.

mock_server를 MOCK_SPEED=5로 돌려서 통과 → 방문 → 장시간 체류 배너와 알림까지 확인하고 정리해 줘.
```

---

## 3차: 기록, 이벤트 상세, 사진 폰 보관

```
기록(Events.dc.html)과 이벤트 상세(EventDetail.dc.html), 그리고 SPEC 6장 사진 보관을 만들어 줘.

- lib/data/local_store.dart: sqflite에 이벤트 요약과 사진 파일 경로 저장, 휴대폰 보관 기간 지난 것 정리.
- lib/data/photo_sync.dart: 앱 시작 · WebSocket 재연결 · 새 camera 이벤트 때 pending → 사진·메타 받기 → 저장 성공한 것만 ack. 동시에 두 번 돌지 않게.
- 기록: 날짜별(날짜 선택 알약), 전체/이상만 세그먼트, 검은 요약 카드(오늘 전체/이상/촬영), 당겨서 새로고침. 파이에 연결이 안 돼도 폰에 저장된 이벤트는 보여 줘.
- 상세: 사진은 폰 저장본 우선, 없으면 파이에서. "이 폰에 저장됨" 표시, 오른쪽 위 버튼은 gal로 갤러리에 저장. 나온 행동 칩(이상 먼저), 근거 문장, 궤적 작은 지도.
- 판정 확인: 맞아요 → 현재 판정으로 /label, 다른 상황이에요 → 8개 중 고르는 바텀시트 → /label. 저장 후 "정답으로 저장했어요 · 되돌리기".

mock_server로 pending/ack가 제대로 줄어드는지, 앱을 껐다 켜도 사진이 남는지 확인해 줘.
```

---

## 4차: 설정, 기기 상태, 자동 찾기 (P1 마무리)

```
설정(Settings.dc.html), 기기 상태(Device.dc.html), mDNS 기기 찾기를 마무리해 줘.

- 설정: 알림 상황 3개 스위치(notify), 이상 상황 촬영(camera_on), 촬영 기준 표시(camera_prob · camera_hold_s), 바꾸면 PUT /api/settings. 실패하면 스위치를 되돌리고 스낵바.
- 휴대폰 보관 기간: 숫자 입력 7~730, 범위 밖이면 테두리·안내 문구 빨강, 포커스가 빠지면 끝값으로. 값은 앱에만 저장하고 local_store 정리에 바로 반영.
- 연결 해제: 토큰·마지막 기기 삭제 후 /connect (폰에 보관한 사진은 지우지 않음 — 확인 다이얼로그에 그렇게 적어 줘).
- 기기 상태: /api/status, /api/info, pending 개수. "레이더 다시 연결"은 일단 status를 다시 읽고, 파이 쪽 API가 생기면 바꿀 수 있게 TODO.
- 연결 화면의 "같은 Wi-Fi에서 찾은 기기": nsd로 _doorradar._tcp 찾아 목록. 못 찾으면 IP 입력 안내.
- 글꼴: Inter Tight + Noto Sans KR을 assets/fonts에 넣고 theme에 적용(라이선스 파일 포함).

mock_server는 mDNS를 안 알리니, 찾기는 "못 찾으면 IP 입력"으로 동작 확인만 하고, 실제 파이에서 시험할 체크리스트를 남겨 줘.
```
