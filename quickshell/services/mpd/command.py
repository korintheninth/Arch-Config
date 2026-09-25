#!/usr/bin/env python3
"""MPD command process — send controls only.

One long-lived MPD connection. Reads actions from stdin and applies them.
Watches the socket with select; when MPD closes it, reconnects immediately.
Never calls MPD idle. Never emits UI snapshots.
"""

from __future__ import annotations

import argparse
import select
import sys
import time
from pathlib import Path

_SERVICES = Path(__file__).resolve().parents[1]
if str(_SERVICES) not in sys.path:
    sys.path.insert(0, str(_SERVICES))

from mpd.client import DEFAULT_HOST, DEFAULT_PORT, Mpd, MpdError, dump  # noqa: E402
from mpd import player  # noqa: E402


def dead(mpd: Mpd) -> bool:
    """True if the server closed the socket (or sent unexpected data)."""
    try:
        chunk = mpd.sock.recv(4096)
    except OSError:
        return True
    return not chunk  # b"" => closed; any data => desynced, reconnect


def main() -> None:
    parser = argparse.ArgumentParser(description="MPD command process")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    args = parser.parse_args()
    stdin_fd = sys.stdin.fileno()

    while True:
        mpd = None
        try:
            mpd = Mpd(args.host, args.port)
        except (OSError, MpdError) as e:
            dump({"ok": False, "error": str(e)})
            time.sleep(1.5)
            continue

        try:
            while True:
                ready, _, _ = select.select([stdin_fd, mpd.fileno()], [], [])

                if mpd.fileno() in ready and dead(mpd):
                    break  # reconnect immediately

                if stdin_fd not in ready:
                    continue

                line = sys.stdin.readline()
                if line == "":
                    return

                parsed = player.parse_line(line)
                if not parsed:
                    continue
                action, arg = parsed
                if action == "refresh":
                    continue
                try:
                    player.apply(mpd, action, arg)
                except MpdError as e:
                    if "connection closed" in str(e).lower():
                        break
                except OSError:
                    break
        finally:
            if mpd is not None:
                try:
                    mpd.close()
                except Exception:
                    pass


if __name__ == "__main__":
    main()
