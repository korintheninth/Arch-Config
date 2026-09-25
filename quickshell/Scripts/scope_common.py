import json
import os
import struct
import subprocess
import sys
import time
import zlib

import numpy as np

RATE = 48000
CHANNELS = 2


def parse_color(text):
    channels = [max(0, min(255, int(v))) for v in text.split(",")[:4]]
    while len(channels) < 3:
        channels.append(255)
    if len(channels) < 4:
        channels.append(255)
    return (channels[0], channels[1], channels[2]), channels[3]


def decay_lut(decay):
    lut = np.arange(256, dtype=np.uint8)
    if decay <= 0:
        return lut
    if decay >= 255:
        return np.zeros(256, dtype=np.uint8)
    lut[: decay + 1] = 0
    lut[decay + 1 :] -= np.uint8(decay)
    return lut


def brush_offsets(half):
    if half <= 0:
        return ((0, 0),)
    r2 = (half + 0.5) * (half + 0.5)
    pts = []
    for dy in range(-half, half + 1):
        for dx in range(-half, half + 1):
            if dx * dx + dy * dy <= r2:
                pts.append((dx, dy))
    return tuple(pts)


def add_pixel(buf, x, y, intensity, brush):
    h, w = buf.shape
    add = int(intensity)
    for dx, dy in brush:
        xx = x + dx
        yy = y + dy
        if 0 <= xx < w and 0 <= yy < h:
            v = int(buf[yy, xx]) + add
            buf[yy, xx] = 255 if v > 255 else v


def plot_line(buf, x0, y0, x1, y1, intensity, brush):
    if x0 == x1 and y0 == y1:
        return
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    first = True
    while True:
        if not first:
            add_pixel(buf, x0, y0, intensity, brush)
        else:
            first = False
        if x0 == x1 and y0 == y1:
            break
        e2 = err << 1
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def write_png(path, buf, color, color_alpha):
    h, w = buf.shape
    cr, cg, cb = color
    row_bytes = 1 + w * 4
    filtered = np.empty((h, row_bytes), dtype=np.uint8)
    filtered[:, 0] = 0
    rgba = filtered[:, 1:].reshape(h, w, 4)
    rgba[..., 0] = cr
    rgba[..., 1] = cg
    rgba[..., 2] = cb
    alpha = buf.astype(np.uint16, copy=False)
    rgba[..., 3] = (alpha * color_alpha) // 255

    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(filtered.tobytes(), 1))
    png += chunk(b"IEND", b"")

    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(png)
    os.replace(tmp, path)


def write_gray_png(path, row):
    w = int(row.size)
    filtered = np.empty(1 + w, dtype=np.uint8)
    filtered[0] = 0
    filtered[1:] = np.ascontiguousarray(row, dtype=np.uint8).reshape(-1)

    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, 1, 8, 0, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(filtered.tobytes(), 1))
    png += chunk(b"IEND", b"")

    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(png)
    os.replace(tmp, path)


def has_port(name):
    try:
        ports = subprocess.check_output(["pw-link", "-i"], text=True)
    except subprocess.CalledProcessError:
        return False
    return f"{name}:input_FL" in ports


