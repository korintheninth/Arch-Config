pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: updateChecker

    property int count: 0
    property int pollIntervalMs: 600000

    Process {
        id: fetchUpdates
        command: ["sh", Quickshell.shellPath("Scripts/updates.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim()
                if (!trimmed)
                    return
                const n = parseInt(trimmed)
                if (!isNaN(n))
                    updateChecker.count = n
            }
        }
    }

    Timer {
        id: timer
        interval: updateChecker.pollIntervalMs
        running: true
        repeat: true
        onTriggered: {
            if (!fetchUpdates.running)
                fetchUpdates.running = true
        }
    }

    function refresh() {
        if (!fetchUpdates.running)
            fetchUpdates.running = true
    }

    Component.onCompleted: refresh()
}
