pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: prayerTimesService

    property string city: "Istanbul"
    property string country: "Turkey"
    property int method: 13

    property var prayers: []
    property string curPrayer: ""
    property string date: ""
    property bool loading: false
    property string error: ""

    property int pollIntervalMs: 1800000
    property int retryInterval: 500

    property int dataVersion: 0

    property bool _refreshing: false
    property bool _refreshQueued: false

    Timer {
        id: pollTimer
        interval: prayerTimesService.pollIntervalMs
        running: prayerTimesService.pollIntervalMs > 0
        repeat: true
        onTriggered: prayerTimesService.refreshAll()
    }

    Timer {
        id: retryTimer
        interval: prayerTimesService.retryInterval
        running: false
        repeat: false
        onTriggered: prayerTimesService.refreshAll()
    }

    Timer {
        id: refreshDebounce
        interval: 600
        repeat: false
        onTriggered: prayerTimesService.refreshAll()
    }

    Timer {
        id: tickTimer
        interval: 60000
        running: prayers.length > 0
        repeat: true
        onTriggered: prayerTimesService.updateCurrentPrayer()
    }

    onErrorChanged: {
        if (error !== "")
            retryTimer.restart()
    }

    onCityChanged: refreshDebounce.restart()
    onCountryChanged: refreshDebounce.restart()
    onMethodChanged: refreshDebounce.restart()

    function scheduleRefresh() {
        refreshDebounce.restart()
    }

    function cleanTime(value) {
        return (value || "").split(" ")[0]
    }

    function minutesFromMidnight(timeStr) {
        const parts = cleanTime(timeStr).split(":")
        if (parts.length < 2)
            return -1
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10)
    }

    function parsePrayers(data) {
        date = (data && data.data && data.data.date && data.data.date.hijri && data.data.date.hijri.date) || ""
        const timings = (data && data.data && data.data.timings) || {}
        const sortedTimings = Object.entries(timings).sort((a, b) => {
            let timeA = a[1];
            let timeB = b[1];
            if (timeA <= timings["Imsak"]) timeA = "5" + timeA; 
            if (timeB <= timings["Imsak"]) timeB = "5" + timeB;

            return timeA.localeCompare(timeB);
        })
        
        const result = []
        for (const [name, time] of sortedTimings) {
            if (name == "Sunset" || name == "Midnight" || name == "Firstthird" || name == "Lastthird") continue
            result.push({ name: name, time: cleanTime(time) })
        }

        return result
    }

    function updateCurrentPrayer() {
        const now = new Date()
        const nowMins = now.getHours() * 60 + now.getMinutes()
        let cur = ""

        for (let i = 0; i < prayers.length; i++) {
            let currentMins = minutesFromMidnight(prayers[i].time);
            let nextMins = minutesFromMidnight(prayers[(i + 1) % prayers.length].time);
            if ((currentMins < nextMins && nowMins >= currentMins && nowMins < nextMins)
                || (currentMins > nextMins && (nowMins >= currentMins || nowMins < nextMins))
                ) {
                cur = prayers[i].name
                break
            }
        }

        if (!cur && prayers.length > 0)
            cur = prayers[prayers.length - 1].name

        if (curPrayer !== cur)
            curPrayer = cur
    }

    function setPrayerData(list) {
        prayers = list || []
        updateCurrentPrayer()
        dataVersion++
    }

    function apiRequest(callback) {
        const xhr = new XMLHttpRequest()

        const params = new URLSearchParams({
            city: city,
            country: country,
            method: String(method)
        })
        var url = "https://api.aladhan.com/v1/timingsByCity?" + params.toString()
        xhr.open("GET", url)

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            let data = null
            if (xhr.responseText) {
                try {
                    data = JSON.parse(xhr.responseText)
                } catch (e) {
                    data = null
                }
            }

            const ok = xhr.status >= 200 && xhr.status < 300
            callback(data, xhr.status, ok ? "" : (xhr.status ? ("Aladhan HTTP " + xhr.status) : "Prayer times request failed"))
        }

        xhr.send(null)
    }

    function refreshAll() {
        if (_refreshing) {
            _refreshQueued = true
            return
        }

        _refreshing = true
        loading = true
        error = ""

        function finishRefresh() {
            _refreshing = false
            loading = false

            if (_refreshQueued) {
                _refreshQueued = false
                refreshAll()
            }
        }

        apiRequest(function(data, status, err) {
            if (status !== 200 || !data || data.code !== 200) {
                error = err || "Invalid prayer times response"
                finishRefresh()
                return
            }

            try {
                const parsed = parsePrayers(data)
                if (!parsed.length) {
                    error = "No prayer times in response"
                    finishRefresh()
                    return
                }

                error = ""
                setPrayerData(parsed)
            } catch (e) {
                error = "Invalid prayer times response"
            }

            finishRefresh()
        })
    }

    Component.onCompleted: refreshAll()
}
