#!/usr/bin/env python3
import argparse
import os
import sys

import numpy as np

from scope_common import (
    CHANNELS,
    RATE,
    add_pixel,
    brush_offsets,
    decay_lut,
    default_sink,
    parse_color,
    plot_line,
    start_capture,
    write_png,
)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--size", type=int, default=128)
    p.add_argument("--decay", type=int, default=14)
    p.add_argument("--intensity", type=int, default=96)
    p.add_argument("--gain", type=float, default=1.0)
    p.add_argument("--line-width", type=int, default=1)
    p.add_argument("--color", default="255,255,255,255")
    p.add_argument("--out", required=True)
    p.add_argument("--fps", type=int, default=24)
    p.add_argument("--target", default="")
    args = p.parse_args()

    size = max(2, args.size)
    decay = max(0, min(255, args.decay))
    intensity = max(0, min(255, args.intensity))
    gain = max(0.01, args.gain)
    fps = max(1, min(60, args.fps))
    half = max(0, (max(1, args.line_width) - 1) // 2)
    color, color_alpha = parse_color(args.color)
    brush = brush_offsets(half)
    lut = decay_lut(decay)

    samples_per_frame = max(1, RATE // fps)
    sink = default_sink(args.target)
    if not sink:
        sys.exit(1)

    out_dir = os.path.dirname(os.path.abspath(args.out))
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    proc = start_capture(f"qs-vectorscope-{os.getpid()}", sink)
    nbytes = samples_per_frame * CHANNELS * 4
    buf = np.zeros((size, size), dtype=np.uint8)
    last = None
    n = size - 1
    paths = [args.out + ".0.png", args.out + ".1.png"]
    flip = 0
    stdout = sys.stdout
    fit_peak = 0.0
    headroom = 0.88
    g = np.float32(gain)

    try:
        while True:
            data = proc.stdout.read(nbytes)
            if not data or len(data) < nbytes:
                break

            buf[:] = lut[buf]

            samples = np.frombuffer(data, dtype=np.float32)
            left = samples[0::2] * g
            right = samples[1::2] * g
            frame_peak = float(np.max(np.hypot(left, right))) if left.size else 0.0
            if frame_peak > fit_peak:
                fit_peak = frame_peak
            else:
                fit_peak = fit_peak * 0.94 + frame_peak * 0.06
            scale = headroom / fit_peak if fit_peak > headroom else 1.0

            xs = ((left * scale * 0.5 + 0.5) * n).astype(np.int32)
            ys = ((0.5 - right * scale * 0.5) * n).astype(np.int32)
            np.clip(xs, 0, n, out=xs)
            np.clip(ys, 0, n, out=ys)

            if last is None:
                last = (int(xs[0]), int(ys[0]))
                add_pixel(buf, last[0], last[1], intensity, brush)
                start = 1
            else:
                start = 0
            lx, ly = last
            for x, y in zip(xs[start:].tolist(), ys[start:].tolist()):
                if x == lx and y == ly:
                    continue
                plot_line(buf, lx, ly, x, y, intensity, brush)
                lx, ly = x, y
            last = (lx, ly)

            path = paths[flip]
            write_png(path, buf, color, color_alpha)
            stdout.write(path + "\n")
            stdout.flush()
            flip ^= 1
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        if proc.poll() is None:
            proc.terminate()


if __name__ == "__main__":
    main()
