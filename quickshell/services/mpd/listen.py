#!/usr/bin/env python3
"""MPD listener — watches for changes and updates the UI.

One MPD connection: idle until notified, then read status and emit a
snapshot on stdout. Never handles playback controls.
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

_SERVICES = Path(__file__).resolve().parents[1]
if str(_SERVICES) not in sys.path:
    sys.path.insert(0, str(_SERVICES))

from mpd.client import DEFAULT_HOST, DEFAULT_PORT, Mpd, MpdError, dump  # noqa: E402
from mpd import player  # noqa: E402

SUBSYSTEMS = ("player", "mixer", "options", "playlist")


def main() -> None:
    parser = argparse.ArgumentParser(description="MPD idle listener")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    args = parser.parse_args()

    covers: dict[str, str] = {}

    while True:
        mpd = None
        try:
            mpd = Mpd(args.host, args.port)
            dump(player.snapshot(mpd, covers))

            while True:
                mpd.begin_idle(*SUBSYSTEMS)
                mpd.finish_idle()
                dump(player.snapshot(mpd, covers))

        except (OSError, MpdError) as e:
            dump({
                "ok": False,
                "connected": False,
                "active": False,
                "isPlaying": False,
                "error": str(e),
            })
            time.sleep(1.5)
        finally:
            if mpd is not None:
                try:
                    mpd.close()
                except Exception:
                    pass


if __name__ == "__main__":
    main()
