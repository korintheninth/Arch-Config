pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../themes"

Singleton {
    id: service

    property int bufferSize: Styles.vectorscope.bufferSize
    property int decay: Styles.vectorscope.decay
    property int intensity: Styles.vectorscope.intensity
    property real gain: Styles.vectorscope.gain
    property int fps: Styles.vectorscope.fps
    property int lineWidth: Styles.vectorscope.lineWidth
    property color color: Styles.vectorscope.color
    property int viewers: 0
    property string framePath: ""
    property bool _restarting: false

    readonly property string frameSource: framePath.length ? "file://" + framePath : ""
    readonly property string _outBase: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-vectorscope"
    readonly property string _colorArg: {
        const c = color
        return [Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255), Math.round(c.a * 255)].join(",")
    }
    readonly property string _captureKey: [bufferSize, decay, intensity, gain, fps, lineWidth, _colorArg].join("|")
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

    on_CaptureKeyChanged: {
        if (capture.running)
            restartCapture()
    }

    Process {
        id: capture
        command: [
            "python3", "-u",
            Quickshell.shellPath("Scripts/vectorscope.py"),
            "--size", "" + service.bufferSize,
            "--decay", "" + service.decay,
            "--intensity", "" + service.intensity,
            "--gain", "" + service.gain,
            "--line-width", "" + service.lineWidth,
            "--color", service._colorArg,
            "--out", service._outBase,
            "--fps", "" + service.fps
        ]
        running: service.active && !service._restarting

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: path => {
                if (path.length)
                    service.framePath = path
            }
        }

        onExited: {
            if (service.active && !service._restarting)
                crashTimer.restart()
        }
    }

    Timer {
        id: recaptureTimer
        interval: 50
        onTriggered: {
            service._restarting = false
            if (service.active)
                capture.running = true
        }
    }

    Timer {
        id: crashTimer
        interval: 800
        onTriggered: {
            if (service.active && !capture.running)
                capture.running = true
        }
    }
}
