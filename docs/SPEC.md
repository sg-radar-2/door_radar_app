# 도어 레이더 앱 명세

원본은 팀 문서 「도어 레이더 앱 구현 문서 (Flutter)」(claude.ai)다. 여기에는 앱 구현에 필요한 부분만 옮겼다.
원본과 다르면 원본을 따르고 이 파일을 고친다. 이 파일을 고쳤으면 `mock_server/server.py`도 같이 맞춘다.

## 1. 범위

- 앱은 라즈베리파이(이하 파이)가 내린 판정을 보여주고 설정을 바꾼다. 행동 판정과 촬영은 모두 파이가 한다.
- 앱은 **클라우드를 통해서만** 파이와 통신한다(9장). 폰과 파이가 같은 Wi-Fi에 있을 필요가 없고, 둘 다 인터넷에 연결돼 있으면 된다.
- 앱이 하는 일: 페어링 코드로 연결, 문 앞 실시간 상태, 이벤트 기록과 사진, 이상 상황 알림, 설정 변경, 판정에 정답 표시, 사진을 폰에 보관.
- 앱이 하지 않는 일: 레이더 데이터 직접 받기, 행동 판정, 카메라 제어, 모델 학습.
- 범위 밖: 여러 집·여러 기기 관리, 계정·로그인. (푸시 알림은 9.4)
- 플랫폼: Flutter로 Android·iOS 모두 고려하되 시연과 1차 개발은 Android.

## 2. 화면 (탭 3개: 홈 · 기록 · 설정)

| 화면 | 경로 | 와이어프레임 | 보여주는 것 | 하는 일 |
| --- | --- | --- | --- | --- |
| 연결 | `/connect` | `Main.dc.html` | 6자리 페어링 코드 | 클라우드 `/api/pair` → 토큰으로 `/api/info` → 토큰 저장 → 홈 |
| 홈 | `/home` | `Home.dc.html`, `HomeAlert.dc.html` | 위에서 본 문 앞 지도(측정 영역, 사람 점과 궤적), 인원, 사람별 진행 중 판정·확률, 레이더·카메라 상태, 최근 기록 2개 | 이상 상황이면 빨간 배너 + 알림. 배너 → 이벤트 상세 |
| 기록 | `/events` | `Events.dc.html` | 날짜별 이벤트: 시각, 최종 판정, 확률, 이상 여부, 사진 썸네일, 오늘 요약(전체/이상/촬영) | 전체/이상만 필터, 날짜 이동, 당겨서 새로고침 |
| 이벤트 상세 | `/events/:id` | `EventDetail.dc.html` | 사진(폰에 저장된 것 우선), 궤적, 나온 행동(이상 먼저), 끝날 때 판정, 근거 문장, 머문 시간, "이 폰에 저장됨" | 정답 표시(맞아요 / 다른 상황 고르기), 갤러리에 저장 |
| 설정 | `/settings` | `Settings.dc.html` | 알림 받을 상황 3개 스위치, 이상 상황 촬영, 촬영 기준(확률·유지 시간), 휴대폰 보관 기간(7~730일) | 파이 설정은 `PUT /api/settings`, 휴대폰 보관 기간은 앱에만 저장 |
| 기기 상태 | `/settings/device` | `Device.dc.html` | 파이 이름·서버 버전·클라우드 연결(파이 꺼짐), 레이더 연결·프레임 수신율, 카메라, 모델 이름·버전, 파이 저장 공간·전송 대기 사진 수 | 레이더 다시 연결 시도, 다른 기기 연결(→ `/connect`) |

문 앞 지도 좌표계는 PC 뷰어(`situation_viewer.pyw`)의 "위에서 본 모습"과 같다. 레이더(문)가 아래 가운데, x는 좌우(m), y는 문에서 멀어지는 방향(m).

## 3. 우선순위

