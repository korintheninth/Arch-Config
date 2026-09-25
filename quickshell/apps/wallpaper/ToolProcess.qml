import QtQuick
import Quickshell
import Quickshell.Io

// Runs tool.py subcommands and emits the parsed JSON reply as result().
Process {
    id: proc

    property string tag: "wallpaper"
    signal result(var data)

    running: false

    function exec(args) {
        running = false
        command = ["python3", Quickshell.shellPath("apps/wallpaper/tool.py")].concat(args)
        // Deferred so a killed previous instance is fully torn down first.
        Qt.callLater(() => proc.running = true)
    }

    stdout: StdioCollector {
        onStreamFinished: {
            const raw = text.trim()
            if (!raw)
                return
            try {
                proc.result(JSON.parse(raw))
            } catch (e) {
                proc.result({ ok: false, error: "unreadable reply from tool.py" })
            }
        }
    }

    stderr: StdioCollector {
        onStreamFinished: {
            if (text.trim())
                console.log("[" + proc.tag + "]", text.trim())
        }
    }
}
