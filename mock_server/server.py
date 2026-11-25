"""앱 개발용 가짜 클라우드(+ 그 뒤의 라즈베리파이) 서버.

앱은 클라우드를 통해서만 통신한다(docs/SPEC.md 9장). 클라우드는 파이 API(4·5·8장)를 그대로 제공하므로
이 서버도 파이 API를 흉내 내고, 9.1의 클라우드 추가분(토큰으로 /api/info, pi online/offline,
push_token, 503 pi_offline, 사진은 모든 폰이 받으면 지움)을 더한다.
레이더·카메라 없이 고정 이벤트와 대본대로 움직이는 사람(통과 → 방문 → 장시간 체류)을 돌려준다.

개발용: POST /mock/pi {"online": false} 로 파이가 끊긴 상황을 만든다 (true 로 되돌림).

실행:
    pip install -r requirements.txt
    python server.py              # 0.0.0.0:8080, 페어링 코드는 시작할 때 출력
    MOCK_PAIR_CODE=482913 python server.py   # 코드 고정 (PowerShell: $env:MOCK_PAIR_CODE="482913")
    MOCK_SPEED=10 python server.py           # 실시간 대본 10배 빨리 (장시간 체류 알림 확인용)

실제 파이처럼 토큰은 껐다 켜도 남는다(mock_state.json). 이벤트 id 도 이어서 매겨 재사용하지 않는다.
이벤트·사진은 메모리에만 있어서 켤 때마다 오늘치 6개로 다시 시작한다.
"""

from __future__ import annotations

import asyncio
import io
import json
import math
import os
import random
import secrets
import socket
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

import uvicorn
from fastapi import Depends, FastAPI, Query, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse, Response
from PIL import Image, ImageDraw

KST = timezone(timedelta(hours=9))
PORT = int(os.environ.get("MOCK_PORT", "8080"))
PAIR_CODE = os.environ.get("MOCK_PAIR_CODE") or f"{random.randint(0, 999999):06d}"
FPS = 5  # /ws/live 프레임 수 (초당)
SPEED = float(os.environ.get("MOCK_SPEED", "1"))  # 테스트용 빨리 감기 배수

NORMAL = ["통과", "귀가", "외출", "방문", "배달"]
ABNORMAL = ["장시간 체류", "배회", "반복 접근"]
SITUATIONS = NORMAL + ABNORMAL

STATE_FILE = Path(__file__).with_name("mock_state.json")  # 토큰·다음 이벤트 id (실제 파이는 DB)

TOKENS: set[str] = set()
ACKED: dict[str, set[int]] = {}  # 토큰별로 받아 간 사진의 이벤트 id
ACTIVE: set[str] = set()  # 이번에 켠 뒤 요청한 토큰 (= 지금 쓰는 폰). 사진은 이들이 모두 받으면 지운다
DELETED_PHOTOS: set[int] = set()  # 클라우드에서 지운 사진 (파이에는 30일 남음)
PUSH_TOKENS: dict[str, str] = {}  # 앱 토큰 → FCM 토큰 (목 서버는 보내지 않고 기록만)
CLOUD_KEEP_DAYS = 7  # 아무도 안 받아도 이 기간이 지나면 클라우드에서 지움 (SPEC 9.2)
PI_ONLINE = True  # 파이가 클라우드에 붙어 있는지 (POST /mock/pi 로 바꿈)
CLIENTS: set[WebSocket] = set()
STARTED = datetime.now(KST)

SETTINGS: dict[str, Any] = {
    "notify": ["장시간 체류", "배회", "반복 접근"],
    "camera_on": True,
    "camera_prob": 0.6,
    "camera_hold_s": 1.0,
    "region": {"xmin": -2, "xmax": 2, "ymin": 0, "ymax": 3, "fov_deg": 135},
    "device_keep_days": 30,
}
READ_ONLY_SETTINGS = {"region", "device_keep_days"}


def now() -> datetime:
    return datetime.now(KST)


def iso(t: datetime) -> str:
    return t.isoformat(timespec="milliseconds")


# ---------------------------------------------------------------- 오류 형식