| 우선 | 기능 | 끝난 기준 |
| --- | --- | --- |
| P0 | 페어링 코드로 클라우드 연결, 토큰 기억 | 앱을 다시 켜도 자동으로 연결됨 |
| P0 | 홈 실시간 지도와 진행 중 판정 | 사람이 지나갈 때 1초 안에 점이 움직이고 판정 글자가 바뀜 |
| P0 | 이상 상황 알림 (앱이 켜져 있을 때) | 장시간 체류·배회·반복 접근에서 배너와 소리·진동, 정상 상황은 알림 없음 |
| P0 | 이벤트 목록·상세, 사진 보기 | 촬영된 사진이 이벤트와 함께 나옴 (밤에는 적외선 흑백) |
| P1 | 판정에 정답 표시 | 정답이 파이에 저장되고 CSV로 내보낼 수 있음 |
| P1 | 설정 화면 | 바꾼 값이 다음 판정부터 적용됨, 휴대폰 보관 기본 300일(7~730일) |
| P1 | 사진을 폰으로 받아 보관, 갤러리에 저장 | 앱을 열면 클라우드에서 안 받은 사진을 받아 오고, 보관 기간이 지난 사진은 앱이 지움 |
| P1 | 기기 상태 화면 | 레이더가 끊기면 홈과 상태 화면에 표시, 남은 저장 공간 표시 |
| P2 | 반복 발생 알림 (n회 이상일 때만) | 상황별 n과 기간을 설정에서 정함 |
| P1 | 앱이 꺼져 있을 때 알림 (FCM 푸시, 9.4) | 앱을 꺼 둬도 이상 상황 알림이 오고, 누르면 상세 |
| P2 | 이벤트 전후 몇 초 영상(사진과 같은 방식으로 폰에 보관), 실시간 카메라 | - |
| P2 | 측정 영역을 앱에서 수정, iOS 빌드 | - |

앱을 다시 켜면 놓친 이벤트를 `/api/events?since=`로 받아온다. 반복 발생 알림(P2)의 판단은 파이가 하고, 앱은 `notify` 설정과 알림 표시만 맡는다.

## 4. 파이 API

앱은 이 API를 **클라우드 주소**(`--dart-define=CLOUD_URL`)로 부른다. 클라우드가 경로·필드를 그대로 제공하고, 9.1의 것만 더한다.
파이 자체의 주소는 `http://<파이IP>:8080`(파이 담당·클라우드가 쓴다). 레이더 관리 페이지(8000)와 데이터 포트(29172)는 레이더 쪽이라 앱이 쓰지 않는다.

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| GET | `/api/info` | 기기 이름, 버전, 측정 영역, 모델 이름 (연결 확인용, 인증 없음) |
| POST | `/api/pair` | `{"code": "482913"}` → `{"token": "..."}` (인증 없음) |
| GET | `/api/status` | 레이더·카메라 연결, 프레임 수신율, 저장 공간 |
| GET | `/api/events?since=&limit=&abnormal=` | 이벤트 목록 (최신순). `since`는 ISO 시각, 그 이후(`t` 기준)만 |
| GET | `/api/events/{id}` | 이벤트 상세 (`track`, `behaviors` 포함) |
| GET | `/api/events/{id}/photo` | 촬영 사진 JPEG, `?thumb=1`이면 썸네일 |
| GET | `/api/photos/pending` | 이 폰(토큰)이 아직 안 받은 사진의 이벤트 id 목록 `{"ids": [...]}` |
| POST | `/api/photos/ack` | 받은 사진 알리기 `{"ids": [128, 131]}` |
| POST | `/api/events/{id}/label` | 정답 표시 `{"situation": "배달"}`, `{"situation": null}`이면 정답 지우기(앱의 "되돌리기"). 응답은 바뀐 이벤트 요약 |
| GET / PUT | `/api/settings` | 설정 읽기 / 바꾸기 (바꿀 키만 보내도 됨) |
| WS | `/ws/live?token=` | 실시간 프레임(초당 5번)과 새 이벤트 알림 |

