"""파이 ↔ 클라우드 클라이언트 예시 (docs/SPEC.md 9.3). 진짜 파이 없이 바깥 파이 모드를 시험하고,
파이 담당이 실제 클라이언트를 만들 때 메시지 순서를 참고하는 용도.

    # 1) 가짜 클라우드를 바깥 파이 모드로 (PowerShell)
    $env:MOCK_EXTERNAL_PI="1"; .\\.venv\\Scripts\\python.exe server.py
    # 2) 이 스크립트 (다른 터미널)
    .\\.venv\\Scripts\\python.exe fake_pi_client.py --cloud http://127.0.0.1:8080
    # 3) 앱에서 페어링 코드 135790 으로 연결

하는 일: 등록(/pi/register, 토큰은 fake_pi_token.txt 에 저장) → /pi/ws 연결 → hello →
앱이 보고 있으면(viewers > 0) 프레임 초당 5번 → 30초마다 장시간 체류 한 명(camera 이벤트 + 사진 업로드 → final) →
10초마다 status → cmd(설정·레이더·정답)에 cmd_result → photo_request 에 사진 다시 올림. 끊기면 1·2·4·8초 재시도.
진짜 파이에서는 frame·event·status 를 로컬 서버(/ws/live, /api/status)에서 받아 그대로 올리고,
cmd 는 로컬 API(http://127.0.0.1:8080)를 그대로 불러 결과를 돌려주면 된다.
"""

from __future__ import annotations

import argparse
import asyncio
import io
import json
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

import websockets
from PIL import Image, ImageDraw

KST = timezone(timedelta(hours=9))
TOKEN_FILE = Path(__file__).with_name("fake_pi_token.txt")
PAIR_CODE = "135790"
REGION = {"xmin": -2.0, "xmax": 2.0, "ymin": 0.0, "ymax": 3.0, "fov_deg": 135.0}

settings = {"notify": ["장시간 체류", "배회", "반복 접근"], "camera_on": True, "camera_prob": 0.6,
            "camera_hold_s": 1.0, "region": REGION, "device_keep_days": 30}
events: dict[int, dict] = {}
viewers = 0
next_id = int(datetime.now(KST).timestamp()) % 1_000_000  # 재시작해도 겹치지 않게


def iso(t: datetime) -> str:
    return t.isoformat(timespec="milliseconds")


def post_json(url: str, body: dict, token: str | None = None) -> dict:
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method="POST",
                                 headers={"Content-Type": "application/json",
                                          **({"Authorization": f"Bearer {token}"} if token else {})})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


def upload_photo(cloud: str, token: str, event_id: int) -> None:
    for thumb, size in ((False, (1920, 1080)), (True, (320, 180))):
        img = Image.new("RGB", size, (40, 30, 40))
        ImageDraw.Draw(img).text((20, 20), f"FAKE PI  event {event_id}", fill=(230, 230, 230))
        buf = io.BytesIO()
        img.save(buf, "JPEG", quality=80)
        req = urllib.request.Request(f"{cloud}/pi/photos/{event_id}{'?thumb=1' if thumb else ''}",
                                     data=buf.getvalue(), method="POST",
                                     headers={"Content-Type": "image/jpeg", "Authorization": f"Bearer {token}"})
        urllib.request.urlopen(req, timeout=10).read()


def register(cloud: str, secret: str) -> str:
    if TOKEN_FILE.exists():
        return TOKEN_FILE.read_text().strip()
    r = post_json(f"{cloud}/pi/register", {"enroll_secret": secret, "name": "doorradar"})
    TOKEN_FILE.write_text(r["device_token"])
    print("등록:", r["device_id"])
    return r["device_token"]


def status() -> dict:
    return {"radar": "ok", "radar_host": "fake", "radar_error": None, "frame_rate": 10.0, "camera": "ok",
            "camera_backend": "fake", "latency_s": 0.1, "judge_error": None, "cpu_temp_c": 50.0, "uptime_s": 60,
            "storage": {"used_gb": 6.1, "total_gb": 29.0, "photos": sum(1 for e in events.values() if e["photo"])},
            "pending_photos": 0}


def handle_cmd(msg: dict) -> dict:
    """진짜 파이에서는 로컬 API 를 그대로 부르고 그 HTTP 코드·본문을 돌려준다."""
    method, path, body = msg["method"], msg["path"], msg.get("body")
    if (method, path) == ("PUT", "/api/settings"):
        settings.update({k: v for k, v in (body or {}).items() if k not in ("region", "device_keep_days")})
        return {"status": 200, "body": settings}
    if (method, path) == ("POST", "/api/radar/reconnect"):
        return {"status": 200, "body": {"radar": "connecting"}}
    if method == "POST" and path.endswith("/label"):
        ev = events.get(int(path.split("/")[3]))
        if ev is None:
            return {"status": 404, "body": {"error": "not_found", "message": "없는 이벤트"}}
        ev["label"] = (body or {}).get("situation")
        return {"status": 200, "body": {k: v for k, v in ev.items() if k not in ("track", "behaviors")}}
    return {"status": 404, "body": {"error": "not_found", "message": f"{method} {path}"}}


