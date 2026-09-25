pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../themes"
import "../components"

Singleton {
    id: todoistService

    property string apiToken: ""
    property string tokenPath: Quickshell.shellPath("todoist.token")
    property var tasks: []
    property var dayPriorities: ({})
    property bool loading: false
    property string error: ""
    property int pollIntervalMs: 30000
    property int retryInterval: 500

    property int dataVersion: 0
    property int mutationVersion: 0

    property bool _refreshing: false
    property bool _refreshQueued: false
    property bool _ready: false

    readonly property string token: {
        const direct = apiToken.trim()
        if (direct)
            return direct
        if (tokenFile.loaded)
            return tokenFile.text().trim()
        return ""
    }

    function readToken() {
        const direct = apiToken.trim()
        if (direct)
            return direct
        if (!tokenFile.loaded)
            return ""
        return tokenFile.text().trim()
    }

    FileView {
        id: tokenFile
        path: todoistService.tokenPath
        watchChanges: true
        onLoaded: todoistService.refreshAll()
        onFileChanged: reload()
    }

    CurlRequest {
        id: getReq
        name: "Todoist"
    }

    CurlRequest {
        id: postReq
        name: "Todoist"
    }

    Timer {
        id: pollTimer
        interval: todoistService.pollIntervalMs
        running: todoistService.token.length > 0 && todoistService.pollIntervalMs > 0
        repeat: true
        onTriggered: todoistService.refreshAll()
    }

    Timer {
        id: retryTimer
        interval: todoistService.retryInterval
        running: false
        repeat: false
        onTriggered: todoistService.refreshAll()
    }

    Timer {
        id: refreshDebounce
        interval: 600
        repeat: false
        onTriggered: todoistService.refreshAll()
    }

    onErrorChanged: {
        if (error !== "")
            retryTimer.restart()
    }

    function scheduleRefresh() {
        refreshDebounce.restart()
    }


    function generateUuid() {
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0
            const v = c === "x" ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }

    function isPlainDateString(value) {
        return /^\d{4}-\d{2}-\d{2}$/.test(value || "")
    }

    function isRecurring(task) {
        if (!task)
            return false
        if (task.due.is_recurring)
            return true
    }


    function dateKey(value) {
        if (value === null || value === undefined)
            return Qt.formatDate(new Date(), "yyyy-MM-dd")
        if (typeof value === "string")
            return value
        return Qt.formatDate(value, "yyyy-MM-dd")
    }

    function plainDateKey(value) {
        return dateKey(value).slice(0, 10)
    }

    function daysBetween(fromValue, toValue) {
        const from = new Date(plainDateKey(fromValue) + "T00:00:00")
        const to = new Date(plainDateKey(toValue) + "T00:00:00")
        return Math.round((to.getTime() - from.getTime()) / 86400000)
    }

    function upcomingNonRecurring(days) {
        const window = days > 0 ? days : 10
        const todayKey = Qt.formatDate(new Date(), "yyyy-MM-dd")
        const end = new Date()
        end.setDate(end.getDate() + window)
        const endKey = Qt.formatDate(end, "yyyy-MM-dd")
        const result = []

        for (let i = 0; i < tasks.length; i++) {
            const task = tasks[i]
            const due = task.due
            if (!due || !due.date || due.is_recurring)
                continue

            const dueDate = plainDateKey(due.date)
            if (!isPlainDateString(dueDate))
                continue
            if (dueDate <= todayKey || dueDate > endKey)
                continue

            result.push(task)
        }

        result.sort(function(a, b) {
            const da = plainDateKey(a.due.date)
            const db = plainDateKey(b.due.date)
            if (da < db)
                return -1
            if (da > db)
                return 1
            return (b.priority || 1) - (a.priority || 1)
        })

        return result
    }

    function buildDayPriorities(taskList) {
        const map = {}
        if (!taskList)
            return map

        for (let i = 0; i < taskList.length; i++) {
            const task = taskList[i]
            const due = task.due
            if (!due || !due.date)
                continue
            const priority = task.priority || 1
            if (!map[due.date] || priority > map[due.date])
                map[due.date] = priority
        }

        return map
    }

    function setTaskData(taskList) {
        tasks = taskList || []
        dayPriorities = buildDayPriorities(tasks)
        dataVersion++
    }

    function tasksForDate(value) {
        const key = dateKey(value)
        const todayKey = Qt.formatDate(new Date(), "yyyy-MM-dd")
        const todayView = key === todayKey
        const result = []

        for (let i = 0; i < tasks.length; i++) {
            const task = tasks[i]
            const dueDate = (task.due || {}).date
            if (!dueDate)
                continue

            if (dueDate === key) {
                result.push(task)
                continue
            }

            if (todayView && dueDate < todayKey && isRecurring(task))
                result.push(task)
        }

        return result
    }

    function priorityColor(priority) {
        const colors = Styles.todoist.priority
        if (priority >= 4)
            return colors.p1
        if (priority === 3)
            return colors.p2
        if (priority === 2)
            return colors.p3
        return colors.p4
    }

    function dayPriority(dateKeyValue) {
        return dayPriorities[dateKeyValue] || 0
    }

    function extractTasks(data) {
        if (Array.isArray(data))
            return data
        if (data && Array.isArray(data.results))
            return data.results
        return []
    }

    function apiRequest(method, path, body, callback) {
        const authToken = readToken()
        if (!authToken) {
            callback(null, 0, "Missing Todoist API token")
            return
        }

        const opts = {
            method: method,
            url: "https://api.todoist.com/api/v1" + path,
            headers: { "Authorization": "Bearer " + authToken },
            callback: callback
        }
        if (body !== undefined) {
            opts.headers["Content-Type"] = "application/json"
            opts.body = body
        }
        (method === "GET" ? getReq : postReq).request(opts)
    }

    function finishRefresh() {
        _refreshing = false
        _ready = true
        loading = false

        if (_refreshQueued) {
            _refreshQueued = false
            refreshAll()
        }
    }

    function refreshAll() {
        const authToken = readToken()
        if (!authToken) {
            _refreshing = false
            _refreshQueued = false
            if (tokenFile.loaded)
                error = "Missing Todoist API token"
            setTaskData([])
            loading = false
            return
        }

        if (_refreshing) {
            _refreshQueued = true
            return
        }

        _refreshing = true
        if (!_ready)
            loading = true
        error = ""

        const collected = []
        const fetchMutationVersion = mutationVersion
        let cursor = ""

        function fetchPage() {
            let url = "/tasks?limit=200"
            if (cursor)
                url += "&cursor=" + encodeURIComponent(cursor)

            apiRequest("GET", url, undefined, function(data, status, err) {
                if (status !== 200) {
                    error = err || "Todoist request failed"
                    finishRefresh()
                    return
                }

                try {
                    collected.push.apply(collected, extractTasks(data))
                    cursor = (data && data.next_cursor) || ""
                    if (cursor) {
                        fetchPage()
                        return
                    }

                    error = ""
                    if (fetchMutationVersion === mutationVersion)
                        setTaskData(collected)
                    else
                        scheduleRefresh()
                } catch (e) {
                    error = "Invalid Todoist response"
                }

                finishRefresh()
            })
        }

        fetchPage()
    }

    function completeTask(taskId, callback) {
        if (!readToken()) {
            callback(false, "Missing Todoist API token")
            return
        }
        apiRequest("POST", "/tasks/" + taskId + "/close", undefined, function(data, status, err) {
            if (status > 300 || status < 200) {
                callback(false, err || "Failed to complete task")
                return
            }
            mutationVersion++

            scheduleRefresh()
            callback(true, "")
        })
    }
}
