#!/usr/bin/env python3
"""Shared MPD protocol client for quickshell.

Used by services/mpd (MpdService) and apps/mpd/tool.py (library UI).
"""

from __future__ import annotations

import hashlib
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

DEFAULT_HOST = os.environ.get("MPD_HOST", "127.0.0.1")
DEFAULT_PORT = int(os.environ.get("MPD_PORT", "6600"))
COVER_CACHE = Path(
    os.environ.get(
        "QS_MPD_COVER_CACHE",
        str(Path.home() / ".config/quickshell/cache/mpd-covers"),
    )
)
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tiff", ".tif", ".avif"}
_MUSIC_DIR: Path | None | bool = False



def dump(obj: Any) -> None:
    json.dump(obj, sys.stdout, separators=(",", ":"), ensure_ascii=False)
    sys.stdout.write("\n")
    sys.stdout.flush()


def fail(msg: str) -> None:
    dump({"ok": False, "error": msg})
    sys.exit(1)


class MpdError(Exception):
    pass


def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


class Mpd:
    def __init__(self, host: str, port: int) -> None:
        self.sock = socket.create_connection((host, port), timeout=5)
        self.sock.settimeout(15)
        self.buf = b""
        self.idling = False
        hello = self._readline()
        if not hello.startswith("OK MPD"):
            raise MpdError(f"unexpected hello: {hello}")

    def close(self) -> None:
        try:
            self._write("close\n")
        except Exception:
            pass
        try:
            self.sock.close()
        except Exception:
            pass

    def _write(self, data: str | bytes) -> None:
        if isinstance(data, str):
            data = data.encode("utf-8")
        self.sock.sendall(data)

    def _read_exact(self, n: int) -> bytes:
        out = bytearray()
        while len(out) < n:
            if self.buf:
                take = min(n - len(out), len(self.buf))
                out.extend(self.buf[:take])
                self.buf = self.buf[take:]
                continue
            chunk = self.sock.recv(max(4096, n - len(out)))
            if not chunk:
                raise MpdError("connection closed")
            self.buf += chunk
        return bytes(out)

    def _readline(self) -> str:
        while True:
            nl = self.buf.find(b"\n")
            if nl >= 0:
                line = self.buf[:nl]
                self.buf = self.buf[nl + 1 :]
                return line.decode("utf-8", errors="replace").rstrip("\r")
            chunk = self.sock.recv(4096)
            if not chunk:
                raise MpdError("connection closed")
            self.buf += chunk

    def command(self, cmd: str) -> list[str]:
        self._write(cmd + "\n")
        lines: list[str] = []
        while True:
            line = self._readline()
            if line.startswith("ACK "):
                raise MpdError(line[4:])
            if line == "OK":
                return lines
            lines.append(line)

    def pairs(self, cmd: str) -> list[tuple[str, str]]:
        out: list[tuple[str, str]] = []
        for line in self.command(cmd):
            if ": " not in line:
                continue
            key, value = line.split(": ", 1)
            out.append((key, value))
        return out

    def begin_idle(self, *subsystems: str) -> None:
        """Enter MPD idle; blocks until finish_idle()/noidle() or an event."""
        self.sock.settimeout(None)
        self.idling = True
        if subsystems:
            self._write("idle " + " ".join(subsystems) + "\n")
        else:
            self._write("idle\n")

    def finish_idle(self) -> list[str]:
        """Read the response after idle wakes or noidle is sent."""
        changed: list[str] = []
        try:
            while True:
                line = self._readline()
                if line.startswith("ACK "):
                    raise MpdError(line[4:])
                if line == "OK":
                    return changed
                if line.startswith("changed: "):
                    changed.append(line.split(": ", 1)[1])
            return changed
        finally:
            self.idling = False
            self.sock.settimeout(15)

    def noidle(self) -> list[str]:
        """Cancel a pending idle and return any changed subsystems."""
        self._write("noidle\n")
        return self.finish_idle()

    def fileno(self) -> int:
        return self.sock.fileno()

    def list_values(self, tag: str, *filters: str) -> list[str]:
        cmd = " ".join(["list", tag, *filters])
        return [v for k, v in self.pairs(cmd) if k == tag and v]

    def count(self, *filters: str) -> dict[str, int]:
        cmd = " ".join(["count", *filters])
        data = {k.lower(): v for k, v in self.pairs(cmd)}
        songs = int(float(data.get("songs", "0") or 0))
        playtime = int(float(data.get("playtime", "0") or 0))
        return {"songs": songs, "playtime": playtime}

    def albumart(self, uri: str) -> bytes | None:
        data = bytearray()
        offset = 0
        total: int | None = None
        while True:
            self._write(f"albumart {quote(uri)} {offset}\n")
            size_line = self._readline()
            if size_line.startswith("ACK "):
                return None if offset == 0 else bytes(data)
            if size_line.startswith("size: "):
                total = int(size_line.split(" ", 1)[1])
                bin_line = self._readline()
            elif size_line.startswith("binary: "):
                bin_line = size_line
            else:
                # Unexpected; drain to OK if possible
                while size_line != "OK" and not size_line.startswith("ACK "):
                    size_line = self._readline()
                return None if offset == 0 else bytes(data)

            if not bin_line.startswith("binary: "):
                raise MpdError(f"expected binary: got {bin_line}")
            chunk_size = int(bin_line.split(" ", 1)[1])
            data.extend(self._read_exact(chunk_size))
            # trailing newline after binary payload is not always present;
            # next response line is OK
            ok = self._readline()
            if ok.startswith("ACK "):
                raise MpdError(ok[4:])
            if ok != "OK":
                # some servers may emit an empty line
                if ok == "":
                    ok = self._readline()
                if ok != "OK":
                    raise MpdError(f"expected OK after albumart, got {ok}")
            offset = len(data)
            if total is not None and offset >= total:
                return bytes(data)
            if chunk_size <= 0:
                return bytes(data) if data else None

    def readpicture(self, uri: str) -> bytes | None:
        """Fetch embedded cover art via MPD readpicture."""
        data = bytearray()
        offset = 0
        total: int | None = None
        while True:
            self._write(f"readpicture {quote(uri)} {offset}\n")
            first = self._readline()
            if first.startswith("ACK "):
                return None if offset == 0 else bytes(data)
            if first == "OK":
                return None if offset == 0 else bytes(data)

            bin_line = ""
            while True:
                if first.startswith("size: "):
                    total = int(first.split(" ", 1)[1])
                elif first.startswith("binary: "):
                    bin_line = first
                    break
                elif first.startswith("type: ") or first.startswith("MIME: "):
                    pass
                elif first == "OK":
                    return None if offset == 0 else bytes(data)
                elif first.startswith("ACK "):
                    return None if offset == 0 else bytes(data)
                first = self._readline()

            chunk_size = int(bin_line.split(" ", 1)[1])
            if chunk_size <= 0:
                ok = self._readline()
                return bytes(data) if data else None
            data.extend(self._read_exact(chunk_size))
            ok = self._readline()
            if ok.startswith("ACK "):
                return bytes(data) if data else None
            if ok != "OK":
                if ok == "":
                    ok = self._readline()
                if ok != "OK":
                    raise MpdError(f"expected OK after readpicture, got {ok}")
            offset = len(data)
            if total is not None and offset >= total:
                return bytes(data)


