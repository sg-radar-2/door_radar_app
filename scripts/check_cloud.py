"""실제 클라우드(rad2-cloud) 연결 확인. 파이·레이더·앱 없이 PC에서 돌린다 (SPEC 9.0).

    python scripts/check_cloud.py                      # 서버 상태와 /api/info 만
    python scripts/check_cloud.py --code 185820        # 페어링 → 토큰으로 이벤트 읽기까지
    python scripts/check_cloud.py --token <토큰>        # 이미 받은 토큰으로 (페어링 안 함)

    # 파이 대신 테스트 이벤트 하나를 올려 앱 기록에 뜨는지 본다 (실제 DB에 남음, 기기 키 필요)
    python scripts/check_cloud.py --code 185820 --send-test-event --device-key <RAD2_DEVICE_API_KEY>

--code 를 주면 클라우드 DB에 앱 토큰이 하나 생긴다. 출력된 토큰을 --token 으로 다시 쓰면 더 안 생긴다.
표준 라이브러리만 쓴다. Render 무료 플랜이 잠들어 있으면 첫 요청이 30~60초 걸린다.
"""
from __future__ import annotations

import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from typing import Any

DEFAULT_URL = "https://rad2-cloud.onrender.com"
KST = timezone(timedelta(hours=9))

ok_count = 0
fail_count = 0


def ssl_context() -> ssl.SSLContext:
    """기본 인증서가 없는 파이썬(MSYS2 등)이면 Windows 인증서 저장소나 certifi 를 쓴다."""
    ctx = ssl.create_default_context()
    if ctx.cert_store_stats().get("x509_ca", 0):
        return ctx
    for store in ("ROOT", "CA"):
        for cert, enc, _ in getattr(ssl, "enum_certificates", lambda _s: [])(store):
            if enc == "x509_asn":
                try:
                    ctx.load_verify_locations(cadata=cert)
                except ssl.SSLError:
                    pass
    if not ctx.cert_store_stats().get("x509_ca", 0):
        try:
            import certifi  # type: ignore[import-not-found]
            ctx.load_verify_locations(certifi.where())
        except ImportError:
            pass
    return ctx


SSL_CTX = ssl_context()


def call(base: str, method: str, path: str, *, body: Any = None, token: str | None = None,
         headers: dict[str, str] | None = None, timeout: float = 20) -> tuple[int, Any, float]:
    """(HTTP 상태, JSON 본문 또는 텍스트, 걸린 초). 네트워크 오류는 상태 0."""
    data = None if body is None else json.dumps(body, ensure_ascii=False).encode()
    req = urllib.request.Request(base + path, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    start = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=SSL_CTX) as res:
            status, raw = res.status, res.read()
    except urllib.error.HTTPError as e:
        status, raw = e.code, e.read()
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        return 0, str(e), time.monotonic() - start
    text = raw.decode("utf-8", "replace")
    try:
        parsed: Any = json.loads(text) if text else None
    except ValueError:
        parsed = text
    return status, parsed, time.monotonic() - start


def report(ok: bool, name: str, detail: str) -> None:
    global ok_count, fail_count
    if ok:
        ok_count += 1
    else:
        fail_count += 1
    print(f"  [{'OK' if ok else '실패'}] {name}: {detail}")