async def scenario(ws, cloud: str, token: str) -> None:
    """30초마다 한 명: 문 앞에 머물다(장시간 체류) 촬영 → 사라지면 3초 뒤 final."""
    global next_id
    while True:
        start = datetime.now(KST)
        pid = f"T{next_id % 100}"
        camera_id = None
        for i in range(25 * 5):  # 25초
            t = datetime.now(KST)
            still = max(0.0, i / 5 - 3)
            abnormal = still >= 15
            if abnormal and camera_id is None:
                next_id += 1
                camera_id = next_id
                ev = {"id": camera_id, "kind": "camera", "person": pid, "t": iso(t), "started_at": iso(start),
                      "ended_at": None, "situation": "장시간 체류", "prob": 1.0, "abnormal": True,
                      "photo": settings["camera_on"], "label": None}
                events[camera_id] = ev
                if ev["photo"]:
                    await asyncio.to_thread(upload_photo, cloud, token, camera_id)  # 사진 먼저, 그다음 이벤트
                await ws.send(json.dumps({"type": "event", "event": ev}))
            if viewers > 0:
                await ws.send(json.dumps({"type": "frame", "t": iso(t), "radar": "ok", "people": [{
                    "id": pid, "x": 0.9, "y": 1.2, "hidden": False,
                    "situation": "장시간 체류" if abnormal else ("방문" if i > 5 else "판단 중"),
                    "prob": 1.0 if abnormal else (0.8 if i > 5 else 0.0), "abnormal": abnormal,
                    "still_s": round(still, 1), "elapsed_s": round(i / 5, 1)}]}, ensure_ascii=False))
            await asyncio.sleep(0.2)
        end = datetime.now(KST)
        for _ in range(15):  # 사라지고 3초
            if viewers > 0:
                await ws.send(json.dumps({"type": "frame", "t": iso(datetime.now(KST)), "radar": "ok", "people": []}))
            await asyncio.sleep(0.2)
        next_id += 1
        final = {"id": next_id, "kind": "final", "person": pid, "t": iso(end), "started_at": iso(start),
                 "ended_at": iso(end), "situation": "장시간 체류", "prob": 1.0, "abnormal": True, "also": [],
                 "end_situation": "방문", "behaviors": [{"situation": "장시간 체류", "prob": 1.0, "source": "progress"},
                                                       {"situation": "방문", "prob": 0.94, "source": "end"}],
                 "reason": "이상 행동 우선: 진행 중 장시간 체류 100% → 끝날 때 판정 방문 94% 대신",
                 "path": "외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)", "photo": camera_id is not None and settings["camera_on"],
                 "label": None, "track": [[round(i * 0.2, 1), 0.9, 1.2] for i in range(10)]}
        events[next_id] = final
        await ws.send(json.dumps({"type": "event", "event": final}, ensure_ascii=False))
        await asyncio.sleep(5)


async def run(cloud: str, secret: str) -> None:
    global viewers
    token = register(cloud, secret)
    ws_url = cloud.replace("http", "ws", 1) + f"/pi/ws?token={token}"
    delays, fails = [1, 2, 4, 8], 0
    while True:
        try:
            async with websockets.connect(ws_url) as ws:
                fails = 0
                info = {"name": "doorradar", "host": "fake-pi", "version": "0.1.0-fake", "model": "situation_trees_real",
                        "model_version": "v5", "region": REGION}
                await ws.send(json.dumps({"type": "hello", "info": info, "settings": settings, "pair_code": PAIR_CODE},
                                         ensure_ascii=False))
                print("연결됨. 앱에서 페어링 코드", PAIR_CODE)

                async def status_loop():
                    while True:
                        await ws.send(json.dumps({"type": "status", "status": status()}))
                        await asyncio.sleep(10)

                tasks = [asyncio.create_task(scenario(ws, cloud, token)), asyncio.create_task(status_loop())]
                try:
                    async for raw in ws:
                        msg = json.loads(raw)
                        if msg.get("type") == "viewers":
                            viewers = int(msg.get("count", 0))
                        elif msg.get("type") == "cmd":
                            await ws.send(json.dumps({"type": "cmd_result", "id": msg["id"], **handle_cmd(msg)},
                                                     ensure_ascii=False))
                        elif msg.get("type") == "photo_request":
                            for i in msg.get("ids", []):
                                if i in events and events[i]["photo"]:
                                    await asyncio.to_thread(upload_photo, cloud, token, i)
                finally:
                    for t in tasks:
                        t.cancel()
        except (OSError, websockets.WebSocketException) as e:
            fails += 1
            wait = delays[min(fails, len(delays)) - 1]
            print(f"끊김 ({e}). {wait}초 뒤 다시")
            await asyncio.sleep(wait)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--cloud", default="http://127.0.0.1:8080")
    ap.add_argument("--secret", default="dev-enroll")
    args = ap.parse_args()
    asyncio.run(run(args.cloud.rstrip("/"), args.secret))