def disconnect_inputs(name):
    try:
        listing = subprocess.check_output(["pw-link", "-l"], text=True)
    except subprocess.CalledProcessError:
        return
    current = None
    for line in listing.splitlines():
        if line.startswith(" ") or line.startswith("\t"):
            if current and "|<-" in line:
                src = line.split("|<-", 1)[1].strip()
                subprocess.run(
                    ["pw-link", "-d", src, current],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            continue
        if line.startswith(f"{name}:input_"):
            current = line.strip()
        else:
            current = None


def link_sink_monitor(sink, capture, timeout=1.5):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if has_port(capture):
            break
        time.sleep(0.03)
    else:
        return False

    disconnect_inputs(capture)
    ok = True
    for side in ("FL", "FR"):
        r = subprocess.run(
            ["pw-link", f"{sink}:monitor_{side}", f"{capture}:input_{side}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if r.returncode != 0:
            ok = False
    return ok


def default_sink(fallback=""):
    try:
        return subprocess.check_output(
            ["pactl", "get-default-sink"], text=True
        ).strip()
    except subprocess.CalledProcessError:
        return fallback.strip()


def spawn_capture(capture_name):
    cmd = [
        "pw-cat",
        "-r",
        "-a",
        "--format=f32",
        f"--rate={RATE}",
        f"--channels={CHANNELS}",
        "--latency=8ms",
        "--target", "0",
        "-P", f"node.name={capture_name}",
        "-P", "node.autoconnect=false",
        "-",
    ]
    return subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )


def start_capture(capture_name, sink):
    proc = spawn_capture(capture_name)
    if not link_sink_monitor(sink, capture_name):
        proc.terminate()
        sys.exit(1)
    return proc


_HINT_SKIP = {
    "music", "media", "player", "audio", "instance", "org", "mpris",
    "the", "and", "app", "desktop", "playerctld",
}

_HINT_ALIASES = {
    "youtube-music": ("chromium", "electron", "youtube-music"),
    "youtube": ("chromium", "electron"),
    "mpd": ("music player daemon", "mpd"),
    "mpd-mpris": ("music player daemon", "mpd"),
}

# Short names that still uniquely identify a stream (default min length is 4).
_HINT_SHORT_OK = {"mpd"}


def hint_tokens(text):
    raw = str(text or "").strip().lower()
    if not raw:
        return []
    raw = raw.replace("org.mpris.mediaplayer2.", "")
    tokens = []
    pieces = [raw]
    pieces.extend(raw.replace("-", " ").replace("_", " ").replace(".", " ").split())
    for piece in pieces:
        piece = piece.strip()
        if piece in _HINT_SKIP:
            continue
        if len(piece) < 4 and piece not in _HINT_SHORT_OK:
            continue
        if piece not in tokens:
            tokens.append(piece)
        for alias in _HINT_ALIASES.get(piece, ()):
            if alias not in tokens:
                tokens.append(alias)
    return tokens


def find_stream_node(hints):
    tokens = []
    for hint in hints:
        for token in hint_tokens(hint):
            if token not in tokens:
                tokens.append(token)
    if not tokens:
        return ""
    try:
        dump = json.loads(subprocess.check_output(["pw-dump"], text=True))
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return ""
    matches = []
    for obj in dump:
        if obj.get("type") != "PipeWire:Interface:Node":
            continue
        info = obj.get("info") or {}
        props = info.get("props") or info.get("properties") or {}
        if props.get("media.class") != "Stream/Output/Audio":
            continue
        # Omit media.name (track title) — it changes per song and causes false matches.
        fields = [
            props.get("node.name", ""),
            props.get("node.nick", ""),
            props.get("application.name", ""),
            props.get("application.process.binary", ""),
            props.get("application.id", ""),
        ]
        blob = " ".join(fields).lower()
        hit = False
        for token in tokens:
            if token in blob:
                hit = True
                break
            for field in fields:
                fl = field.lower()
                if token in fl or (len(fl) >= 4 and fl in token):
                    hit = True
                    break
            if hit:
                break
        if not hit:
            continue
        name = props.get("node.name", "")
        if not name:
            continue
        state = str(info.get("state") or props.get("node.state") or "").lower()
        running = state in ("running", "active", "streaming") or props.get("node.passive") is False
        matches.append((0 if running else 1, name))
    if not matches:
        return ""
    matches.sort()
    return matches[0][1]


def node_output_ports(node):
    try:
        listing = subprocess.check_output(["pw-link", "-o"], text=True)
    except subprocess.CalledProcessError:
        return []
    prefix = f"{node}:"
    return [line.strip() for line in listing.splitlines() if line.startswith(prefix)]


def pick_stereo_ports(ports):
    def find_end(suffix):
        for port in ports:
            if port.endswith(suffix):
                return port
        return None

    fl = find_end("output_FL") or find_end("playback_FL") or find_end("_FL")
    fr = find_end("output_FR") or find_end("playback_FR") or find_end("_FR")
    if fl and fr:
        return [fl, fr]
    audio = [port for port in ports if ":monitor_" not in port]
    if len(audio) >= 2:
        return audio[:2]
    if len(audio) == 1:
        return [audio[0], audio[0]]
    return []


def capture_input_sources(capture):
    try:
        listing = subprocess.check_output(["pw-link", "-l"], text=True)
    except subprocess.CalledProcessError:
        return []
    sources = []
    current = None
    prefix = f"{capture}:input_"
    for line in listing.splitlines():
        if line.startswith(" ") or line.startswith("\t"):
            if current and "|<-" in line:
                sources.append(line.split("|<-", 1)[1].strip())
            continue
        if line.startswith(prefix):
            current = line.strip()
        else:
            current = None
    return sources


def link_stream_outputs(node, capture):
    ports = pick_stereo_ports(node_output_ports(node))
    if len(ports) < 2 or not has_port(capture):
        return False
    disconnect_inputs(capture)
    ok = True
    for src, side in zip(ports, ("FL", "FR")):
        r = subprocess.run(
            ["pw-link", src, f"{capture}:input_{side}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if r.returncode != 0:
            ok = False
    return ok


def ensure_stream_link(capture_name, hints):
    """Re-resolve the target stream and relink if ports moved or player changed."""
    if not has_port(capture_name):
        return False
    node = find_stream_node(hints)
    if not node:
        return False
    prefix = f"{node}:"
    sources = capture_input_sources(capture_name)
    if len(sources) >= 2 and all(src.startswith(prefix) for src in sources):
        return True
    return link_stream_outputs(node, capture_name)


def start_capture_stream(capture_name, hints, timeout=2.5):
    proc = spawn_capture(capture_name)
    deadline = time.time() + timeout
    while time.time() < deadline:
        if ensure_stream_link(capture_name, hints):
            return proc
        time.sleep(0.08)
    proc.terminate()
    sys.exit(1)
