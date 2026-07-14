import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Controls
import Quickshell.Services.Notifications
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../services"

PopupWindow {
    id: centerMenu
    color: "transparent"
    implicitHeight: content.height + 10
    implicitWidth: content.width + 10

    property bool open: false

    HyprlandFocusGrab {
        active: centerMenu.open
        windows: [centerMenu]
        onCleared: centerMenu.open = false
    }

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    property Item anchorTarget: null
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 20
    onOpenChanged: {
        if (open) {
            visible = true
            anchor.updateAnchor()
        }
    }

    function truncate(str, max) {
        if (!str || max <= 0)
            return str ?? ""
        return str.length > max ? str.slice(0, max - 1) + "…" : str
    }

    function urgencyAccent(urgency) {
        const s = Styles.centerMenu.notifications.item.urgency
        if (urgency === NotificationUrgency.Critical)
            return s.critical
        return s.normal
    }

    function applyCalendarDayOfWeekStyle(target) {
        Styler.apply(target, Styles.centerMenu.calendar.dayOfWeek)
    }

    function applyCalendarDayStyle(target) {
        Styler.apply(target, Styles.centerMenu.calendar.text)
    }

    function applyNotificationItemStyles(item, dismissBtn, actionsRow, appName, summary, body) {
        Styler.apply(item, Styles.centerMenu.notifications.item)
        Styler.apply(dismissBtn, Styles.centerMenu.notifications.item.dismiss)
        Styler.apply(appName, Styles.centerMenu.notifications.item.appName)
        Styler.apply(summary, Styles.centerMenu.notifications.item.summary)
        Styler.apply(body, Styles.centerMenu.notifications.item.body)
        if (actionsRow)
            Styler.apply(actionsRow, Styles.centerMenu.notifications.item.actionsRow)
    }

    function applyNotificationActionStyles(action, actionLabel) {
        Styler.apply(action, Styles.centerMenu.notifications.item.action)
        Styler.apply(actionLabel, Styles.centerMenu.notifications.item.action.text)
    }

    Component.onCompleted: {
        Styler.apply(centerMenu, Styles.centerMenu)
        Styler.apply(content, Styles.centerMenu.background)
        Styler.apply(calendar, Styles.centerMenu.calendar)
        Styler.apply(prevMonthLabel, Styles.centerMenu.calendar.text)
        Styler.apply(dateLabel, Styles.centerMenu.calendar.text)
        Styler.apply(nextMonthLabel, Styles.centerMenu.calendar.text)
        Styler.apply(middlePanel, Styles.centerMenu.placeholder)
        Styler.apply(middleHeaderTitle, Styles.centerMenu.notifications.header.text)
        Styler.apply(middleToggleBtn, Styles.centerMenu.notifications.header.clear)
        Styler.apply(notifications, Styles.centerMenu.notifications)
        Styler.apply(notifTitle, Styles.centerMenu.notifications.header.text)
        Styler.apply(notifEmptyLabel, Styles.centerMenu.notifications.empty)
    }

    Rectangle {
        id: content
        width: Styles.centerMenu.panelWidth * 3
        height: Styles.centerMenu.panelHeight

        transform: Rotation {
            id: xAxisRotation
            origin.x: content.width / 2
            axis { x: 1; y: 0; z: 0 }
            angle: -90
        }

        NumberAnimation {
            id: openAnim
            target: xAxisRotation
            property: "angle"
            from: -90
            to: 0
            duration: 300
            easing.type: Easing.OutBack

            onFinished: {
                if (!centerMenu.open)
                    centerMenu.visible = false
            }
        }

        Connections {
            target: centerMenu
            function onOpenChanged() {
                if (centerMenu.open) {
                    xAxisRotation.angle = -90
                    openAnim.from = -90
                    openAnim.to = 0
                    openAnim.start()
                } else {
                    openAnim.from = xAxisRotation.angle
                    openAnim.to = -90
                    openAnim.start()
                }
            }
        }

        Row {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: calendar
                width: content.width / 3
                height: parent.height

                property int buttonWidth: Styles.centerMenu.calendar.buttonWidth
                property int buttonHeight: Styles.centerMenu.calendar.buttonHeight
                property int year: new Date().getFullYear()
                property int month: new Date().getMonth()
                property date selectedDate: new Date()

                Column {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Row {
                        id: controlRow
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: calendar.buttonWidth
                            height: calendar.buttonHeight
                            property bool hovered: false
                            color: hovered ? Styles.centerMenu.calendar.navButton.hoverColor : "transparent"

                            BetterText {
                                id: prevMonthLabel
                                anchors.centerIn: parent
                                text: "‹"
                                color: parent.hovered
                                    ? Styles.centerMenu.calendar.navButton.hoverTextColor
                                    : Styles.centerMenu.calendar.navButton.color
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: {
                                    if (calendar.month === 0) {
                                        calendar.month = 11
                                        calendar.year--
                                    } else {
                                        calendar.month--
                                    }
                                }
                            }
                        }

                        BetterText {
                            id: dateLabel
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            renderType: Text.NativeRendering
                            width: parent.width - 2 * calendar.buttonWidth - 2 * controlRow.spacing
                            text: Qt.formatDate(new Date(calendar.year, calendar.month, 1), "MMMM yyyy")
                        }

                        Rectangle {
                            width: calendar.buttonWidth
                            height: calendar.buttonHeight
                            property bool hovered: false
                            color: hovered ? Styles.centerMenu.calendar.navButton.hoverColor : "transparent"

                            BetterText {
                                id: nextMonthLabel
                                anchors.centerIn: parent
                                text: "›"
                                color: parent.hovered
                                    ? Styles.centerMenu.calendar.navButton.hoverTextColor
                                    : Styles.centerMenu.calendar.navButton.color
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: {
                                    if (calendar.month === 11) {
                                        calendar.month = 0
                                        calendar.year++
                                    } else {
                                        calendar.month++
                                    }
                                }
                            }
                        }
                    }

                    DayOfWeekRow {
                        id: weekRow
                        width: parent.width
                        locale: grid.locale
                        

                        delegate: BetterText {
                            required property string shortName
                            text: shortName
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Component.onCompleted: centerMenu.applyCalendarDayOfWeekStyle(this)
                        }
                    }

                    SystemClock {
                        id: clock
                        precision: SystemClock.Minutes
                    }

                    MonthGrid {
                        id: grid
                        width: parent.width
                        height: parent.height - weekRow.height - controlRow.height - col.spacing * 2
                        month: calendar.month
                        year: calendar.year
                        locale: Qt.locale()
                        onClicked: (date) => {
                            calendar.selectedDate = date
                        }

                        delegate: Rectangle {
                            required property var model
                            required property int index
                            readonly property bool inCurrentMonth: model.month === grid.month
                            readonly property bool isToday: model.year === clock.date.getFullYear() && model.month === clock.date.getMonth() && model.day === clock.date.getDate()
                            readonly property bool isSelected:
                                model.year === calendar.selectedDate.getFullYear()
                                && model.month === calendar.selectedDate.getMonth()
                                && model.day === calendar.selectedDate.getDate()
                            readonly property string dateKey: Qt.formatDate(
                                new Date(model.year, model.month, model.day), "yyyy-MM-dd")
                            readonly property int taskPriority: {
                                TodoistService.dataVersion
                                return TodoistService.dayPriorities[dateKey] || 0
                            }

                            width: grid.cellWidth
                            height: grid.cellHeight
                            color: isSelected
                                ? Styles.centerMenu.calendar.selected.color
                                : taskPriority > 0
                                    ? TodoistService.priorityColor(taskPriority)
                                    : "transparent"
                            opacity: inCurrentMonth ? 1.0 : Styles.centerMenu.calendar.outOfMonth.opacity
                            border.width: isToday ? Styles.centerMenu.calendar.today.borderWidth : 0
                            border.color: Styles.centerMenu.calendar.today.borderColor

                            BetterText {
                                anchors.centerIn: parent
                                text: model.day
                                color: parent.isSelected
                                    ? Styles.centerMenu.calendar.selected.textColor
                                    : parent.taskPriority >= 3
                                        ? Styles.centerMenu.calendar.taskDueTextColor
                                        : Styles.centerMenu.calendar.text.color
                                Component.onCompleted: centerMenu.applyCalendarDayStyle(this)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: grid.clicked(model.date)
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: middlePanel
                width: content.width / 3
                height: parent.height

                property bool showPrayerTimes: false

                Column {
                    id: middleColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Row {
                        id: middleHeaderRow
                        width: parent.width
                        spacing: (parent.width - middleHeaderTitle.width)/2 - middleToggleBtn.paintedWidth
                        leftPadding: (parent.width - middleHeaderTitle.width)/2

                        BetterText {
                            id: middleHeaderTitle
                            anchors.verticalCenter: parent.verticalCenter
                            renderType: Text.NativeRendering
                            text: middlePanel.showPrayerTimes
                                ? "Prayer Times"
                                : Qt.formatDate(calendar.selectedDate, "dddd MMM d")
                        }

                        BetterText {
                            id: middleToggleBtn
                            anchors.verticalCenter: parent.verticalCenter
                            text: middlePanel.showPrayerTimes ? "Tasks" : "Prayer"
                            property bool hovered: false
                            color: hovered
                                ? Styles.centerMenu.notifications.header.clear.hoverTextColor
                                : Styles.centerMenu.notifications.header.clear.color
                            font.family: Styles.fontFamily
                            font.pixelSize: Styles.pixelSize

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: middleToggleBtn.hovered = true
                                onExited: middleToggleBtn.hovered = false
                                onClicked: middlePanel.showPrayerTimes = !middlePanel.showPrayerTimes
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: parent.height - middleHeaderRow.height - middleColumn.spacing

                        Flickable {
                            anchors.fill: parent
                            visible: !middlePanel.showPrayerTimes
                            contentHeight: todoistTasks.implicitHeight
                            clip: true

                            Todoist {
                                id: todoistTasks
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                taskMaxWidth: parent.width
                                date: calendar.selectedDate
                            }
                        }

                        Flickable {
                            anchors.fill: parent
                            visible: middlePanel.showPrayerTimes
                            contentHeight: prayerTimesPanel.implicitHeight
                            clip: true

                            PrayerTimes {
                                id: prayerTimesPanel
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: notifications
                width: content.width / 3
                height: parent.height

                Column {
                    id: notifColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Row {
                        id: notifHeaderRow
                        width: parent.width
                        spacing: parent.width - notifTitle.width - clearLabel.paintedWidth

                        BetterText {
                            id: notifTitle
                            renderType: Text.NativeRendering
                            text: "Notifications"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        BetterText {
                            id: clearLabel
                            text: "Clear"
                            opacity: NotificationService.count > 0 ? 1 : 0.35
                            anchors.verticalCenter: parent.verticalCenter
                            property bool hovered: false
                            color: hovered && NotificationService.count > 0
                                ? Styles.centerMenu.notifications.header.clear.hoverTextColor
                                : Styles.centerMenu.notifications.header.clear.color
                            font.family: Styles.fontFamily
                            font.pixelSize: Styles.pixelSize

                            MouseArea {
                                anchors.fill: parent
                                enabled: NotificationService.count > 0
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: clearLabel.hovered = true
                                onExited: clearLabel.hovered = false
                                onClicked: NotificationService.dismissAll()
                            }
                        }
                    }

                    Rectangle {
                        id: notifList
                        width: parent.width
                        height: parent.height - notifHeaderRow.height - notifColumn.spacing
                        color: "transparent"
                        clip: true

                        BetterText {
                            id: notifEmptyLabel
                            anchors.centerIn: parent
                            visible: NotificationService.count === 0
                            text: "No notifications"
                        }

                        Flickable {
                            anchors.fill: parent
                            contentHeight: notifItems.height
                            clip: true
                            visible: NotificationService.count > 0

                            Column {
                                id: notifItems
                                width: notifList.width
                                spacing: 4

                                Repeater {
                                    model: NotificationService.list

                                    delegate: Rectangle {
                                        id: notifItem
                                        required property var modelData
                                        width: notifItems.width
                                        height: implicitHeight
                                        implicitHeight: notifBody.implicitHeight
                                            + Styles.centerMenu.notifications.item.padding.top
                                            + Styles.centerMenu.notifications.item.padding.bottom

                                        Rectangle {
                                            width: Styles.centerMenu.notifications.item.accentWidth
                                            height: parent.height - 8
                                            anchors.left: parent.left
                                            anchors.leftMargin: 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: centerMenu.urgencyAccent(modelData.urgency)
                                        }

                                        BetterText {
                                            id: dismissBtn
                                            text: "×"
                                            z: 1
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.topMargin: 2
                                            anchors.rightMargin: 4
                                            property bool hovered: false
                                            property color normalColor: "transparent"
                                            property color hoverColor: "transparent"
                                            color: hovered ? hoverColor : normalColor

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: dismissBtn.hovered = true
                                                onExited: dismissBtn.hovered = false
                                                onClicked: modelData.dismiss()
                                            }
                                        }

                                        Column {
                                            id: notifBody
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.topMargin: Styles.centerMenu.notifications.item.padding.top
                                            anchors.leftMargin: Styles.centerMenu.notifications.item.padding.left
                                            anchors.rightMargin: Styles.centerMenu.notifications.item.padding.right
                                            spacing: 2

                                            BetterText {
                                                id: notifAppName
                                                width: parent.width
                                                text: modelData.appName || "Unknown"
                                                elide: Text.ElideRight
                                            }
                                            BetterText {
                                                id: notifSummary
                                                width: parent.width
                                                text: modelData.summary
                                                elide: Text.ElideRight
                                            }
                                            BetterText {
                                                id: notifBodyText
                                                width: parent.width
                                                text: centerMenu.truncate(modelData.body, 80)
                                                elide: Text.ElideRight
                                                visible: modelData.body.length > 0
                                            }

                                            Row {
                                                id: actionsRow
                                                width: parent.width
                                                visible: modelData.actions.length > 0

                                                Repeater {
                                                    model: modelData.actions

                                                    delegate: Rectangle {
                                                        id: actionItem
                                                        required property var modelData
                                                        property bool hovered: false
                                                        property color normalColor: "transparent"
                                                        property color hoverColor: "transparent"
                                                        property int horizontalPadding: 0
                                                        color: hovered ? hoverColor : normalColor
                                                        width: actionLabel.paintedWidth + 2 * horizontalPadding

                                                        BetterText {
                                                            id: actionLabel
                                                            anchors.centerIn: parent
                                                            text: parent.modelData.text
                                                            property color normalColor: "transparent"
                                                            property color hoverColor: "transparent"
                                                            color: parent.hovered ? hoverColor : normalColor
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onEntered: parent.hovered = true
                                                            onExited: parent.hovered = false
                                                            onClicked: parent.modelData.invoke()
                                                        }

                                                        Component.onCompleted: centerMenu.applyNotificationActionStyles(
                                                            actionItem, actionLabel)
                                                    }
                                                }
                                            }
                                        }

                                        Component.onCompleted: centerMenu.applyNotificationItemStyles(
                                            notifItem, dismissBtn, actionsRow,
                                            notifAppName, notifSummary, notifBodyText)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
