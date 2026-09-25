import Quickshell
import Quickshell.Io
import QtQuick

Process {
    id: req

    property int timeoutSec: 15
    property string name: ""
    property var callback: null
    property var _pending: null
    property string _stdout: ""
    property bool _gotExit: false

    running: false

    function request(opts) {
        if (!opts || !opts.url)
            return
        if (running) {
            _pending = opts
            running = false
            return
        }
        start(opts)
    }

    function start(opts) {
        _pending = null
        _stdout = ""
        _gotExit = false
        callback = opts.callback || null

        const args = [
            "curl", "-sS", "-L", "--max-time", String(timeoutSec),
            "-w", "\n%{http_code}",
            "-X", opts.method || "GET"
        ]
        const headers = opts.headers || {}
        for (const name in headers) {
            if (headers[name] === undefined || headers[name] === null)
                continue
            args.push("-H", name + ": " + headers[name])
        }
        if (opts.body !== undefined && opts.body !== null) {
            args.push("--data-binary", typeof opts.body === "string" ? opts.body : JSON.stringify(opts.body))
        }
        args.push(opts.url)
        req.exec(args)
    }

    function parseOutput(raw) {
        const text = String(raw || "")
        const idx = text.lastIndexOf("\n")
        const status = idx < 0 ? 0 : parseInt(text.slice(idx + 1), 10)
        const body = idx < 0 ? text : text.slice(0, idx)
        let data = null
        if (body) {
            try {
                data = JSON.parse(body)
            } catch (e) {
                data = null
            }
        }
        const code = isNaN(status) ? 0 : status
        const ok = code >= 200 && code < 300
        const label = name || "request"
        return {
            data: data,
            status: code,
            error: ok ? "" : (code ? (label + " HTTP " + code) : (label + " failed"))
        }
    }

    function dispatch() {
        _gotExit = true
        const cb = callback
        callback = null
        if (!cb)
            return
        const parsed = parseOutput(_stdout)
        cb(parsed.data, parsed.status, parsed.error)
    }

    stdout: StdioCollector {
        onStreamFinished: req._stdout = text
    }

    stderr: StdioCollector {
        onStreamFinished: {
            if (text.trim())
                console.log("[curl]", text.trim())
        }
    }

    onExited: function() {
        _gotExit = true
        if (_pending) {
            callback = null
            start(_pending)
            return
        }
        dispatch()
    }

    onRunningChanged: {
        if (!running && !_gotExit && callback && !_pending)
            dispatch()
    }
}
