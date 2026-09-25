#!/usr/bin/env python3
"""Backend CLI for the quickshell wallpaper gallery.

Every subcommand prints one JSON object to stdout (`thumbs` prints one per
line). Errors are reported as {"ok": false, "error": "..."}.
"""

import argparse
import hashlib
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff", ".avif", ".jxl", ".svg"}
GIF_EXT = {".gif"}
VIDEO_EXT = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}
MEDIA_EXT = IMAGE_EXT | GIF_EXT | VIDEO_EXT
SKIP_DIRS = {".git", ".cache", "__pycache__", "node_modules"}

CACHE = Path.home() / ".cache" / "quickshell" / "wallpaper-gallery"
THUMB_DIR = CACHE / "thumbs"
PREVIEW_DIR = CACHE / "preview"
APPLY_DIR = CACHE / "applied"
MPV_SOCK = CACHE / "mpvpaper.sock"
WALLPAPER_SH = Path.home() / ".config" / "hypr" / "scripts" / "wallpaper.sh"
WALLUST_TOML = Path.home() / ".config" / "wallust" / "wallust.toml"

TINTS = {
    "red": "#c04040",
    "blue": "#5080c0",
    "green": "#40a060",
    "amber": "#c0a040",
    "pink": "#c06090",
}

AWWW_TYPES = [
    "none", "simple", "fade", "left", "right", "top", "bottom",
    "wipe", "wave", "grow", "center", "any", "outer", "random",
]
AWWW_POS = [
    "center", "top", "left", "right", "bottom",
    "top-left", "top-right", "bottom-left", "bottom-right",
]
AWWW_BEZIERS = {
    "default": ".54,0,.34,.99",
    "linear": "0.0,0.0,1.0,1.0",
    "ease": ".25,.1,.25,1",
}

WALLUST_BACKENDS = ["full", "resized", "wal", "thumb", "fastresize", "kmeans"]
WALLUST_COLOR_SPACES = ["lab", "labmixed", "lch", "lchmixed"]
WALLUST_FALLBACKS = ["interpolation", "complementary"]
WALLUST_PALETTES = [
    "dark", "dark16", "darkcomp", "darkcomp16", "light", "light16", "lightcomp", "lightcomp16",
    "harddark", "harddark16", "harddarkcomp", "harddarkcomp16", "softdark", "softdark16",
    "softdarkcomp", "softdarkcomp16", "softlight", "softlight16", "softlightcomp", "softlightcomp16",
]


# ---------- helpers ----------

def dump(obj) -> None:
    json.dump(obj, sys.stdout, separators=(",", ":"), ensure_ascii=False)
    sys.stdout.write("\n")
    sys.stdout.flush()


def fail(msg: str) -> None:
    dump({"ok": False, "error": msg})
    sys.exit(1)


def run(cmd, **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=False, **kwargs)


def run_or_raise(cmd, fallback: str, expect: Path | None = None) -> None:
    """Run a command quietly; raise RuntimeError with the last stderr line on failure."""
    result = run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0 or (expect is not None and not expect.exists()):
        lines = (result.stderr or "").strip().splitlines()
        raise RuntimeError(lines[-1] if lines else fallback)


def kind_of(path: Path) -> str:
    ext = path.suffix.lower()
    if ext in VIDEO_EXT:
        return "video"
    if ext in GIF_EXT:
        return "gif"
    return "image"


def cache_name(src: str, suffix: str) -> str:
    return hashlib.sha1(src.encode()).hexdigest()[:16] + suffix