class ApiError(Exception):
    def __init__(self, status: int, code: str, message: str):
        self.status, self.code, self.message = status, code, message


# ---------------------------------------------------------------- 이벤트 저장소

EVENTS: dict[int, dict[str, Any]] = {}
_next_id = 100
LAST_FRAME: dict[str, Any] | None = None  # 새로 붙은 WebSocket 에 바로 보낼 프레임


def load_state() -> None:
    global _next_id
    try:
        data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return
    TOKENS.update(data.get("tokens", []))
    _next_id = max(_next_id, int(data.get("next_id", _next_id)))


def save_state() -> None:
    try:
        STATE_FILE.write_text(json.dumps({"tokens": sorted(TOKENS), "next_id": _next_id}), encoding="utf-8")
    except OSError:
        pass


def add_event(ev: dict[str, Any]) -> dict[str, Any]:
    global _next_id
    _next_id += 1
    ev["id"] = _next_id
    if ev["kind"] == "final":
        ev.setdefault("also", [])
    EVENTS[ev["id"]] = ev
    save_state()
    return ev


def summary(ev: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in ev.items() if k not in ("track", "behaviors")}


def straight(a: tuple[float, float], b: tuple[float, float], n: int) -> list[tuple[float, float]]:
    return [(a[0] + (b[0] - a[0]) * i / max(n - 1, 1), a[1] + (b[1] - a[1]) * i / max(n - 1, 1)) for i in range(n)]


def track_of(points: list[tuple[float, float]]) -> list[list[float]]:
    return [[round(i * 0.2, 1), round(x, 2), round(y, 2)] for i, (x, y) in enumerate(points)]


def seed_events() -> None:
    """와이어프레임과 같은 오늘치 이벤트 6개."""
    today = now().replace(second=0, microsecond=0)
    if today.hour < 16:  # 아직 15시 전이면 어제 날짜로 넣어서 미래 시각이 안 생기게
        today -= timedelta(days=1)

    def at(h: int, m: int, s: int = 0) -> datetime:
        return today.replace(hour=h, minute=m, second=s)

    rows = [
        # (시작, 길이 초, 최종, 확률, 끝날 때 판정, path, photo, kind)
        (at(8, 47), 6, "통과", 0.98, "통과", "왼쪽 외곽 → 오른쪽 외곽", False),
        (at(9, 12), 9, "외출", 0.93, "외출", "문에서 나옴(0.4m) → 외곽으로 사라짐(2.6m)", False),
        (at(11, 58), 60, "반복 접근", 1.0, "방문", "60초 동안 문 앞에 3번 다가옴", True),
        (at(13, 20), 8, "귀가", 0.97, "귀가", "외곽에서 들어옴(2.7m) → 문으로 사라짐(0.4m)", False),
        (at(14, 41), 25, "배달", 0.93, "배달", "외곽에서 들어옴 → 문 앞 머무름 12초 → 외곽으로 사라짐", False),
        (at(15, 2, 17), 83, "장시간 체류", 1.0, "방문", "외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)", True),
    ]
    for no, (start, dur, sit, prob, end_sit, path, photo) in enumerate(rows, start=1):
        person = f"T{no}"
        abnormal = sit in ABNORMAL
        pts = straight((1.8, 2.6), (0.2, 0.5), max(int(dur * 5), 2))
        if photo:
            add_event({
                "kind": "camera", "person": person, "t": iso(start + timedelta(seconds=min(dur, 53))),
                "started_at": iso(start), "ended_at": None, "situation": sit, "prob": prob,
                "abnormal": abnormal, "photo": True, "label": None,
            })
        behaviors = [{"situation": sit, "prob": prob, "source": "progress" if abnormal else "end"}]
        if end_sit != sit:
            behaviors.append({"situation": end_sit, "prob": 0.94, "source": "end"})
        reason = (f"이상 행동 우선: 진행 중 {sit} {round(prob * 100)}% → 끝날 때 판정 {end_sit} 94% 대신"
                  if end_sit != sit else f"끝날 때 판정 {sit} {round(prob * 100)}%")
        add_event({
            "kind": "final", "person": person, "t": iso(start + timedelta(seconds=dur)),
            "started_at": iso(start), "ended_at": iso(start + timedelta(seconds=dur)),
            "situation": sit, "prob": prob, "abnormal": abnormal, "end_situation": end_sit,
            "behaviors": behaviors, "reason": reason, "path": path, "photo": photo, "label": None,
            "track": track_of(pts),
        })