def short(body: Any, n: int = 160) -> str:
    s = body if isinstance(body, str) else json.dumps(body, ensure_ascii=False)
    return s if len(s) <= n else s[:n] + "…"


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(description="rad2-cloud 연결 확인 (SPEC 9.0)")
    p.add_argument("--url", default=DEFAULT_URL, help=f"클라우드 주소 (기본 {DEFAULT_URL})")
    p.add_argument("--code", help="페어링 코드 (Render 환경변수 RAD2_PAIR_CODE)")
    p.add_argument("--token", help="이미 받은 앱 토큰 (주면 페어링을 건너뜀)")
    p.add_argument("--send-test-event", action="store_true", help="파이 대신 테스트 이벤트를 올린다 (실제 DB에 남음)")
    p.add_argument("--device-key", help="X-Device-Key (Render 환경변수 RAD2_DEVICE_API_KEY)")
    args = p.parse_args()
    base = args.url.rstrip("/")

    print(f"클라우드: {base}")

    # 1. 서버가 살아 있나 (Render 가 잠들어 있으면 여기서 깨어난다)
    print("\n1) 서버")
    status, body, sec = call(base, "GET", "/health", timeout=90)
    report(status == 200, "GET /health", f"{status} {short(body)} ({sec:.1f}초)")
    if status == 0 and "CERTIFICATE_VERIFY_FAILED" in str(body):
        print("\n이 파이썬에는 루트 인증서가 없다. Windows 파이썬으로 다시: py scripts\\check_cloud.py ...")
        return 1
    if status != 200:
        print("\n서버에 닿지 않는다. 주소, 인터넷, Render 서비스 상태(대시보드 Logs)를 확인한다.")
        return 1

    status, body, _ = call(base, "GET", "/api/info")
    info_ok = status == 200 and isinstance(body, dict) and {"name", "version", "region"} <= body.keys()
    report(info_ok, "GET /api/info", f"{status} {short(body)}")

    # 2. 페어링
    token = args.token
    print("\n2) 페어링")
    if token:
        print("  --token 을 받아서 페어링은 건너뜀")
    elif args.code:
        status, body, _ = call(base, "POST", "/api/pair", body={"code": args.code})
        if status == 200 and isinstance(body, dict) and body.get("token"):
            token = body["token"]
            report(True, "POST /api/pair", "토큰 받음")
            print(f"  토큰: {token}\n  (다음에는 --token 으로 다시 쓰면 DB에 토큰이 더 안 쌓인다)")
        else:
            report(False, "POST /api/pair", f"{status} {short(body)}")
            if status == 401:
                print("  → 코드가 Render 의 RAD2_PAIR_CODE 와 다르다. 파이 pair_code.txt 가 아니라 Render 값을 쓴다.")
            elif status == 503:
                print("  → Render 에 RAD2_PAIR_CODE 가 없다. Environment 에 넣고 다시 배포한다.")
    else:
        print("  --code 나 --token 이 없어서 건너뜀 (여기서 끝)")

    # 3. 토큰으로 읽기
    if token:
        print("\n3) 토큰으로 읽기")
        status, body, _ = call(base, "GET", "/api/events", token="틀린토큰")
        report(status == 401, "틀린 토큰은 401", f"{status}")

        status, body, _ = call(base, "GET", "/api/events?limit=5", token=token)
        events = body if status == 200 and isinstance(body, list) else None
        report(events is not None, "GET /api/events?limit=5",
               f"{status} {len(events)}개" if events is not None else f"{status} {short(body)}")
        for ev in events or []:
            print(f"     #{ev.get('id')} {ev.get('t')} {ev.get('kind')} {ev.get('situation')}"
                  f"{' (이상)' if ev.get('abnormal') else ''}{' 정답=' + ev['label'] if ev.get('label') else ''}")
        if events:
            first = events[0]["id"]
            status, body, _ = call(base, "GET", f"/api/events/{first}", token=token)
            report(status == 200, f"GET /api/events/{first}",
                   f"{status} 키: {', '.join(sorted(body))}" if status == 200 else f"{status} {short(body)}")
        elif events == []:
            print("     (이벤트 없음: 파이가 아직 아무것도 안 올렸다. --send-test-event 로 하나 올려 볼 수 있다)")

        since = (datetime.now(KST) - timedelta(days=1)).isoformat(timespec="seconds").replace("+", "%2B")
        status, body, _ = call(base, "GET", f"/api/events?since={since}", token=token)
        report(status == 200, "GET /api/events?since=(하루 전)",
               f"{status} {len(body)}개" if status == 200 and isinstance(body, list) else f"{status} {short(body)}")

    # 4. 파이 대신 이벤트 올리기
    if args.send_test_event:
        print("\n4) 테스트 이벤트 올리기 (파이 역할)")
        if not args.device_key:
            report(False, "POST /api/device/events", "--device-key 가 필요하다 (Render 의 RAD2_DEVICE_API_KEY)")
        else:
            now = datetime.now(KST)
            edge_id = int(time.time())  # 실제 파이 id(작은 수)와 겹치지 않게
            ev = {
                "device_id": "rad2pi", "edge_event_id": edge_id, "kind": "final", "person": "test",
                "t": now.isoformat(timespec="milliseconds"),
                "started_at": (now - timedelta(seconds=6)).isoformat(timespec="milliseconds"),
                "ended_at": now.isoformat(timespec="milliseconds"),
                "situation": "통과", "prob": 0.9, "abnormal": False, "photo": False,
                "details": {"reason": "check_cloud.py 테스트 이벤트", "behaviors": [], "track": []},
            }
            status, body, _ = call(base, "POST", "/api/device/events", body=ev,
                                   headers={"X-Device-Key": args.device_key})
            report(status == 200, "POST /api/device/events", f"{status} {short(body)}")
            if status == 200 and token and isinstance(body, dict):
                cid = body.get("id")
                status, got, _ = call(base, "GET", f"/api/events/{cid}", token=token)
                report(status == 200 and isinstance(got, dict) and got.get("reason") == ev["details"]["reason"],
                       f"앱 쪽에서 다시 읽기 /api/events/{cid}", f"{status} {short(got)}")

    # 5. 앱이 부르지만 클라우드에 아직 없는 것 (SPEC 9.0). 실패로 세지 않는다
    if token:
        print("\n5) 아직 없는 경로 (참고, SPEC 9.0)")
        for path in ("/api/status", "/api/settings", "/api/photos/pending", "/ws/live?token=x"):
            status, _, _ = call(base, "GET", path, token=token)
            print(f"  [{'있음' if status not in (404, 405) else '없음'}] GET {path.split('?')[0]}: {status}")

    print(f"\n결과: OK {ok_count}, 실패 {fail_count}")
    return 1 if fail_count else 0


if __name__ == "__main__":
    sys.exit(main())