def process_running(name: str) -> bool:
    return run(["pgrep", "-x", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def wait_gone(name: str, timeout: float = 1.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline and process_running(name):
        time.sleep(0.05)


# ---------- indexing ----------

def index_root(root: Path) -> dict:
    root = root.expanduser().resolve()
    folders: dict[str, dict] = {}
    files: list[dict] = []

    def folder(rel: str) -> dict:
        if rel not in folders:
            parts = Path(rel).parts if rel else ()
            parent = None if not rel else "/".join(parts[:-1])
            folders[rel] = {
                "id": rel,
                "name": parts[-1] if parts else root.name,
                "rel": rel,
                "path": str(root / rel) if rel else str(root),
                "parent": parent,
                "depth": len(parts),
                "count": 0,
                "total": 0,
            }
            if parent is not None:
                folder(parent)
        return folders[rel]

    folder("")
    seen = set()
    for dirpath, dirnames, filenames in os.walk(root, followlinks=True):
        real = os.path.realpath(dirpath)
        if real in seen:  # symlink loop protection
            dirnames[:] = []
            continue
        seen.add(real)
        dirnames[:] = sorted(
            d for d in dirnames
            if not d.startswith(".") and d not in SKIP_DIRS
            and os.path.realpath(os.path.join(dirpath, d)) not in seen
        )
        rel_dir = os.path.relpath(dirpath, root)
        folder_id = "" if rel_dir == "." else rel_dir.replace("\\", "/")
        folder(folder_id)
        for name in sorted(filenames):
            path = Path(dirpath) / name
            if name.startswith(".") or path.suffix.lower() not in MEDIA_EXT:
                continue
            files.append({
                "name": name,
                "path": str(path),
                "rel": str(path.relative_to(root)).replace("\\", "/"),
                "folder": folder_id,
                "kind": kind_of(path),
                "ext": path.suffix.lower(),
            })
            folders[folder_id]["count"] += 1

    for f in files:  # recursive totals via the ancestor chain
        rel = f["folder"]
        while rel is not None:
            folders[rel]["total"] += 1
            rel = folders[rel]["parent"]

    return {
        "ok": True,
        "root": str(root),
        "folders": sorted((f for f in folders.values() if f["total"] > 0), key=lambda f: f["id"].lower()),
        "files": files,
        "count": len(files),
    }


def cmd_index(args) -> None:
    root = Path(args.root).expanduser()
    if not root.is_dir():
        fail(f"wallpaper folder not found: {root}")
    dump(index_root(root))


# ---------- filters ----------

def filters_active(args) -> bool:
    return bool(
        int(args.colors) > 0
        or int(args.sat) != 100
        or int(args.bri) != 100
        or int(args.con) != 100
        or int(args.hue) != 0
        or args.gray
        or args.bw
        or args.invert
        or args.sepia
        or args.dither
        or (args.tint != "none" and float(args.tint_amount) > 0)
    )


def tint_channel_factors(color: str, amount: float) -> tuple[float, float, float]:
    mix = max(0.0, min(1.0, float(amount) / 100.0))
    h = color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return tuple(1.0 - mix + mix * (c / 255.0) for c in (r, g, b))


def magick_filters(src: str, dest: str, args, resize: str | None = None,
                   first_frame: bool = False, resize_after: bool = False) -> None:
    cmd = ["magick", f"{src}[0]" if first_frame else src]
    if first_frame or src.lower().endswith(".gif"):
        cmd += ["-coalesce"]
    if resize and not resize_after:
        cmd += ["-resize", resize]
    if args.invert:
        cmd += ["-negate"]
    if args.sepia:
        cmd += ["-sepia-tone", "80%"]
    sat = 0 if args.gray else args.sat
    hue = 100.0 + float(args.hue) / 1.8  # modulate maps 0..200 onto -180..180 degrees
    cmd += ["-modulate", f"{args.bri},{sat},{hue:.2f}"]
    if int(args.con) != 100:
        cmd += ["-brightness-contrast", f"0x{int(args.con) - 100}"]
    colors = int(args.colors)
    if colors > 0:
        cmd += ["-dither", "FloydSteinberg" if args.dither else "None", "-colors", str(colors)]
    elif args.dither:
        cmd += ["-ordered-dither", "o8x8,16"]
    if args.gray and not args.bw:
        cmd += ["-grayscale", "Rec709Luminance"]
    if resize and resize_after:
        cmd += ["-resize", resize]
    if args.bw:
        # Hard 1-bit after resize so a later scale cannot reintroduce gray.
        cmd += ["-colorspace", "Gray", "-threshold", "50%", "-type", "TrueColor"]
    if args.tint != "none" and float(args.tint_amount) > 0:
        rf, gf, bf = tint_channel_factors(TINTS.get(args.tint, args.tint), args.tint_amount)
        # Gray/1-bit images have no independent R/G/B; promote first or multiply is a no-op.
        cmd += [
            "-colorspace", "sRGB",
            "-type", "TrueColor",
            "-channel", "R", "-evaluate", "multiply", f"{rf:.6f}",
            "-channel", "G", "-evaluate", "multiply", f"{gf:.6f}",
            "-channel", "B", "-evaluate", "multiply", f"{bf:.6f}",
            "+channel",
        ]
    run_or_raise(cmd + [dest], "magick failed")


def mpv_vf(args) -> str:
    """Build an mpv/ffmpeg video filter chain approximating the magick filters."""
    parts = []
    if args.invert:
        parts.append("negate")
    if args.sepia and not args.gray:
        parts.append(
            "colorchannelmixer=rr=0.393:rg=0.769:rb=0.189:gr=0.349:gg=0.686:gb=0.168:br=0.272:bg=0.534:bb=0.131"
        )
    bri = int(args.bri) / 100.0 - 1.0
    con = int(args.con) / 100.0
    sat = 0.0 if args.gray else int(args.sat) / 100.0
    eq = []
    if abs(bri) > 0.001:
        eq.append(f"brightness={bri:.3f}")
    if abs(con - 1.0) > 0.001:
        eq.append(f"contrast={con:.3f}")
    if abs(sat - 1.0) > 0.001:
        eq.append(f"saturation={sat:.3f}")
    if eq:
        parts.append("eq=" + ":".join(eq))
    if int(args.hue) != 0 and not args.gray:
        parts.append(f"hue=h={int(args.hue)}")
    if args.dither:
        parts.append("noise=alls=14:allf=t")
    colors = int(args.colors)
    if colors > 1:
        step = max(1, 256 // colors)
        parts.append(
            "format=rgb24,"
            f"geq=r='floor(r(X,Y)/{step})*{step}':"
            f"g='floor(g(X,Y)/{step})*{step}':"
            f"b='floor(b(X,Y)/{step})*{step}'"
        )
    if args.gray and not args.bw:
        parts.append("hue=s=0")
    if args.bw:
        parts.append("format=gray,lutyuv=y='if(gte(val,128),255,0)':u=128:v=128")
    if args.tint != "none" and float(args.tint_amount) > 0:
        rf, gf, bf = tint_channel_factors(TINTS.get(args.tint, args.tint), args.tint_amount)
        parts.append(
            "format=rgb24,"
            f"geq=r='r(X,Y)*{rf:.6f}':"
            f"g='g(X,Y)*{gf:.6f}':"
            f"b='b(X,Y)*{bf:.6f}'"
        )
    return ",".join(parts)


# ---------- frame extraction and rendering ----------

def extract_frame(src: str, dest: str) -> None:
    dest_path = Path(dest)
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    if Path(src).suffix.lower() in VIDEO_EXT:
        run_or_raise(
            ["ffmpeg", "-y", "-i", src, "-frames:v", "1", "-q:v", "3", str(dest_path)],
            "ffmpeg could not extract a frame", expect=dest_path,
        )
    else:
        run_or_raise(["magick", f"{src}[0]", str(dest_path)], "could not read image frame", expect=dest_path)


def ffmpeg_filtered_frame(src: str, dest: str, vf: str, scale: str = "960:540") -> None:
    filters = [f for f in (f"scale={scale}:force_original_aspect_ratio=decrease", vf) if f]
    run_or_raise(
        ["ffmpeg", "-y", "-i", src, "-frames:v", "1", "-vf", ",".join(filters), "-q:v", "3", dest],
        "ffmpeg preview failed", expect=Path(dest),
    )


def ffmpeg_filtered_video(src: str, dest: str, vf: str) -> None:
    dest_path = Path(dest)
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    vf_arg = f"{vf},format=yuv420p" if vf else "format=yuv420p"
    base = ["ffmpeg", "-y", "-i", src, "-vf", vf_arg,
            "-c:v", "libx264", "-preset", "fast", "-crf", "18", "-pix_fmt", "yuv420p"]
    last_err = "ffmpeg video failed"
    for audio in (["-c:a", "copy"], ["-c:a", "aac"]):  # audio copy fails for some containers
        try:
            run_or_raise(base + audio + [str(dest_path)], last_err, expect=dest_path)
            return
        except RuntimeError as e:
            last_err = str(e)
    raise RuntimeError(last_err)


# ---------- thumbs ----------

def make_thumb(src: str) -> dict:
    src_path = Path(src).expanduser()
    if not src_path.exists():
        return {"ok": False, "src": src, "error": f"missing file: {src}"}
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    dest = THUMB_DIR / cache_name(str(src_path), ".jpg")
    if dest.exists() and dest.stat().st_mtime >= src_path.stat().st_mtime:
        return {"ok": True, "src": str(src_path), "path": str(dest)}
    tmp = dest.with_suffix(".frame.png") if kind_of(src_path) == "video" else None
    try:
        if tmp:
            extract_frame(str(src_path), str(tmp))
        magick_src = str(tmp) if tmp else f"{src_path}[0]"
        run_or_raise(
            ["magick", magick_src, "-thumbnail", "320x180>", "-quality", "75", str(dest)],
            "thumb failed", expect=dest,
        )
        return {"ok": True, "src": str(src_path), "path": str(dest)}
    except RuntimeError as e:
        return {"ok": False, "src": str(src_path), "error": str(e)}
    finally:
        if tmp:
            tmp.unlink(missing_ok=True)


def cmd_thumbs(args) -> None:
    from concurrent.futures import ThreadPoolExecutor, as_completed

    with ThreadPoolExecutor(max_workers=min(6, len(args.inputs))) as pool:
        for fut in as_completed(pool.submit(make_thumb, p) for p in args.inputs):
            dump(fut.result())


# ---------- preview ----------

def prune_previews(keep: Path | None = None) -> None:
    keep_resolved = keep.resolve() if keep else None
    for old in PREVIEW_DIR.iterdir():
        if old.name.startswith("srcframe-") or (keep_resolved and old.resolve() == keep_resolved):
            continue
        try:
            old.unlink()
        except OSError:
            pass


def video_source_frame(src: Path) -> Path:
    frame = PREVIEW_DIR / f"srcframe-{hashlib.sha1(str(src.resolve()).encode()).hexdigest()[:16]}.png"
    if not frame.exists() or frame.stat().st_mtime < src.stat().st_mtime:
        extract_frame(str(src), str(frame))
    return frame


def cmd_preview(args) -> None:
    src = Path(args.input).expanduser()
    if not src.exists():
        fail(f"missing file: {src}")
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    kind = kind_of(src)

    if not filters_active(args):
        if kind in ("gif", "video"):  # play the original directly, no preview file needed
            dump({"ok": True, "path": "", "kind": kind, "play": True})
            return
        dest = PREVIEW_DIR / f"preview-{time.time_ns()}.png"
        run(["magick", f"{src}[0]", "-resize", "960x540>", str(dest)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        prune_previews(dest)
        dump({"ok": True, "path": str(dest), "kind": kind})
        return

    try:
        if kind == "gif":
            dest = PREVIEW_DIR / f"preview-{time.time_ns()}.gif"
            magick_filters(str(src), str(dest), args, resize="480x270>", resize_after=True)
            prune_previews(dest)
            dump({"ok": True, "path": str(dest), "kind": kind, "play": True})
            return
        dest = PREVIEW_DIR / f"preview-{time.time_ns()}.png"
        if kind == "video":
            if resolve_manager(args, kind) == "mpvpaper":
                ffmpeg_filtered_frame(str(src), str(dest), mpv_vf(args))
            else:
                magick_filters(str(video_source_frame(src)), str(dest), args,
                               resize="960x540>", resize_after=True)
        else:
            magick_filters(str(src), str(dest), args,
                           resize="960x540>", first_frame=True, resize_after=True)
        prune_previews(dest)
        dump({"ok": True, "path": str(dest), "kind": kind})
    except RuntimeError as e:
        fail(str(e))


# ---------- wallpaper managers ----------

def resolve_manager(args, kind: str) -> str:
    manager = getattr(args, "manager", "auto") or "auto"
    if manager == "auto":
        return "mpvpaper" if kind == "video" else "awww"
    return manager


def stop_mpvpaper() -> None:
    run(["pkill", "-x", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    wait_gone("mpvpaper")


def stop_awww() -> None:
    run(["awww", "kill"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    run(["pkill", "-x", "awww-daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    wait_gone("awww-daemon")


def start_awww_daemon() -> None:
    if process_running("awww-daemon"):
        return
    subprocess.Popen(["awww-daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    deadline = time.time() + 1.5
    while time.time() < deadline:
        if process_running("awww-daemon"):
            time.sleep(0.1)
            return
        time.sleep(0.05)
    time.sleep(0.2)


def awww_settings_from_args(args) -> dict:
    return {
        "transition": args.transition if args.transition in AWWW_TYPES else "simple",
        "pos": args.transition_pos if args.transition_pos in AWWW_POS else "center",
        "bezier": AWWW_BEZIERS.get(args.transition_bezier, AWWW_BEZIERS["default"]),
        "step": int(args.transition_step),
        "duration": int(args.transition_duration),
        "fps": int(args.transition_fps),
        "angle": int(args.transition_angle),
        "wave": int(args.transition_wave),
    }


def set_awww(path: str, cfg: dict) -> None:
    stop_mpvpaper()
    start_awww_daemon()
    run_or_raise([
        "awww", "img", "--resize", "crop",
        "--transition-type", cfg["transition"],
        "--transition-step", str(cfg["step"]),
        "--transition-duration", str(cfg["duration"]),
        "--transition-fps", str(cfg["fps"]),
        "--transition-angle", str(cfg["angle"]),
        "--transition-pos", cfg["pos"],
        "--transition-bezier", cfg["bezier"],
        "--transition-wave", f'{cfg["wave"]},{cfg["wave"]}',
        path,
    ], "awww failed")


def set_mpvpaper(path: str, vf: str, volume: int, mute: bool) -> None:
    stop_mpvpaper()
    stop_awww()
    MPV_SOCK.unlink(missing_ok=True)
    CACHE.mkdir(parents=True, exist_ok=True)
    opts = f"loop panscan=1.0 volume={int(volume)} mute={'yes' if mute else 'no'} input-ipc-server={MPV_SOCK}"
    if vf:
        opts += f" vf={vf}"
    subprocess.Popen(["mpvpaper", "-f", "-o", opts, "*", path],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def theme_wallpaper(path: str) -> None:
    if WALLPAPER_SH.exists():
        subprocess.Popen(["bash", str(WALLPAPER_SH), path],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ---------- apply / save ----------

def cmd_apply(args) -> None:
    src = Path(args.input).expanduser()
    if not src.exists():
        fail(f"missing file: {src}")
    APPLY_DIR.mkdir(parents=True, exist_ok=True)
    kind = kind_of(src)
    manager = resolve_manager(args, kind)
    filtered = filters_active(args)
    try:
        display = theme = str(src)
        if kind == "video":
            if manager == "awww":
                display = str(APPLY_DIR / "video-still.png")
                extract_frame(str(src), display)
                if filtered:
                    magick_filters(display, display, args)
                    theme = display
            elif filtered:  # mpvpaper plays the source; theme from a filtered frame
                theme = str(APPLY_DIR / "theme.png")
                extract_frame(str(src), theme)
                magick_filters(theme, theme, args)
        elif filtered:
            ext = ".gif" if kind == "gif" else (src.suffix.lower() or ".png")
            display = theme = str(APPLY_DIR / f"wallpaper{ext}")
            magick_filters(str(src), display, args)

        if manager == "mpvpaper":
            vf = mpv_vf(args) if kind == "video" and filtered else ""
            source = str(src) if kind == "video" else display
            set_mpvpaper(source, vf, int(args.volume), bool(int(args.mute)))
        else:
            set_awww(display, awww_settings_from_args(args))
        theme_wallpaper(theme)
        dump({"ok": True, "path": str(src), "display": display, "manager": manager, "kind": kind})
    except RuntimeError as e:
        fail(str(e))


def filter_name_tag(args) -> str:
    parts = [flag for flag in ("gray", "bw", "invert", "sepia", "dither") if getattr(args, flag)]
    for tag, value, default in (
        ("c", int(args.colors), 0),
        ("sat", int(args.sat), 100),
        ("bri", int(args.bri), 100),
        ("con", int(args.con), 100),
        ("hue", int(args.hue), 0),
    ):
        if value != default:
            parts.append(f"{tag}{value}")
    if args.tint != "none" and float(args.tint_amount) > 0:
        parts.append(f"tint{args.tint}{int(args.tint_amount)}")
    return "_".join(parts) or "filters"


def unique_path(path: Path) -> Path:
    i = 2
    candidate = path
    while candidate.exists():
        candidate = path.with_name(f"{path.stem}_{i}{path.suffix}")
        i += 1
    return candidate


def cmd_save(args) -> None:
    src = Path(args.input).expanduser()
    if not src.exists():
        fail(f"missing file: {src}")
    if not filters_active(args):
        fail("no filters to save")
    kind = kind_of(src)
    ext = src.suffix.lower() or ".png"
    if kind == "video" and ext == ".webm":
        ext = ".mp4"
    dest = unique_path(src.with_name(f"{src.stem}_{filter_name_tag(args)}{ext}"))
    try:
        if kind == "video":
            ffmpeg_filtered_video(str(src), str(dest), mpv_vf(args))
        else:
            magick_filters(str(src), str(dest), args)
        dump({"ok": True, "path": str(dest), "kind": kind})
    except RuntimeError as e:
        fail(str(e))


# ---------- mpv ipc ----------

def mpv_send(command: list):
    if not MPV_SOCK.exists():
        raise RuntimeError("mpvpaper is not running")
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(0.4)
    try:
        sock.connect(str(MPV_SOCK))
        sock.sendall((json.dumps({"command": command}) + "\n").encode())
        buf = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buf += chunk
            if b"\n" in buf:
                return json.loads(buf.split(b"\n", 1)[0].decode())
    except OSError as e:
        raise RuntimeError(f"mpv ipc failed: {e}") from e
    finally:
        sock.close()
    raise RuntimeError("mpv ipc returned nothing")


def mpv_get(prop: str):
    return (mpv_send(["get_property", prop]) or {}).get("data")


def cmd_ipc(args) -> None:
    if args.action == "status":
        if not process_running("mpvpaper"):
            dump({"ok": True, "running": False})
            return
        try:
            dump({
                "ok": True,
                "running": True,
                "pause": bool(mpv_get("pause")),
                "mute": bool(mpv_get("mute")),
                "volume": int(round(float(mpv_get("volume") or 50))),
            })
        except RuntimeError:
            dump({"ok": True, "running": True, "pause": False, "mute": True, "volume": 50})
        return
    try:
        if args.action == "toggle":
            mpv_send(["cycle", "pause"])
        elif args.action == "cycle-mute":
            mpv_send(["cycle", "mute"])
        elif args.action == "volume":
            mpv_send(["set_property", "volume", int(args.value or 50)])
        elif args.action == "seek":
            mpv_send(["seek", float(args.value or 0), "relative"])
        elif args.action == "restart":
            mpv_send(["seek", 0, "absolute"])
        dump({"ok": True})
    except RuntimeError as e:
        fail(str(e))


# ---------- wallust config ----------

def wallust_defaults() -> dict:
    return {
        "backend": "wal",
        "color_space": "lch",
        "palette": "dark",
        "fallback_generator": "interpolation",
        "check_contrast": False,
        "saturation": None,
        "saturation_hint": 50,
        "threshold": None,
        "threshold_hint": 0,
    }


def wallust_parse_key_line(line: str):
    """Parse `key = value` (possibly commented out); returns (key, commented, value) or None."""
    body = line.strip()
    if not body or body.startswith("["):
        return None
    commented = body.startswith("#")
    if commented:
        body = body[1:].strip()
    if "=" not in body:
        return None
    key, value = body.split("=", 1)
    key = key.strip()
    if not key:
        return None
    return key, commented, value.strip().strip('"').strip("'")


def wallust_split(content: str) -> tuple[str, str]:
    """Split the toml into (global section, everything from the first table on)."""
    parts = content.splitlines(keepends=True)
    idx = next((i for i, line in enumerate(parts) if line.lstrip().startswith("[")), len(parts))
    return "".join(parts[:idx]), "".join(parts[idx:])


def parse_wallust_settings(content: str) -> dict:
    settings = wallust_defaults()
    for line in wallust_split(content)[0].splitlines():
        parsed = wallust_parse_key_line(line)
        if not parsed:
            continue
        key, commented, value = parsed
        if key in ("backend", "color_space", "palette", "fallback_generator"):
            if not commented:
                settings[key] = value
        elif key == "check_contrast":
            if not commented:
                settings[key] = value.lower() in ("true", "1", "yes")
        elif key in ("saturation", "threshold"):
            try:
                num = int(value)
            except ValueError:
                continue
            settings[f"{key}_hint"] = num
            settings[key] = None if commented else num
    return settings


def wallust_upsert(lines: list[str], key: str, new_line: str) -> None:
    for i, line in enumerate(lines):
        parsed = wallust_parse_key_line(line)
        if parsed and parsed[0] == key:
            lines[i] = new_line
            return
    lines.append(new_line)


def wallust_remove(lines: list[str], key: str) -> None:
    lines[:] = [l for l in lines if not ((p := wallust_parse_key_line(l)) and p[0] == key)]


def apply_wallust_settings(content: str, s: dict) -> str:
    global_text, rest = wallust_split(content)
    lines = global_text.splitlines()
    wallust_upsert(lines, "backend", f'backend = "{s["backend"]}"')
    wallust_upsert(lines, "color_space", f'color_space = "{s["color_space"]}"')
    wallust_upsert(lines, "palette", f'palette = "{s["palette"]}"')
    if s["fallback_generator"] == "interpolation":  # wallust default; keep the file minimal
        wallust_remove(lines, "fallback_generator")
    else:
        wallust_upsert(lines, "fallback_generator", f'fallback_generator = "{s["fallback_generator"]}"')
    wallust_upsert(lines, "check_contrast", f'check_contrast = {str(bool(s["check_contrast"])).lower()}')
    for key in ("saturation", "threshold"):
        if s[key] is None:  # keep the last value around, commented out
            wallust_upsert(lines, key, f'#{key} = {s[f"{key}_hint"]}')
        else:
            wallust_upsert(lines, key, f'{key} = {int(s[key])}')
    out = "\n".join(lines)
    if out and not out.endswith("\n"):
        out += "\n"
    return out + rest


def cmd_wallust_get(_args) -> None:
    if not WALLUST_TOML.exists():
        fail(f"missing file: {WALLUST_TOML}")
    dump({"ok": True, "path": str(WALLUST_TOML), **parse_wallust_settings(WALLUST_TOML.read_text())})


def cmd_wallust_set(args) -> None:
    if not WALLUST_TOML.exists():
        fail(f"missing file: {WALLUST_TOML}")
    content = WALLUST_TOML.read_text()
    settings = parse_wallust_settings(content)
    settings.update(
        backend=args.backend,
        color_space=args.color_space,
        palette=args.palette,
        fallback_generator=args.fallback_generator,
        check_contrast=bool(args.check_contrast),
        saturation=int(args.saturation) if args.saturation_on else None,
        saturation_hint=int(args.saturation),
        threshold=int(args.threshold) if args.threshold_on else None,
        threshold_hint=int(args.threshold),
    )
    tmp = WALLUST_TOML.with_name(WALLUST_TOML.name + ".tmp")
    tmp.write_text(apply_wallust_settings(content, settings))
    tmp.replace(WALLUST_TOML)
    dump({"ok": True, "path": str(WALLUST_TOML), **settings})


# ---------- cli ----------

def add_filter_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--colors", type=int, default=0)
    p.add_argument("--sat", type=int, default=100)
    p.add_argument("--bri", type=int, default=100)
    p.add_argument("--con", type=int, default=100)
    p.add_argument("--hue", type=int, default=0)
    p.add_argument("--gray", action="store_true")
    p.add_argument("--bw", action="store_true")
    p.add_argument("--invert", action="store_true")
    p.add_argument("--sepia", action="store_true")
    p.add_argument("--dither", action="store_true")
    p.add_argument("--tint", default="none")
    p.add_argument("--tint-amount", type=float, default=0)


def add_awww_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--transition", default="simple", choices=AWWW_TYPES)
    p.add_argument("--transition-step", type=int, default=90)
    p.add_argument("--transition-duration", type=int, default=3)
    p.add_argument("--transition-fps", type=int, default=30)
    p.add_argument("--transition-angle", type=int, default=45)
    p.add_argument("--transition-pos", default="center", choices=AWWW_POS)
    p.add_argument("--transition-bezier", default="default", choices=list(AWWW_BEZIERS))
    p.add_argument("--transition-wave", type=int, default=20)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("index")
    p.add_argument("root", nargs="?", default=str(Path.home() / "wallpapers"))
    p.set_defaults(func=cmd_index)

    p = sub.add_parser("thumbs")
    p.add_argument("inputs", nargs="+")
    p.set_defaults(func=cmd_thumbs)

    p = sub.add_parser("preview")
    p.add_argument("input")
    p.add_argument("--manager", default="auto", choices=["auto", "awww", "mpvpaper"])
    add_filter_args(p)
    p.set_defaults(func=cmd_preview)

    p = sub.add_parser("apply")
    p.add_argument("input")
    p.add_argument("--manager", default="auto", choices=["auto", "awww", "mpvpaper"])
    p.add_argument("--volume", type=int, default=50)
    p.add_argument("--mute", type=int, default=1)
    add_awww_args(p)
    add_filter_args(p)
    p.set_defaults(func=cmd_apply)

    p = sub.add_parser("save")
    p.add_argument("input")
    add_filter_args(p)
    p.set_defaults(func=cmd_save)

    p = sub.add_parser("ipc")
    p.add_argument("action", choices=["status", "toggle", "cycle-mute", "volume", "seek", "restart"])
    p.add_argument("value", nargs="?", default="")
    p.set_defaults(func=cmd_ipc)

    p = sub.add_parser("wallust-get")
    p.set_defaults(func=cmd_wallust_get)

    p = sub.add_parser("wallust-set")
    p.add_argument("--backend", default="wal", choices=WALLUST_BACKENDS)
    p.add_argument("--color-space", default="lch", choices=WALLUST_COLOR_SPACES)
    p.add_argument("--palette", default="dark", choices=WALLUST_PALETTES)
    p.add_argument("--fallback-generator", default="interpolation", choices=WALLUST_FALLBACKS)
    p.add_argument("--check-contrast", type=int, default=0)
    p.add_argument("--saturation-on", type=int, default=0)
    p.add_argument("--saturation", type=int, default=50)
    p.add_argument("--threshold-on", type=int, default=0)
    p.add_argument("--threshold", type=int, default=0)
    p.set_defaults(func=cmd_wallust_set)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