# ---------------------------------------------------------------- 실시간 대본

def scene_points(name: str) -> list[tuple[float, float]]:
    n = FPS
    if name == "통과":
        return straight((-2.0, 2.3), (2.0, 2.0), 8 * n)
    if name == "방문":
        return (straight((1.8, 2.8), (0.2, 0.7), 6 * n) + [(0.2, 0.7)] * (5 * n)
                + straight((0.2, 0.7), (-1.9, 2.8), 6 * n))
    # 장시간 체류: 문 앞 1.4m 근처에서 40초 머물다 문으로 사라짐
    stay = [(0.9 + 0.05 * math.sin(i / 7), 1.15 + 0.04 * math.cos(i / 9)) for i in range(40 * n)]
    return straight((1.9, 2.7), (0.9, 1.15), 6 * n) + stay + straight((0.9, 1.15), (0.1, 0.4), 4 * n)


async def broadcast_frame(msg: dict[str, Any]) -> None:
    global LAST_FRAME
    msg["pi"] = "online"
    LAST_FRAME = msg
    await broadcast(msg)


def offline_frame() -> dict[str, Any]:
    return {"type": "frame", "t": iso(now()), "radar": "disconnected", "pi": "offline", "people": []}


async def wait_pi() -> None:
    """파이가 끊겨 있으면 대본을 멈추고, 클라우드처럼 1초마다 offline 프레임을 보낸다 (SPEC 9.1)."""
    while not PI_ONLINE:
        await broadcast(offline_frame())
        await asyncio.sleep(1)


async def broadcast(msg: dict[str, Any]) -> None:
    for ws in list(CLIENTS):
        try:
            await ws.send_json(msg)
        except Exception:
            CLIENTS.discard(ws)


async def live_loop() -> None:
    dt = 1 / FPS
    person_no = 10
    while True:
        for name in ["통과", "방문", "장시간 체류"]:
            person_no += 1
            pid = f"T{person_no}"
            pts = scene_points(name)
            start = now()
            camera_sent = False
            dwell_from: int | None = None
            for i, (x, y) in enumerate(pts):
                await wait_pi()
                elapsed = i * dt
                situation, prob, abnormal = "판단 중", 0.0, False
                if elapsed >= 2:
                    situation = name if name != "장시간 체류" else "방문"
                    prob = min(0.55 + elapsed * 0.04, 0.98)
                if name == "장시간 체류":
                    near = math.hypot(x - 0.9, y - 1.15) < 0.2
                    if near and dwell_from is None:
                        dwell_from = i
                    still = (i - dwell_from) * dt if dwell_from is not None else 0.0
                    if still >= 15:
                        situation, prob, abnormal = "장시간 체류", 1.0, True
                    if (abnormal and not camera_sent and still >= 15 + SETTINGS["camera_hold_s"]
                            and SETTINGS["camera_on"]):
                        camera_sent = True
                        ev = add_event({
                            "kind": "camera", "person": pid, "t": iso(now()), "started_at": iso(start),
                            "ended_at": None, "situation": "장시간 체류", "prob": 1.0, "abnormal": True,
                            "photo": True, "label": None,
                        })
                        await broadcast({"type": "event", "event": summary(ev)})
                else:
                    still = 0.0
                await broadcast_frame({
                    "type": "frame", "t": iso(now()), "radar": "ok",
                    "people": [{
                        "id": pid, "x": round(x, 2), "y": round(y, 2), "hidden": False,
                        "situation": situation, "prob": round(prob, 2), "abnormal": abnormal,
                        "still_s": round(still, 1), "elapsed_s": round(elapsed, 1),
                    }],
                })
                await asyncio.sleep(dt / SPEED)

            end = now()
            abnormal = name in ABNORMAL
            end_sit = "방문" if name == "장시간 체류" else name
            behaviors = [{"situation": name, "prob": 1.0 if abnormal else 0.95, "source": "progress" if abnormal else "end"}]
            if end_sit != name:
                behaviors.append({"situation": end_sit, "prob": 0.94, "source": "end"})
            final = {
                "kind": "final", "person": pid, "t": iso(end), "started_at": iso(start), "ended_at": iso(end),
                "situation": name, "prob": behaviors[0]["prob"], "abnormal": abnormal, "end_situation": end_sit,
                "behaviors": behaviors,
                "reason": (f"이상 행동 우선: 진행 중 {name} 100% → 끝날 때 판정 {end_sit} 94% 대신"
                           if abnormal else f"끝날 때 판정 {name} 95%"),
                "path": {"통과": "왼쪽 외곽 → 오른쪽 외곽", "방문": "외곽에서 들어옴(2.9m) → 외곽으로 사라짐(3.4m)",
                         "장시간 체류": "외곽에서 들어옴(2.9m) → 문으로 사라짐(0.4m)"}[name],
                "photo": camera_sent, "label": None, "track": track_of(pts),
            }
            # 사람 없는 시간. final 은 실제 파이처럼 사라지고 3초 뒤에 나간다 (t 는 사라진 시각)
            for k in range(4 * FPS):
                await wait_pi()
                if k == 3 * FPS:
                    ev = add_event(final)
                    await broadcast({"type": "event", "event": summary(ev)})
                await broadcast_frame({"type": "frame", "t": iso(now()), "radar": "ok", "people": []})
                await asyncio.sleep(dt / SPEED)


