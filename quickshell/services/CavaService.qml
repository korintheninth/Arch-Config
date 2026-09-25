pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../themes"

Singleton {
    id: service

    property string confPath: Styles.wallpaper.media.cava.confPath
    property int viewers: 0
    property var bars: []
    property bool _restarting: false

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
        const parts = line.split(";")
        const vals = []
        for (let i = 0; i < parts.length; i++) {
            if (parts[i] === "")
                continue
            vals.push(parseInt(parts[i], 10) / 1000.0)
        }
        service.bars = vals
    }

    onConfPathChanged: {
        if (capture.running)
            restartCapture()
    }

    Process {
        id: capture
        command: ["cava", "-p", Quickshell.shellPath(service.confPath)]
        running: service.active && !service._restarting

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => service.parseLine(line)
        }

        onExited: {
            service.bars = []
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