- **인증**: `/api/info`, `/api/pair` 외에는 `Authorization: Bearer <토큰>`. WebSocket은 `?token=`. 토큰이 틀리면 REST는 401, WebSocket은 핸드셰이크 거절.
- **기기 찾기**: 앱은 하지 않는다(클라우드가 페어링 코드로 파이를 찾는다). 파이 자체는 mDNS `_doorradar._tcp`(이름 `doorradar`), 호스트 `rad2pi.local`.
- **끊기면**: WebSocket을 1, 2, 4, 8초(이후 8초 반복) 간격으로 다시 연결하고, 붙으면 마지막으로 받은 이벤트의 `t` 이후를 `/api/events?since=`로 채운다.
- **오류 형식**: `{"error": "<코드>", "message": "<설명>"}` (401 토큰 없음·틀림, 404 없는 이벤트·사진, 400 잘못된 값). 레이더가 끊겨도 API는 오류를 내지 않고 `/api/status`·프레임의 `radar`로만 알린다.
- **토큰**: 파이 DB에 남아 서버를 다시 켜도 유효하다. 폰마다 따로이고 사진 ack도 토큰별.
- **`/api/events`**: `limit` 1~500(기본 50). `since`에 시간대가 없으면 한국 시간. 앱은 `+`를 `%2B`로 인코딩해 보낸다.
- **WebSocket**: 붙자마자 프레임 하나, 이후 사람이 없어도 초당 5번. 앱은 2초 넘게 아무것도 안 오면 끊긴 것으로 보고 다시 붙는다. `final`은 사람이 사라지고 3초 뒤에 온다.

## 5. 데이터 형식

시각은 ISO 8601 문자열(한국 시간 `+09:00`), 위치는 레이더 기준 미터.
상황 이름은 `situation_core` 이름 그대로: 정상 `통과 귀가 외출 방문 배달`, 이상 `장시간 체류 배회 반복 접근`, 그리고 `판단 중`.

**실시간 프레임** (`/ws/live`, 초당 5번. 사람이 없으면 `people: []`)

```json
{
  "type": "frame",
  "t": "2026-11-19T15:02:31.400+09:00",
  "people": [
    {"id": "T3+7", "x": 0.42, "y": 1.35, "hidden": false,
     "situation": "방문", "prob": 0.82, "abnormal": false,
     "still_s": 6.5, "elapsed_s": 14.2}
  ],
  "radar": "ok"
}
```

`id`는 문자열이다. 레이더가 같은 사람에게 준 여러 타깃 id를 서버가 하나로 묶으면 `T3+7`처럼 온다.

**새 이벤트 알림** (같은 WebSocket. 촬영했을 때와 최종 판정이 나왔을 때)

```json
{"type": "event", "event": {"id": 128, "kind": "camera", "person": "T3+7", "situation": "장시간 체류", "prob": 1.0, "abnormal": true, "photo": true, "t": "2026-11-19T15:03:10+09:00", "started_at": "...", "ended_at": null, "label": null}}
```

**이벤트** (`/api/events/{id}`. 목록은 `track`, `behaviors`를 뺀 것)

```json
{
  "id": 128,
  "kind": "final",
  "person": "T3+7",
  "t": "2026-11-19T15:03:40+09:00",
  "started_at": "2026-11-19T15:02:17+09:00",
  "ended_at": "2026-11-19T15:03:40+09:00",
  "situation": "장시간 체류",
  "prob": 1.0,
  "abnormal": true,
  "end_situation": "방문",
  "behaviors": [
    {"situation": "장시간 체류", "prob": 1.0, "source": "progress"},
    {"situation": "방문", "prob": 0.94, "source": "end"}
  ],
  "reason": "이상 행동 우선: 진행 중 장시간 체류 100% → 끝날 때 판정 방문 94% 대신",
  "path": "외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)",
  "photo": true,
  "label": null,
  "track": [[0.0, 1.71, 1.66], [0.2, 1.65, 1.61]]
}
```

