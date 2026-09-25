#!/usr/bin/env python3
import argparse
import os
import sys

import numpy as np

from scope_common import CHANNELS, RATE, ensure_stream_link, start_capture_stream


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--width", type=int, default=512)
    p.add_argument("--period-ms", type=int, default=50)
    p.add_argument("--gain", type=float, default=1.0)
    p.add_argument("--fps", type=int, default=24)
    p.add_argument("--target", default="")
    args = p.parse_args()

    width = max(2, args.width)
    period_ms = max(1, args.period_ms)
    gain = max(0.01, args.gain)
    fps = max(1, min(60, args.fps))

    samples_per_frame = max(1, RATE // fps)
    window_n = max(2, int(RATE * period_ms / 1000))
    hop = max(1, window_n // width)
    hints = [h for h in args.target.split("|") if h.strip()]
    if not hints:
        sys.exit(1)

    capture_name = f"qs-oscilloscope-{os.getpid()}"
    proc = start_capture_stream(capture_name, hints)
    nbytes = samples_per_frame * CHANNELS * 4
    fifo = np.zeros(width, dtype=np.float32)
    leftover = np.zeros(hop, dtype=np.float32)
    leftover_n = 0
    stdout = sys.stdout
    fit_peak = 0.0
    headroom = 0.88
    # pw-cat keeps emitting silence after links die; relink on an interval.
    relink_every = max(1, fps // 2)
    frames = 0

    def push(pts):
        k = pts.shape[0]
        if k <= 0:
            return
        if k >= width:
            fifo[:] = pts[-width:]
            return
        fifo[:-k] = fifo[k:].copy()
        fifo[-k:] = pts

    try:
        while True:
            data = proc.stdout.read(nbytes)
            if not data or len(data) < nbytes:
                break

            frames += 1
            if frames % relink_every == 0:
                ensure_stream_link(capture_name, hints)

            samples = np.frombuffer(data, dtype=np.float32)
            mono = (samples[0::2] + samples[1::2]) * np.float32(0.5 * gain)
            n = mono.shape[0]
            if not n:
                continue

            frame_peak = float(np.max(np.abs(mono)))
            if frame_peak > fit_peak:
                fit_peak = frame_peak
            else:
                fit_peak = fit_peak * 0.94 + frame_peak * 0.06
            scale = headroom / fit_peak if fit_peak > headroom else 1.0

            if leftover_n:
                need = hop - leftover_n
                take = min(need, n)
                leftover[leftover_n:leftover_n + take] = mono[:take]
                leftover_n += take
                mono = mono[take:]
                n -= take
                if leftover_n == hop:
                    push(leftover[hop - 1:hop])
                    leftover_n = 0

            if n >= hop:
                n_hops = n // hop
                used = n_hops * hop
                push(mono[hop - 1:used:hop])
                mono = mono[used:]
                n -= used

            if n:
                leftover[:n] = mono
                leftover_n = n

            ys = 0.5 - np.clip(fifo * scale, -1.0, 1.0) * 0.5
            stdout.write(" ".join("%.4f" % v for v in ys))
            stdout.write("\n")
            stdout.flush()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        if proc.poll() is None:
            proc.terminate()


if __name__ == "__main__":
    main()
