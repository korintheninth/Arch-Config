pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool open: false

    function toggle() {
        open = !open
    }

    function show() {
        open = true
    }

    function hide() {
        open = false
    }

    IpcHandler {
        target: "mpui"
        function toggle(): void {
            root.toggle()
        }
        function open(): void {
            root.show()
        }
        function close(): void {
            root.hide()
        }
    }
}