- `kind`: `camera`(진행 중 이상 상황으로 촬영, `ended_at`·`end_situation`·`reason`·`path`·`track` 없음) 또는 `final`(사람이 사라져서 나온 최종 판정)
- `t`: 이벤트가 생긴 시각(camera는 촬영 시각, final은 `ended_at`). 정렬과 `since` 기준
- `track`: `[시작부터 초, x, y]`, 0.2초 간격
- `label`: 앱에서 표시한 정답 (없으면 `null`)
- 모델로 만들 때 `camera`에만 없는 필드는 nullable 로 둔다.

**설정** (`/api/settings`)

```json
{
  "notify": ["장시간 체류", "배회", "반복 접근"],
  "camera_on": true,
  "camera_prob": 0.6,
  "camera_hold_s": 1.0,
  "region": {"xmin": -2, "xmax": 2, "ymin": 0, "ymax": 3, "fov_deg": 135},
  "device_keep_days": 30
}
```

- `region`, `device_keep_days`는 읽기 전용(보내도 무시).
- `notify`는 이상 3가지 중에서만. 목록에 있는 상황은 1회만 나와도 알린다. P2에서 `{"situation": "배회", "min_count": 3, "within_min": 60}` 목록으로 넓힌다.

## 6. 사진 보관 (폰이 장기, 파이는 임시)

- 휴대폰 보관 기간은 **앱에만** 저장한다. 기본 300일, 7~730일. 범위 밖 값은 가까운 끝값으로 맞춘다.
- 파이는 사진을 30일(`device_keep_days`) 임시 보관한다. 폰이 받았다고 알려도 30일 동안은 남겨서 다른 폰도 받을 수 있다.
- 동기화: 앱을 켤 때, WebSocket이 다시 붙을 때, 새 `camera` 이벤트가 올 때
  1. `GET /api/photos/pending` → id 목록
  2. 각 id를 `GET /api/events/{id}`(메타) + `/photo`(원본)로 받아 앱 저장소(파일 + sqflite)에 저장
  3. 저장이 끝난 id만 `POST /api/photos/ack`
- 앱은 켤 때마다 휴대폰 보관 기간이 지난 사진과 이벤트를 지운다. 갤러리에 저장한 사진은 앱을 지워도 남는다.
- 30일 넘게 연결하지 않은 폰은 그 기간 사진을 받지 못한다(파이에서 지워짐).
- 화면에서는 폰에 있는 사진을 먼저 보여주고, 없으면 파이에서 받아 보여준다.
- 지금은 사진만. 나중에 이벤트 전후 영상(P2)도 같은 방식으로 받는다.

## 7. 알림 규칙

- **지금(P0)**: `notify` 목록에 있는 이상 상황의 `camera` 이벤트가 오면 1회만 나와도 알린다(배너 + 소리·진동). 정상 상황은 알림 없음.
- **P2 추천 기본값** (와이어프레임 문구가 이 기준): 반복 접근은 바로, 장시간 체류·배회는 "머무름"으로 묶어 30분 안에 2번째부터, 같은 사람은 10분에 한 번까지. 판단은 파이가 하고 앱은 표시만 한다.

## 8. 실제 파이 서버 (`../pi_server`)에서 정해진 것