def music_directory() -> Path | None:
    global _MUSIC_DIR
    if _MUSIC_DIR is not False:
        return _MUSIC_DIR  # type: ignore[return-value]

    env = os.environ.get("MPD_MUSIC_DIRECTORY") or os.environ.get("MPD_MUSIC_DIR")
    if env:
        _MUSIC_DIR = Path(os.path.expanduser(env)).resolve()
        return _MUSIC_DIR

    conf = Path.home() / ".config/mpd/mpd.conf"
    if conf.is_file():
        try:
            for line in conf.read_text(encoding="utf-8", errors="replace").splitlines():
                raw = line.strip()
                if not raw or raw.startswith("#"):
                    continue
                if raw.lower().startswith("music_directory"):
                    parts = raw.split(None, 1)
                    if len(parts) < 2:
                        continue
                    value = parts[1].strip().strip('"').strip("'")
                    _MUSIC_DIR = Path(os.path.expanduser(value)).resolve()
                    return _MUSIC_DIR
        except OSError:
            pass

    fallback = Path.home() / "Music"
    _MUSIC_DIR = fallback.resolve() if fallback.is_dir() else None
    return _MUSIC_DIR


def absolute_track_path(uri: str) -> Path | None:
    root = music_directory()
    if not root:
        return None
    path = (root / uri).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        return None
    return path if path.is_file() else None


def find_folder_image(track_path: Path) -> Path | None:
    """Pick any image file in the track's directory (largest first)."""
    folder = track_path.parent
    if not folder.is_dir():
        return None
    images: list[Path] = []
    try:
        for entry in folder.iterdir():
            if not entry.is_file():
                continue
            if entry.suffix.lower() in IMAGE_EXTS:
                images.append(entry)
    except OSError:
        return None
    if not images:
        return None
    images.sort(key=lambda p: (-p.stat().st_size, p.name.casefold()))
    return images[0]


def extract_embedded_cover(track_path: Path, dest: Path) -> bool:
    """Extract embedded artwork from an audio file into dest."""
    dest.parent.mkdir(parents=True, exist_ok=True)

    # metaflac for FLAC picture blocks
    if track_path.suffix.lower() == ".flac":
        try:
            r = subprocess.run(
                ["metaflac", f"--export-picture-to={dest}", str(track_path)],
                capture_output=True,
                timeout=20,
                check=False,
            )
            if r.returncode == 0 and dest.is_file() and dest.stat().st_size > 0:
                return True
            if dest.exists() and dest.stat().st_size == 0:
                dest.unlink(missing_ok=True)
        except (OSError, subprocess.SubprocessError):
            pass

    # ffmpeg: map first attached/video picture stream if present
    try:
        r = subprocess.run(
            [
                "ffmpeg", "-y", "-i", str(track_path),
                "-an", "-map", "0:v:0", "-c", "copy",
                str(dest),
            ],
            capture_output=True,
            timeout=30,
            check=False,
        )
        if r.returncode == 0 and dest.is_file() and dest.stat().st_size > 0:
            return True
        if dest.exists():
            dest.unlink(missing_ok=True)
    except (OSError, subprocess.SubprocessError):
        pass

    return False


