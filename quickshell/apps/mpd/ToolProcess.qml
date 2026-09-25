import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: proc

    property string tag: "mpd"
    signal result(var data)

    running: false

    function exec(args) {
        running = false
        command = ["python3", Quickshell.shellPath("apps/mpd/tool.py")].concat(args)
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