- 파이 호스트 이름은 `rad2pi` → 주소 `rad2pi.local:8080`. mDNS 서비스 이름은 `doorradar` (`_doorradar._tcp`).
- **최종 판정 갱신**: 같은 사람이 사라졌다가 다시 이어 붙으면(외곽으로 나갔다 30초 안에 다시 들어옴 등) 같은 `id`의 `final` 이벤트가 WebSocket으로 다시 온다. 앱은 `id` 기준으로 덮어쓴다(목록·폰 저장소 모두).
- `POST /api/radar/reconnect` → `{"radar": "connecting"}`: 기기 상태 화면의 "레이더 다시 연결".
- `/api/status` 추가 필드: `radar_host`, `radar_error`, `camera_backend`(`helper`·`rpicam`·`fake`·`none`), `judge_error`, `pending_photos`. `radar`는 `ok | connecting | disconnected | stale`(2초 넘게 프레임 없음), `camera`는 `ok | error | none`, `cpu_temp_c`는 없을 수 있음(null).
- 실시간 프레임의 사람 `id`(`T3+7`)의 숫자는 레이더 ID가 아니라 서버가 매긴 등장 번호다. 판정에 아직 안 들어간 새 사람도 `판단 중`으로 온다.
- `final` 이벤트에 `also`(같은 확률로 동점인 다른 이상 행동 목록, 보통 빈 배열)가 있다.
- `final`의 `photo`는 같은 사람의 첫 `camera` 사진을 가리키고, pending에는 둘 다 나온다. 앱은 같은 사람(`started_at`)의 camera 사진이 이미 폰에 있으면 final 사진은 다시 받지 않고 ack만 한다.

## 9. 클라우드 연결 (2026-11-25 결정)

앱은 **파이에 직접 붙지 않고 클라우드(`rad2-cloud`, Render + PostgreSQL)를 통해서만** 통신한다. 집 Wi-Fi 직접 연결(IP 입력, mDNS 찾기)은 없앤다.
클라우드는 **파이 API(4·5·8장)를 경로·필드 그대로** 앱에 제공한다. 그래서 앱의 화면·모델·동기화 코드는 그대로 쓰고, 주소와 연결 화면만 바뀐다.

```
폰 ──HTTPS / WSS──▶ 클라우드 ◀──WSS (파이가 먼저 접속, 계속 유지)── 파이
                      │
                      └── FCM ──▶ 폰 (앱이 꺼져 있을 때 알림)
```

파이는 집 공유기 안이라 클라우드가 먼저 붙을 수 없다. 파이가 연결을 열어 두고, 클라우드는 그 연결로 앱의 요청을 파이에 전달한다.

### 9.0 지금 배포된 클라우드 (2026-11-26 확인)

실제 클라우드는 `../rad2-cloud-backend`(`origin/main`, `https://rad2-cloud.onrender.com`)다. 아래 9.1~9.4 중 **지금 있는 것은 이 표뿐**이고, 나머지는 계획이다. 앱 쪽 계약은 이 표를 기준으로 맞춘다.

| 경로 | 지금 동작 |
| --- | --- |
| `GET /health` | `{"status": "ok", "service": "rad2-cloud"}` (인증 없음) |
| `POST /api/pair` | 코드를 **Render 환경변수 `RAD2_PAIR_CODE`** 와 비교한다. 맞으면 `{"token"}`, 틀리면 401 `bad_code`, 환경변수가 없으면 503 `not_configured`. 파이의 `pair_code.txt`는 쓰지 않는다 |
| `GET /api/info` | 인증 없이 고정 값(`name: "doorradar"`, `version`, `model`, `model_version`, `region`)을 준다. 파이에서 받아 오는 값이 아니다 |
| `GET /api/events`, `GET /api/events/{id}` | 4장과 같다(Bearer 토큰). 이벤트 `id`는 **클라우드 id**이고 파이 id(`edge_event_id`)와 다르다. `photo`는 지금 항상 `false` |
| `POST /api/events/{id}/label` | 4장과 같다. 클라우드 DB에만 저장하고 파이에는 전하지 않는다 |
| `PUT /api/push_token` | `{"token", "platform"?: "android" \| "ios"}` → `{"ok": true, "platform"}` |
| `POST /api/device/events` | 파이 → 클라우드 이벤트 올리기(9.3). 헤더 `X-Device-Key` |