def cover_path_for(key: str) -> Path:
    COVER_CACHE.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:20]
    return COVER_CACHE / f"{digest}.img"


def ensure_cover(mpd: Mpd, uri: str | None) -> str:
    """Resolve cover art for a library URI.

    Order:
      1. any image file in the track's folder
      2. embedded art via MPD readpicture
      3. embedded art extracted from the audio file
      4. MPD albumart (external cover MPD already knows about)
    """
    if not uri:
        return ""

    abs_path = absolute_track_path(uri)

    # 1) Folder image — return the file itself (no copy).
    if abs_path:
        folder_img = find_folder_image(abs_path)
        if folder_img:
            return str(folder_img)

    cache = cover_path_for(uri)
    if cache.exists() and cache.stat().st_size > 0:
        return str(cache)

    # 2) Embedded via MPD
    blob = None
    try:
        blob = mpd.readpicture(uri)
    except MpdError:
        blob = None
    if blob:
        cache.write_bytes(blob)
        return str(cache)

    # 3) Extract from the audio file on disk
    if abs_path and extract_embedded_cover(abs_path, cache):
        return str(cache)

    # 4) MPD albumart database / known external covers
    try:
        blob = mpd.albumart(uri)
    except MpdError:
        blob = None
    if blob:
        cache.write_bytes(blob)
        return str(cache)

    return ""


def parse_format(fmt: str | None) -> dict[str, Any]:
    if not fmt:
        return {}
    parts = str(fmt).split(":")
    out: dict[str, Any] = {"format": fmt}
    try:
        if len(parts) >= 1 and parts[0]:
            out["sampleRate"] = int(parts[0])
        if len(parts) >= 2 and parts[1]:
            out["bits"] = int(parts[1])
        if len(parts) >= 3 and parts[2]:
            out["channels"] = int(parts[2])
    except ValueError:
        pass
    return out


def coerce_number(key: str, value: str) -> Any:
    try:
        if key in ("duration",):
            return float(value)
        if key in ("time", "track", "disc", "bitrate", "pos", "id"):
            return int(float(value))
    except ValueError:
        pass
    return value


TAG_MAP = {
    "Title": "title",
    "Artist": "artist",
    "Album": "album",
    "AlbumArtist": "albumArtist",
    "Date": "date",
    "OriginalDate": "originalDate",
    "Label": "label",
    "Genre": "genre",
    "Format": "format",
    "Time": "time",
    "duration": "duration",
    "Track": "track",
    "Disc": "disc",
    "Composer": "composer",
    "Performer": "performer",
    "Comment": "comment",
    "Pos": "pos",
    "Id": "id",
}


def records_from_pairs(pairs: list[tuple[str, str]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    for key, value in pairs:
        if key == "file":
            if current:
                rows.append(_finalize_track(current))
            current = {"file": value}
            continue
        if current is None:
            continue
        mapped = TAG_MAP.get(key)
        if mapped == "genre":
            genres = current.setdefault("genres", [])
            if value and value not in genres:
                genres.append(value)
        elif mapped in ("time", "duration", "track", "disc", "bitrate", "pos", "id"):
            current[mapped] = coerce_number(mapped, value)
        elif mapped == "format":
            current.update(parse_format(value))
        elif mapped:
            current[mapped] = value
        else:
            # Keep other metadata under extras with original key.
            extras = current.setdefault("extras", {})
            if key in extras:
                prev = extras[key]
                if isinstance(prev, list):
                    prev.append(value)
                else:
                    extras[key] = [prev, value]
            else:
                extras[key] = value
    if current:
        rows.append(_finalize_track(current))
    return rows


def _finalize_track(row: dict[str, Any]) -> dict[str, Any]:
    if "duration" not in row and "time" in row:
        try:
            row["duration"] = float(row["time"])
        except (TypeError, ValueError):
            pass
    return row


def track_sort_key(row: dict[str, Any]) -> tuple:
    def as_int(v: Any) -> int:
        try:
            return int(v)
        except (TypeError, ValueError):
            return 0

    title = str(row.get("title") or row.get("file") or "")
    return (as_int(row.get("disc")), as_int(row.get("track")), title.casefold())


def format_duration(seconds: float | int | None) -> str:
    if seconds is None:
        return "0:00"
    try:
        total = int(float(seconds))
    except (TypeError, ValueError):
        return "0:00"
    if total < 0:
        total = 0
    h = total // 3600
    m = (total % 3600) // 60
    s = total % 60
    if h > 0:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"


def sum_duration(tracks: list[dict[str, Any]]) -> float:
    total = 0.0
    for t in tracks:
        d = t.get("duration", t.get("time", 0))
        try:
            total += float(d or 0)
        except (TypeError, ValueError):
            pass
    return total


def first_track_file(tracks: list[dict[str, Any]]) -> str:
    return str(tracks[0].get("file") or "") if tracks else ""

