import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../services"

Rectangle {
    id: prayerTimes

    color: "transparent"

    property int rowSpacing: 3
    property int maxWidth: Styles.prayerTimes.maxWidth
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

    function applyRowStyles(nameLabel, timeLabel) {
        const active = PrayerTimesService.curPrayer === nameLabel.text
        Styler.apply(nameLabel, active ? Styles.prayerTimes.row.active.name : Styles.prayerTimes.row.name)
        Styler.apply(timeLabel, active ? Styles.prayerTimes.row.active.time : Styles.prayerTimes.row.time)
        if (styleOverride) {
            Styler.apply(nameLabel, active ? styleOverride.row?.active?.name : styleOverride.row?.name)
            Styler.apply(timeLabel, active ? styleOverride.row?.active?.time : styleOverride.row?.time)
        }
    }

    Component.onCompleted: {
        Styler.apply(prayerTimes, Styles.prayerTimes)
        if (styleOverride)
            Styler.apply(prayerTimes, styleOverride)
        Styler.apply(loadingLabel, Styles.prayerTimes.empty.text)
        Styler.apply(errorLabel, Styles.prayerTimes.error.text)
        Styler.apply(dateLabel, Styles.prayerTimes.date)
        if (styleOverride) {
            Styler.apply(loadingLabel, styleOverride.empty?.text)
            Styler.apply(errorLabel, styleOverride.error?.text)
        }
        applyLocalPrayers()
    }

    Column {
        id: prayerColumn
        width: prayerTimes.maxWidth
        spacing: prayerTimes.rowSpacing

        BetterText {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: PrayerTimesService.date
            font.pixelSize: Styles.prayerTimes.pixelSize
            horizontalAlignment: Text.AlignHCenter
    }
    
        Repeater {
            model: prayerModel

            delegate: RowLayout {
                required property string name
                required property string time

                width: prayerColumn.width
                spacing: 6

                BetterText {
                    id: nameLabel
                    Layout.fillWidth: true
                    text: name
                    font.pixelSize: Styles.prayerTimes.pixelSize
                }

                BetterText {
                    id: timeLabel
                    text: time
                    font.pixelSize: Styles.prayerTimes.pixelSize
                }

                Connections {
                    target: PrayerTimesService
                    function onCurPrayerChanged() {
                        prayerTimes.applyRowStyles(nameLabel, timeLabel)
                    }
                }

                Component.onCompleted: prayerTimes.applyRowStyles(nameLabel, timeLabel)
            }
        }

        BetterText {
            id: loadingLabel
            visible: PrayerTimesService.loading && prayerModel.count === 0
            text: "…"
        }

        BetterText {
            id: errorLabel
            visible: PrayerTimesService.error.length > 0
            text: PrayerTimesService.error
            wrapMode: Text.Wrap
            width: prayerColumn.width
        }
    }

    implicitWidth: prayerColumn.implicitWidth
    implicitHeight: prayerColumn.implicitHeight
}