- **없는 것 (404)**: `/api/status`, `/api/settings`, `/api/radar/reconnect`, `/api/events/{id}/photo`, `/api/photos/pending`·`ack`, `/ws/live`, 파이 접속 상태(`pi`), 사진 올리기. 그래서 실제 클라우드에 붙은 앱은 페어링·기록·정답 표시·푸시 등록만 되고, 홈 실시간 지도와 설정·기기 상태는 "연결 안 됨"으로 보인다.
- **기기 한 대**: 클라우드는 `device_id = "rad2pi"` 하나만 받는다. 페어링한 모든 폰이 이 기기를 본다.
- **페어링 코드 맞추기**: Render의 `RAD2_PAIR_CODE`와 앱에 입력하는 코드가 같아야 한다. 파이 코드와는 관계없지만, 헷갈리지 않게 파이 `config.toml`의 `pair_code`도 같은 값으로 고정해 두기를 권한다(비우면 파이가 켤 때마다 새 코드를 만든다).
- 연결 확인: `python scripts/check_cloud.py --code <코드>` (README 「실제 클라우드 연결 확인」).

### 9.1 앱 ↔ 클라우드

- 기본 주소: `https://<클라우드 주소>` (앱 빌드 설정 `--dart-define=CLOUD_URL=...`, 개발 때는 목 서버 `http://10.0.2.2:8080`). WebSocket은 `wss://<클라우드 주소>/ws/live?token=`.
- 경로·요청·응답·오류는 **4장 파이 API와 같다**. 클라우드는 토큰으로 어느 파이인지 안다.
- 다른 점 (파이 API에 **더하기만** 하고 빼거나 바꾸지 않는다):

| 항목 | 내용 |
| --- | --- |
| 연결 순서 | `POST /api/pair {"code"}` → 토큰 → `GET /api/info`. 지금 클라우드의 `/api/info`는 토큰 없이도 같은 고정 값을 준다(9.0) |
| 페어링 코드 | 클라우드 환경변수 `RAD2_PAIR_CODE`의 6자리 고정 코드(9.0). 기기가 한 대라 코드 하나로 충분하다. 파이 `pair_code.txt`도 같은 값으로 맞춰 두면 시연 때 헷갈리지 않는다 |
| 파이 접속 상태 | `/api/status`와 프레임에 `"pi": "online" \| "offline"` 추가. 파이가 끊겨 있으면 클라우드가 1초마다 `{"type": "frame", "t": ..., "radar": "disconnected", "pi": "offline", "people": []}`를 보낸다(앱의 2초 감시가 소켓을 끊지 않게) |
| 오프라인 때 요청 | 파이가 필요한 요청(`PUT /api/settings`, `POST /api/radar/reconnect`, `POST .../label`)은 503 `pi_offline`. 저장된 것만 읽는 요청(`/api/events`, `/api/settings` GET)은 마지막 값으로 답한다 |
| 푸시 토큰 | `PUT /api/push_token {"token": "<FCM 토큰>"}` 추가. 앱 토큰(=폰)마다 하나 |

### 9.2 사진 (폰이 보관, 클라우드는 잠깐)

1. 파이가 `camera` 이벤트를 만들면 사진(원본 + 썸네일)을 클라우드에 올린다.
2. 앱은 지금처럼 `GET /api/photos/pending` → `/api/events/{id}/photo` → `POST /api/photos/ack`(6장).
3. 클라우드는 **그 기기에 페어링된 폰이 모두 ack하면 바로 지우고**, ack가 없어도 **7일**(`cloud_keep_days`, 클라우드 설정) 지나면 지운다. 지운 뒤에는 404 `no_photo`.
4. 파이는 지금처럼 30일(`device_keep_days`) 자기 쪽에 둔다. 폰이 7일 넘게 앱을 안 열면, 다음에 열었을 때 클라우드가 파이에 다시 올려 달라고 요청한다(파이가 30일 안이면 받을 수 있음).

이벤트(사진 제외)는 클라우드 DB에 30일 둔다. 장기 보관은 폰(6장)이 맡는 것은 그대로다.

