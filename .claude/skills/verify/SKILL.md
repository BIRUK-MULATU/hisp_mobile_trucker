---
name: verify
description: How to build, run, and visually verify this Flutter web app headlessly
---

# Verifying hisp_mobile_trucker

## Surface
Flutter app; primary dev target is web on **port 3001** (staging DHIS2 CORS
only allows localhost:3000/3001; 3000 is taken on this machine — see run_web.sh).

## What works headlessly
`flutter run -d web-server` **stalls in headless Chrome** — DDC loads all
modules but main() never fires (DWDS debug bootstrap handshake). Do NOT
burn time on it. Instead:

```bash
flutter build web                          # ~60s
cd build/web && python3 -m http.server 3001 --bind 127.0.0.1 &
```

Then screenshot via CDP (no extension needed). Working probe script from
2026-07-08 session: takes a screenshot after a wait, dumps console events
and DOM state (`flutterView: true` = app booted). Pattern: launch
`google-chrome --headless=new --remote-debugging-port=9224 --window-size=412,915`,
connect to the page's webSocketDebuggerUrl, `Page.navigate`, wait ~20s
(release build), `Page.captureScreenshot`. Interactive flows: `Input.dispatchMouseEvent`
/ `Input.dispatchKeyEvent` over the same CDP socket (Flutter renders to
canvas — no DOM elements to click).

## Landmarks
- Boot lands on the login page (blue, Amharic HMIS title, Username/Password).
- `/#/home` renders the home page with Visualization/Capture toggle —
  **no auth guard on the router** (pre-existing), so screens are reachable
  without logging in.
- Real login needs staging credentials (not stored in repo).

## Gotchas
- `pkill -f`/`pgrep -f` with a pattern that appears in your own command
  line kills your own shell (exit 144). Find the PID with
  `ss -tlnp | grep 3001` and `kill <pid>` instead.
- `flutter run` killed uncleanly can orphan a `dart:flutter_to` child
  still holding port 3001 — check `ss` before assuming the port is free.
- Tests: `flutter test` — the DHIS2 round-trip test self-skips without a
  reachable server; that's normal.