# ---------------------------------------------------------------- 앱

@asynccontextmanager
async def lifespan(_: FastAPI):
    load_state()
    seed_events()
    task = asyncio.create_task(live_loop())
    yield
    task.cancel()


app = FastAPI(title="Door Radar mock", lifespan=lifespan)


@app.exception_handler(ApiError)
async def api_error_handler(_: Request, exc: ApiError) -> JSONResponse:
    return JSONResponse({"error": exc.code, "message": exc.message}, status_code=exc.status)


def require_token(request: Request) -> str:
    auth = request.headers.get("authorization", "")
    token = auth[7:] if auth.lower().startswith("bearer ") else ""
    if token not in TOKENS:
        raise ApiError(401, "unauthorized", "토큰이 없거나 틀렸습니다. /api/pair 로 다시 페어링하세요.")
    ACTIVE.add(token)
    return token


def require_pi() -> None:
    """파이에 전달해야 하는 요청 (SPEC 9.1): 파이가 끊겨 있으면 503."""
    if not PI_ONLINE:
        raise ApiError(503, "pi_offline", "기기가 꺼져 있거나 인터넷에 연결되지 않았어요.")


def get_event(event_id: int) -> dict[str, Any]:
    ev = EVENTS.get(event_id)
    if ev is None:
        raise ApiError(404, "not_found", f"이벤트 {event_id} 가 없습니다.")
    return ev


@app.get("/api/info")
def info(request: Request) -> dict[str, Any]:
    # 클라우드: 토큰이 있어야 어느 파이인지 안다. 없으면 클라우드 정보만 (SPEC 9.1)
    auth = request.headers.get("authorization", "")
    if auth[7:] not in TOKENS:
        return {"name": "rad2-cloud", "version": "0.1.0-mock"}
    return {"name": "doorradar", "host": "rad2pi.local", "version": "0.1.0-mock",
            "model": "situation_trees_1111", "model_version": "v5", "region": SETTINGS["region"]}


@app.post("/mock/pi")
async def mock_pi(request: Request) -> dict[str, bool]:
    """개발용: 파이가 클라우드에서 끊긴 상황 만들기 {"online": false}."""
    global PI_ONLINE
    PI_ONLINE = bool((await request.json()).get("online", True))
    return {"online": PI_ONLINE}


