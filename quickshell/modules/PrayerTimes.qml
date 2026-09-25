import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../themes"
import "../services"

Rectangle {
    id: prayerTimes

    color: styleOverride?.color ?? Styles.prayerTimes.color
    radius: styleOverride?.radius ?? Styles.prayerTimes.radius

    property int rowSpacing: styleOverride?.rowSpacing ?? Styles.prayerTimes.rowSpacing
    property var styleOverride: null

    ListModel {
        id: prayerModel
    }

    function applyLocalPrayers() {
        var list = PrayerTimesService.prayers

        prayerModel.clear()
        if (!list || !list.length)
            return

        for (let i = 0; i < list.length; i++) {
            prayerModel.append({
                name: list[i].name,
                time: list[i].time
            })
        }
    }

    Connections {
        target: PrayerTimesService
        function onDataVersionChanged() {
            applyLocalPrayers()
        }
    }

    Component.onCompleted: applyLocalPrayers()

    Column {
        id: prayerColumn
        anchors.fill: parent
        spacing: prayerTimes.rowSpacing

        /*
        BetterText {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: PrayerTimesService.date
            font.pixelSize: Styles.prayerTimes.pixelSize
            horizontalAlignment: Text.AlignHCenter
            color: Styles.prayerTimes.date.color
            font.family: Styles.prayerTimes.date.font.family
            font.bold: Styles.prayerTimes.date.font.bold
        }
        */

        Repeater {
            model: prayerModel

            delegate: RowLayout {
                required property string name
                required property string time

                readonly property bool active: PrayerTimesService.curPrayer === name
                readonly property var nameStyle: {
                    const o = prayerTimes.styleOverride
                    const over = active ? o?.row?.active?.name : o?.row?.name
                    const base = active ? Styles.prayerTimes.row.active.name : Styles.prayerTimes.row.name
                    return over ?? base
                }
                readonly property var timeStyle: {
                    const o = prayerTimes.styleOverride
                    const over = active ? o?.row?.active?.time : o?.row?.time
                    const base = active ? Styles.prayerTimes.row.active.time : Styles.prayerTimes.row.time
                    return over ?? base
                }

                width: prayerColumn.width
                spacing: 6

                BetterText {
                    id: nameLabel
                    Layout.fillWidth: true
                    text: name
                    font.pixelSize: nameStyle.font?.pixelSize ?? Styles.prayerTimes.pixelSize
                    color: nameStyle.color
                    font.family: nameStyle.font?.family ?? Styles.prayerTimes.row.name.font.family
                    font.bold: nameStyle.font?.bold ?? false
                }

                BetterText {
                    id: timeLabel
                    text: time
                    font.pixelSize: timeStyle.font?.pixelSize ?? Styles.prayerTimes.pixelSize
                    color: timeStyle.color
                    font.family: timeStyle.font?.family ?? Styles.prayerTimes.row.time.font.family
                    font.bold: timeStyle.font?.bold ?? false
                }
            }
        }

        BetterText {
            id: loadingLabel
            visible: PrayerTimesService.loading && prayerModel.count === 0
            text: "…"
            color: prayerTimes.styleOverride?.empty?.text?.color ?? Styles.prayerTimes.empty.text.color
            font.family: prayerTimes.styleOverride?.empty?.text?.font?.family ?? Styles.prayerTimes.empty.text.font.family
            font.bold: prayerTimes.styleOverride?.empty?.text?.font?.bold ?? Styles.prayerTimes.empty.text.font.bold
        }

        BetterText {
            id: errorLabel
            visible: PrayerTimesService.error.length > 0
            text: PrayerTimesService.error
            wrapMode: Text.Wrap
            width: prayerColumn.width
            color: prayerTimes.styleOverride?.error?.text?.color ?? Styles.prayerTimes.error.text.color
            font.family: prayerTimes.styleOverride?.error?.text?.font?.family ?? Styles.prayerTimes.error.text.font.family
            font.bold: prayerTimes.styleOverride?.error?.text?.font?.bold ?? Styles.prayerTimes.error.text.font.bold
        }

        Item {
            width: 1
            height: prayerTimes.styleOverride?.timer?.topMargin ?? Styles.prayerTimes.timer.topMargin
            visible: countdownLabel.visible
        }

        BetterText {
            id: countdownLabel
            visible: PrayerTimesService.remainingText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: PrayerTimesService.remainingText
            font.pixelSize: prayerTimes.styleOverride?.timer?.font?.pixelSize ?? Styles.prayerTimes.timer.font.pixelSize
            font.family: prayerTimes.styleOverride?.timer?.font?.family ?? Styles.prayerTimes.timer.font.family
            font.bold: prayerTimes.styleOverride?.timer?.font?.bold ?? Styles.prayerTimes.timer.font.bold
            color: prayerTimes.styleOverride?.timer?.color ?? Styles.prayerTimes.timer.color
            horizontalAlignment: Text.AlignHCenter
        }

        /*
        BetterText {
            id: nextPrayerLabel
            visible: countdownLabel.visible && PrayerTimesService.nextPrayer.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: "until " + PrayerTimesService.nextPrayer
            font.pixelSize: prayerTimes.styleOverride?.timerLabel?.font?.pixelSize ?? Styles.prayerTimes.timerLabel.font.pixelSize
            font.family: prayerTimes.styleOverride?.timerLabel?.font?.family ?? Styles.prayerTimes.timerLabel.font.family
            font.bold: prayerTimes.styleOverride?.timerLabel?.font?.bold ?? Styles.prayerTimes.timerLabel.font.bold
            color: prayerTimes.styleOverride?.timerLabel?.color ?? Styles.prayerTimes.timerLabel.color
            horizontalAlignment: Text.AlignHCenter
        }
        */
    }

    implicitWidth: prayerColumn.implicitWidth
    implicitHeight: prayerColumn.implicitHeight
}
