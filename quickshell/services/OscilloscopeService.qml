pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../themes"

Singleton {
    id: service

    property int bufferWidth: Styles.oscilloscope.bufferWidth
    property int periodMs: Styles.oscilloscope.periodMs
    property real gain: Styles.oscilloscope.gain
    property int fps: Styles.oscilloscope.fps
    property int viewers: 0
    property var samples: []
    property bool _restarting: false

    readonly property string targetHints: PlayerService.streamHints

    readonly property string _captureKey: [bufferWidth, periodMs, gain, fps, targetHints].join("|")
    readonly property bool active: viewers > 0

    function retain() {
        viewers += 1
    }

    function release() {
        if (viewers > 0)
            viewers -= 1
    }

    function restartCapture() {
        if (_restarting)
            return
        _restarting = true
        capture.running = false
        recaptureTimer.restart()
    }

    function parseLine(line) {
        const parts = line.trim().split(" ")
        const n = parts.length
        if (n < 2)
            return
        const ys = new Array(n)
        for (let i = 0; i < n; i++)
            ys[i] = Number(parts[i])
        service.samples = ys
    }

    on_CaptureKeyChanged: {
        // Player/settings change: always bounce capture so hints are rebuilt.
        // (Writing capture.running breaks the binding, so do not gate on it.)
        if (service.active && service.targetHints.length)
            restartCapture()
        else if (!service.targetHints.length)
            service.samples = []
    }

    Process {
        id: capture
        command: [
            "python3", "-u",
            Quickshell.shellPath("Scripts/oscilloscope.py"),
            "--width", "" + service.bufferWidth,
            "--period-ms", "" + service.periodMs,
            "--gain", "" + service.gain,
            "--fps", "" + service.fps,
            "--target", service.targetHints
        ]
        running: service.active && service.targetHints.length && !service._restarting

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => service.parseLine(line)
        }

        onExited: {
            service.samples = []
            if (service.active && service.targetHints.length && !service._restarting)
                crashTimer.restart()
        }
    }

    onActiveChanged: {
        if (!active) {
            crashTimer.stop()
            recaptureTimer.stop()
            service._restarting = false
            capture.running = false
            service.samples = []
        } else if (service.targetHints.length) {
            restartCapture()
        }
    }

    Timer {
        id: recaptureTimer
        interval: 80
        onTriggered: {
            service._restarting = false
            if (service.active && service.targetHints.length)
                capture.running = true
        }
    }

    Timer {
        id: crashTimer
        interval: 500
        onTriggered: {
            if (service.active && service.targetHints.length && !capture.running)
                capture.running = true
        }
    }
}
