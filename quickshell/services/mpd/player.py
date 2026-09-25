#!/usr/bin/env python3
"""MPD playback snapshot + controls (command socket only)."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .client import Mpd, MpdError, absolute_track_path, ensure_cover, records_from_pairs

ACTIONS = frozenset({
    "play", "pause", "toggle", "next", "previous",
    "seek", "volume", "shuffle", "loop", "refresh",
})


def status_map(mpd: Mpd) -> dict[str, str]:
    return {k.lower(): v for k, v in mpd.pairs("status")}


def _f(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _cover_url(path: str) -> str:
    if not path:
        return ""
    return path if path.startswith("file://") else "file://" + path


def _cover(mpd: Mpd, uri: str, cache: dict[str, str] | None) -> str:
    if not uri:
        return ""
    if cache is not None and cache.get("file") == uri:
        return cache.get("cover") or ""
    try:
        cover = _cover_url(ensure_cover(mpd, uri))
    except Exception:
        cover = ""
    if cache is not None:
        cache.clear()
        cache.update(file=uri, cover=cover)
    return cover


def snapshot(mpd: Mpd, cover_cache: dict[str, str] | None = None) -> dict[str, Any]:
    status = status_map(mpd)
    tracks = records_from_pairs(mpd.pairs("currentsong"))
    track = tracks[0] if tracks else {}
    uri = str(track.get("file") or "")
    abs_path = absolute_track_path(uri) if uri else None
    state = str(status.get("state") or "stop")
    length = int(_f(status.get("playlistlength")))
    title = str(track.get("title") or "") or (Path(uri).stem if uri else "")
    single = str(status.get("single", "0")) == "1"
    repeat = str(status.get("repeat", "0")) == "1"
    loop = "one" if single else ("playlist" if repeat else "off")

    return {
        "ok": True,
        "connected": True,
        "active": bool(uri) or state in ("play", "pause") or length > 0,
        "state": state,
        "isPlaying": state == "play",
        "file": uri,
        "path": str(abs_path) if abs_path else "",
        "title": title,
        "artist": str(track.get("artist") or ""),
        "album": str(track.get("album") or ""),
        "cover": _cover(mpd, uri, cover_cache),
        "position": _f(status.get("elapsed")),
        "duration": _f(status.get("duration") or track.get("duration") or track.get("time")),
        "volume": max(0.0, min(1.0, _f(status.get("volume")) / 100.0)),
        "shuffle": str(status.get("random", "0")) == "1",
        "loopMode": loop,
        "playlistlength": length,
        "canNext": length > 1 or (length == 1 and state != "stop"),
        "canPrevious": length > 0,
    }


def apply(mpd: Mpd, action: str, arg: str | None = None) -> None:
    action = (action or "").strip().lower()

    def resume() -> None:
        try:
            mpd.command("pause 0")
        except MpdError:
            mpd.command("play")

    if action == "play":
        resume()
    elif action == "pause":
        mpd.command("pause 1")
    elif action == "toggle":
        if str(status_map(mpd).get("state") or "") == "play":
            mpd.command("pause 1")
        else:
            resume()
    elif action == "next":
        mpd.command("next")
    elif action == "previous":
        mpd.command("previous")
    elif action == "seek":
        mpd.command(f"seekcur {float(arg)}")
    elif action == "volume":
        mpd.command(f"setvol {int(round(max(0.0, min(1.0, float(arg))) * 100))}")
    elif action == "shuffle":
        mpd.command(f"random {1 if str(arg).lower() in ('1', 'on', 'true') else 0}")
    elif action == "loop":
        mode = (arg or "off").lower()
        if mode in ("one", "track", "single"):
            mpd.command("repeat 1")
            mpd.command("single 1")
        elif mode in ("playlist", "all", "on"):
            mpd.command("repeat 1")
            mpd.command("single 0")
        else:
            mpd.command("repeat 0")
            mpd.command("single 0")
    elif action != "refresh":
        raise ValueError(f"unknown action: {action}")


def parse_line(line: str) -> tuple[str, str | None] | None:
    parts = line.strip().split(None, 1)
    if not parts or parts[0].lower() not in ACTIONS:
        return None
    action = parts[0].lower()
    arg = parts[1] if len(parts) > 1 else None
    if action in ("seek", "volume", "shuffle", "loop") and arg is None:
        return None
    return action, arg