### 9.3 파이 ↔ 클라우드

**지금 구현 (HTTP로 올리기만)**: 파이(`../pi_server/cloud.py`, 형식은 `../pi_server/docs/CLOUD_API.md`)가 이벤트가 생기거나 바뀔 때 `POST /api/device/events`로 올린다.
헤더 `X-Device-Key`는 Render 환경변수 `RAD2_DEVICE_API_KEY`와 같아야 하고(틀리면 401, 없으면 503), `device_id`는 `"rad2pi"`만 받는다(아니면 403).
본문은 `{"device_id", "edge_event_id", "kind", "person", "t", "situation", "prob", "abnormal", "started_at"?, "ended_at"?, "photo"?, "details": {/* final 의 end_situation·behaviors·reason·path·also·track */}}`이고, 클라우드는 `(device_id, edge_event_id)`로 덮어쓴다.
파이는 사진도 `POST /api/device/events/{edge_event_id}/photo`로 올리지만 클라우드에 이 경로가 아직 없다. 클라우드 → 파이 방향(설정 바꾸기, 실시간 프레임, 접속 상태)도 아직 없다.

**계획 (아래, 클라우드에 아직 없음)**: 목 서버의 바깥 파이 모드(`MOCK_EXTERNAL_PI=1`)가 클라우드 쪽을, `mock_server/fake_pi_client.py`가 파이 쪽을 이대로 구현해 두었다. 둘을 붙여 보면 순서를 그대로 확인할 수 있다. 계획에서는 페어링 코드를 `hello.pair_code`로 알리지만, 지금 클라우드는 9.0의 고정 코드를 쓴다.

**등록** (파이가 처음 한 번, 받은 토큰은 파이 `config.toml` 등에 저장)

```json
POST /pi/register   {"enroll_secret": "<팀이 나눠 준 값>", "name": "doorradar"}
→ 200 {"device_id": "dev-3f9a1c", "device_token": "..."}      틀리면 401 bad_enroll_secret
```

**연결**: `wss://<클라우드>/pi/ws?token=<device_token>`. 토큰이 틀리면 핸드셰이크 거절. 끊기면 1·2·4·8초(이후 8초) 재시도.
붙자마자 `hello`를 보낸다. 클라우드는 `hello`를 받아야 그 파이를 online으로 보고, 앱의 페어링 코드도 여기서 안다.

**파이 → 클라우드** (JSON 텍스트, `type`으로 구분. 모르는 `type`은 서로 무시)

```json
{"type": "hello", "info": {/* 파이 GET /api/info 그대로 */}, "settings": {/* GET /api/settings 그대로 */}, "pair_code": "482913"}
{"type": "frame", "t": "...", "radar": "ok", "people": [...]}          // 파이 /ws/live 의 frame 그대로 (viewers > 0 일 때만)
{"type": "event", "event": {/* GET /api/events/{id} 그대로: track·behaviors 포함 */}}   // 생길 때마다, final 갱신도 같은 id 로
{"type": "status", "status": {/* GET /api/status 그대로 */}}           // 10초마다
{"type": "cmd_result", "id": "a1b2", "status": 200, "body": {/* 파이 API 응답 본문 */}}
```

- 이벤트 `id`는 **파이의 id를 그대로** 쓴다. 클라우드는 id로 덮어쓰고, 앱이 붙인 `label`은 유지한다.
- 사진이 있는 `camera` 이벤트는 **사진을 먼저 올리고 나서** `event`를 보낸다(앱이 이벤트를 받자마자 사진을 받으러 오므로).
- 설정이 바뀌면(파이에서 직접 바꾼 경우 포함) `hello`를 다시 보내도 된다. 클라우드는 마지막 `hello`의 `settings`를 쓴다.

**클라우드 → 파이**