@app.put("/api/push_token")
async def push_token(request: Request, token: str = Depends(require_token)) -> dict[str, bool]:
    """FCM 토큰 등록 (SPEC 9.1). 목 서버는 기록만 하고 푸시는 보내지 않는다."""
    fcm = (await request.json()).get("token")
    if not isinstance(fcm, str) or not fcm:
        raise ApiError(400, "bad_token", "token 은 FCM 토큰 문자열이어야 합니다.")
    PUSH_TOKENS[token] = fcm
    return {"ok": True}


@app.post("/api/pair")
async def pair(request: Request) -> dict[str, str]:
    body = await request.json()
    if str(body.get("code", "")) != PAIR_CODE:
        raise ApiError(401, "bad_code", "페어링 코드가 틀렸습니다.")
    token = secrets.token_urlsafe(24)
    TOKENS.add(token)
    ACKED.setdefault(token, set())
    save_state()
    return {"token": token}


@app.get("/api/status")
def status(token: str = Depends(require_token)) -> dict[str, Any]:
    photos = sum(1 for e in EVENTS.values() if e.get("photo"))
    return {
        "radar": "ok", "radar_host": "192.168.0.20", "radar_error": None, "frame_rate": 10.0,
        "camera": "ok", "camera_backend": "fake",
        "latency_s": 0.12, "judge_error": None, "cpu_temp_c": 52.3,
        "uptime_s": int((now() - STARTED).total_seconds()),
        "storage": {"used_gb": round(1.0 + photos * 0.0003, 2), "total_gb": 29.0, "photos": photos},
        "pending_photos": len(pending_ids(token)),
        "pi": "online" if PI_ONLINE else "offline",
    } | ({} if PI_ONLINE else {"radar": "disconnected"})


@app.post("/api/radar/reconnect")
def radar_reconnect(_: str = Depends(require_token)) -> dict[str, str]:
    require_pi()
    return {"radar": "connecting"}


@app.get("/api/events")
def events(since: str | None = None, limit: int = Query(50, ge=1, le=500), abnormal: bool | None = None,
           _: str = Depends(require_token)) -> list[dict[str, Any]]:
    items = sorted(EVENTS.values(), key=lambda e: e["t"], reverse=True)
    if since:
        try:
            # URL 에서 "+09:00" 의 + 가 공백으로 바뀌어 와도 되돌려 읽는다
            s = datetime.fromisoformat(since.strip().replace(" ", "+"))
        except ValueError:
            raise ApiError(400, "bad_since", "since 는 ISO 8601 시각이어야 합니다.")
        if s.tzinfo is None:  # 시간대가 없으면 한국 시간
            s = s.replace(tzinfo=KST)
        items = [e for e in items if datetime.fromisoformat(e["t"]) > s]
    if abnormal is not None:
        items = [e for e in items if e["abnormal"] == abnormal]
    return [summary(e) for e in items[:limit]]


@app.get("/api/events/{event_id}")
def event_detail(event_id: int, _: str = Depends(require_token)) -> dict[str, Any]:
    return get_event(event_id)


