pragma Singleton

import Quickshell
import QtQuick
import "../components"

Singleton {
    id: prayerTimesService

    property string city: "Istanbul"
    property string country: "Turkey"
    property int method: 13

    property var prayers: []
    property string curPrayer: ""
    property string nextPrayer: ""
    property string remainingText: ""
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

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: prayers.length > 0
        onDateChanged: prayerTimesService.updateCurrentPrayer()
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

    CurlRequest {
        id: http
        name: "Aladhan"
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

            return timeA.localeCompare(timeB);
        })
        
        const result = []
        for (const [name, time] of sortedTimings) {
            if (name == "Sunset" || name == "Midnight" || name == "Firstthird" || name == "Lastthird") continue
            result.push({ name: name, time: cleanTime(time) })
        }

        return result
    }

    function pad2(n) {
        return String(n).padStart(2, "0")
    }

    function formatRemaining(hours, minutes, seconds, nextMins) {
        const nowMins = hours * 60 + minutes
        let remMins = nextMins - nowMins
        if (remMins < 0)
            remMins += 24 * 60
        const totalSec = Math.max(0, remMins * 60 - seconds)
        const h = Math.floor(totalSec / 3600)
        const m = Math.floor((totalSec % 3600) / 60)
        const s = totalSec % 60
        return pad2(h) + ":" + pad2(m) + ":" + pad2(s)
    }

    function updateCurrentPrayer() {
        if (!prayers.length) {
            curPrayer = ""
            nextPrayer = ""
            remainingText = ""
            return
        }

        const nowMins = clock.hours * 60 + clock.minutes
        let cur = ""
        let nextName = ""
        let nextMins = -1

        for (let i = 0; i < prayers.length; i++) {
            let currentMins = minutesFromMidnight(prayers[i].time);
            let nxtMins = minutesFromMidnight(prayers[(i + 1) % prayers.length].time);
            if ((currentMins < nxtMins && nowMins >= currentMins && nowMins < nxtMins)
                || (currentMins > nxtMins && (nowMins >= currentMins || nowMins < nxtMins))
                ) {
                cur = prayers[i].name
                const next = prayers[(i + 1) % prayers.length]
                nextName = next.name
                nextMins = nxtMins
                break
            }
        }

        if (!cur) {
            cur = prayers[prayers.length - 1].name
            nextName = prayers[0].name
            nextMins = minutesFromMidnight(prayers[0].time)
        }

        if (curPrayer !== cur)
            curPrayer = cur
        if (nextPrayer !== nextName)
            nextPrayer = nextName

        remainingText = formatRemaining(clock.hours, clock.minutes, clock.seconds, nextMins)
    }

    function setPrayerData(list) {
        prayers = list || []
        updateCurrentPrayer()
        dataVersion++
    }

    function apiRequest(callback) {
        const params = new URLSearchParams({
            city: city,
            country: country,
            method: String(method)
        })
        http.request({
            url: "https://api.aladhan.com/v1/timingsByCity?" + params.toString(),
            callback: callback
        })
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