```json
{"type": "viewers", "count": 1}                          // 앱 /ws/live 연결 수. 0이면 frame 을 보내지 않는다 (데이터·비용 절약)
{"type": "cmd", "id": "a1b2", "method": "PUT", "path": "/api/settings", "body": {"camera_on": false}}
{"type": "photo_request", "ids": [128, 131]}             // 이 사진들을 다시 올려 달라 (클라우드에서 지운 뒤 늦게 연 폰)
```

- `cmd`는 세 가지뿐이다: `PUT /api/settings`, `POST /api/radar/reconnect`, `POST /api/events/{id}/label`. 파이는 **자기 로컬 API를 그대로 불러** HTTP 코드와 본문을 `cmd_result`로 돌려준다. 클라우드는 그 결과를 앱에 그대로 준다(오류 본문 `{"error", "message"}` 포함).
- 클라우드는 5초 안에 `cmd_result`가 없으면 앱에 504 `pi_timeout`, 파이가 끊겨 있으면 503 `pi_offline`.

**사진 올리기**: `POST /pi/photos/{event_id}` (본문 `image/jpeg`, `?thumb=1`이면 320×180 썸네일), `Authorization: Bearer <device_token>`. 원본과 썸네일을 각각 올린다.

**파이 쪽 구현 방법**: 기존 파이 서버는 고치지 않고 옆에 클라이언트 프로세스를 하나 붙인다.
로컬 `ws://127.0.0.1:8080/ws/live`(로컬 토큰)를 구독해 `frame`·`event`를 올리고(event는 `GET /api/events/{id}`로 상세를 받아서),
`GET /api/status`를 10초마다 올리고, `cmd`는 로컬 API로 전달한다. 사진은 로컬 `GET /api/events/{id}/photo`로 받아 그대로 올린다.

### 9.4 푸시 (FCM)

- 클라우드가 `camera` 이벤트를 받으면, 그 기기의 `notify`(설정)에 든 상황일 때 페어링된 폰들에 FCM을 보낸다.
- 메시지: `notification {title: "이상 상황", body: "<상황> · HH:mm"}`, `data {event_id, situation, t}`(문자열), `android {priority: high, notification.channel_id: "abnormal"}`.
- 앱이 화면에 있으면 WebSocket으로 이미 알리므로 같은 `event_id` 푸시는 무시한다.

### 9.5 앱에서 바뀌는 것

- 연결 화면: 기기 찾기·IP 입력을 없애고 **6자리 코드만** (`Main.dc.html` 수정함).
- `nsd` 패키지, `ACCESS_WIFI_STATE`·`CHANGE_WIFI_MULTICAST_STATE` 권한을 없앤다. 토큰과 파이 이름만 저장하고, 토큰을 받은 서버가 빌드의 서버와 다르면 버린다.
- 홈·기기 상태: `pi: "offline"`이면 "기기가 꺼져 있거나 인터넷에 연결되지 않았어요".
- 기기 상태의 "파이 이름·IP"는 이름 · 서버 버전 · "클라우드 연결"(꺼져 있으면 안내)로 (`Device.dc.html` 수정함).
- `firebase_messaging`으로 FCM 토큰 등록, 알림 누르면 상세 (Firebase 프로젝트·`google-services.json` 준비되면).
- 목 서버(`mock_server/`)는 클라우드 역할을 한다. 9.1·9.2를 흉내 내고, 개발용 `POST /mock/pi {"online": false}`로 파이 꺼짐을 만든다.

### 9.6 정할 것

- 클라우드 주소(Render 서비스 이름), 무료 플랜의 잠자기·월 사용 시간과 시연 일정
- 등록 비밀값(`enroll_secret`) 나눠 주는 방법
- 사진 저장 위치(Render 디스크 / 오브젝트 스토리지 / PostgreSQL `bytea`). 사진이 금방 지워지므로 작게 시작해도 된다
- 여러 폰이 한 기기에 붙었을 때 "모두 ack"의 기준(30일 넘게 안 쓰는 폰은 빼기 등)