def render_photo(ev: dict[str, Any], thumb: bool) -> bytes:
    w, h = (320, 180) if thumb else (1920, 1080)
    img = Image.new("RGB", (w, h), (32, 32, 32))
    d = ImageDraw.Draw(img)
    d.rectangle([w * 0.42, h * 0.25, w * 0.58, h * 0.95], outline=(140, 140, 140), width=max(w // 320, 1))
    d.text((w * 0.04, h * 0.06), f"MOCK IR  event {ev['id']}  {ev['t'][11:19]}", fill=(220, 220, 220))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=80)
    return buf.getvalue()


@app.get("/api/events/{event_id}/photo")
def event_photo(event_id: int, thumb: int = 0, _: str = Depends(require_token)) -> Response:
    ev = get_event(event_id)
    if not ev.get("photo"):
        raise ApiError(404, "no_photo", "이 이벤트에는 사진이 없습니다.")
    if event_id in DELETED_PHOTOS:
        raise ApiError(404, "no_photo", "모든 폰이 받아 가서 클라우드에서 지운 사진입니다.")
    return Response(render_photo(ev, bool(thumb)), media_type="image/jpeg")


@app.post("/api/events/{event_id}/label")
async def event_label(event_id: int, request: Request, _: str = Depends(require_token)) -> dict[str, Any]:
    require_pi()
    ev = get_event(event_id)
    situation = (await request.json()).get("situation")
    if situation is None:  # 되돌리기: 정답 지우기
        ev["label"] = None
        return summary(ev)
    if situation not in SITUATIONS:
        raise ApiError(400, "bad_situation", f"situation 은 {', '.join(SITUATIONS)} 중 하나여야 합니다.")
    ev["label"] = situation
    return summary(ev)


@app.get("/api/settings")
def get_settings(_: str = Depends(require_token)) -> dict[str, Any]:
    return SETTINGS


@app.put("/api/settings")
async def put_settings(request: Request, _: str = Depends(require_token)) -> dict[str, Any]:
    require_pi()
    body = await request.json()
    for key in body:
        if key in READ_ONLY_SETTINGS:
            continue  # 읽기 전용은 조용히 무시
        if key not in SETTINGS:
            raise ApiError(400, "unknown_setting", f"모르는 설정입니다: {key}")
    if "notify" in body and not set(body["notify"]) <= set(ABNORMAL):
        raise ApiError(400, "bad_notify", f"notify 는 {', '.join(ABNORMAL)} 중에서 고릅니다.")
    if "camera_prob" in body and not 0 <= float(body["camera_prob"]) <= 1:
        raise ApiError(400, "bad_camera_prob", "camera_prob 는 0~1 입니다.")
    if "camera_hold_s" in body and not 0 <= float(body["camera_hold_s"]) <= 10:
        raise ApiError(400, "bad_camera_hold_s", "camera_hold_s 는 0~10초 입니다.")
    for key, value in body.items():
        if key not in READ_ONLY_SETTINGS:
            SETTINGS[key] = value
    return SETTINGS


def pending_ids(token: str) -> list[int]:
    """사진이 있고, 클라우드에 아직 있고(7일 안, 안 지움), 이 토큰이 ack 하지 않은 이벤트 id. 오래된 것부터."""
    limit = now() - timedelta(days=CLOUD_KEEP_DAYS)
    acked = ACKED.setdefault(token, set())
    return [e["id"] for e in sorted(EVENTS.values(), key=lambda e: e["t"])
            if e.get("photo") and e["id"] not in acked and e["id"] not in DELETED_PHOTOS
            and datetime.fromisoformat(e["t"]) > limit]


@app.get("/api/photos/pending")
def photos_pending(token: str = Depends(require_token)) -> dict[str, list[int]]:
    return {"ids": pending_ids(token)}


@app.post("/api/photos/ack")
async def photos_ack(request: Request, token: str = Depends(require_token)) -> dict[str, int]:
    ids = (await request.json()).get("ids", [])
    ACKED.setdefault(token, set()).update(int(i) for i in ids if int(i) in EVENTS)
    # 지금 쓰는 폰이 모두 받았으면 클라우드에서 지운다 (SPEC 9.2. 파이에는 30일 남음)
    for i in ids:
        if all(int(i) in ACKED.get(t, set()) for t in ACTIVE):
            DELETED_PHOTOS.add(int(i))
    return {"acked": len(ACKED[token])}


@app.websocket("/ws/live")
async def ws_live(ws: WebSocket, token: str = "") -> None:
    if token not in TOKENS:
        await ws.close(code=4401)
        return
    await ws.accept()
    CLIENTS.add(ws)
    try:
        # 붙자마자 프레임 하나를 바로 보낸다
        first = LAST_FRAME or {"type": "frame", "t": iso(now()), "radar": "ok", "pi": "online", "people": []}
        await ws.send_json(first if PI_ONLINE else offline_frame())
        while True:
            await ws.receive_text()  # 앱이 보내는 건 없지만 연결 유지용
    except (WebSocketDisconnect, RuntimeError):
        pass
    finally:
        CLIENTS.discard(ws)


def lan_ip() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"


if __name__ == "__main__":
    print(f"\n  가짜 라즈베리파이 서버  http://{lan_ip()}:{PORT}")
    print(f"  페어링 코드: {PAIR_CODE}")
    print(f"  Android 에뮬레이터에서는 http://10.0.2.2:{PORT}\n")
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="warning")
