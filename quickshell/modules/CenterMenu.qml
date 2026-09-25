import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Controls
import Quickshell.Services.Notifications
import "../components"
import "../themes"
import "../services"

PopupWindow {
    id: centerMenu
    color: "transparent"
    readonly property int surfacePad: 2
    implicitHeight: content.height + 2 * surfacePad
    implicitWidth: content.width + 2 * surfacePad

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
        const s = Styles.notification.urgency
        if (urgency === NotificationUrgency.Critical)
            return s.critical
        return s.normal
    }

    Rectangle {
        id: content
        x: centerMenu.surfacePad
        y: -height
        readonly property int pad: Styles.centerMenu.padding
        readonly property int gap: Styles.centerMenu.spacing
        width: 2 * pad
            + Math.max(calendar.width, upComing.width)
            + gap
            + middlePanel.width
            + gap
            + notifications.width
        height: 2 * pad + Math.max(
            calendar.height + gap + Styles.centerMenu.upcoming.height,
            Math.max(middlePanel.height, notifications.height)
                + gap
                + mediaSection.implicitHeight
        )
        color: Styles.centerMenu.background.color
        border.width: Styles.centerMenu.background.border.width
        border.color: Styles.centerMenu.background.border.color
        radius: Styles.centerMenu.background.radius

        NumberAnimation {
            id: openAnim
            target: content
            property: "y"
            from: -content.height
            to: centerMenu.surfacePad
            duration: 300
            easing.type: Easing.OutQuart

            onFinished: {
                if (!centerMenu.open)
                    centerMenu.visible = false
            }
        }

        Connections {
            target: centerMenu
            function onOpenChanged() {
                if (centerMenu.open) {
                    content.y = -content.height
                    openAnim.from = -content.height
                    openAnim.to = centerMenu.surfacePad
                    openAnim.start()
                } else {
                    openAnim.from = content.y
                    openAnim.to = -content.height
                    openAnim.start()
                }
            }
        }

        Rectangle {
            id: calendar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Styles.centerMenu.padding
            anchors.topMargin: Styles.centerMenu.padding
            width: Styles.centerMenu.calendar.width
            height: Styles.centerMenu.calendar.height
            radius: Styles.centerMenu.calendar.radius
            color: Styles.centerMenu.calendar.color
            border.width: Styles.centerMenu.calendar.border.width
            border.color: Styles.centerMenu.calendar.border.color

            property int buttonWidth: Styles.centerMenu.calendar.navButton.width
            property int buttonHeight: Styles.centerMenu.calendar.navButton.height
            property int year: new Date().getFullYear()
            property int month: new Date().getMonth()
            property date selectedDate: new Date()

            Column {
                id: col
                anchors.fill: parent
                anchors.margins: 5
                spacing: 8

                Row {
                    id: controlRow
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: calendar.buttonWidth
                        height: calendar.buttonHeight
                        radius: Styles.centerMenu.calendar.navButton.radius
                        property bool hovered: false
                        color: hovered ? Styles.centerMenu.calendar.navButton.hoverColor : "transparent"

                        BetterText {
                            id: prevMonthLabel
                            anchors.centerIn: parent
                            text: "‹"
                            font.family: Styles.centerMenu.calendar.text.font.family
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
                        color: Styles.centerMenu.header.text.color
                        font: Qt.font({
                            family: Styles.centerMenu.calendar.text.font.family,
                            pixelSize: Styles.centerMenu.calendar.text.font.pixelSize
                        })
                        width: parent.width - 2 * calendar.buttonWidth - 2 * controlRow.spacing
                        text: Qt.formatDate(new Date(calendar.year, calendar.month, 1), "MMMM yyyy")
                    }

                    Rectangle {
                        width: calendar.buttonWidth
                        height: calendar.buttonHeight
                        radius: Styles.centerMenu.calendar.navButton.radius
                        property bool hovered: false
                        color: hovered ? Styles.centerMenu.calendar.navButton.hoverColor : "transparent"

                        BetterText {
                            id: nextMonthLabel
                            anchors.centerIn: parent
                            text: "›"
                            font.family: Styles.centerMenu.calendar.text.font.family
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
                        color: faded(Styles.centerMenu.calendar.dayOfWeek.color,
                                     Styles.centerMenu.calendar.dayOfWeek.opacity)
                        font.family: Styles.centerMenu.calendar.dayOfWeek.font.family
                        font.pixelSize: Styles.centerMenu.calendar.dayOfWeek.font.pixelSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
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
                    spacing: Styles.centerMenu.calendar.spacing
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
                        radius: Styles.centerMenu.calendar.selected.radius

                            BetterText {
                                anchors.centerIn: parent
                                text: model.day
                                font.family: Styles.centerMenu.calendar.text.font.family
                                color: parent.isSelected
                                    ? Styles.centerMenu.calendar.selected.textColor
                                    : parent.taskPriority >= 3
                                        ? Styles.centerMenu.calendar.highPriorityTextColor
                                        : Styles.centerMenu.calendar.text.color
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
            id: upComing
            anchors.left: calendar.left
            anchors.top: calendar.bottom
            anchors.topMargin: Styles.centerMenu.spacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Styles.centerMenu.padding
            width: Styles.centerMenu.upcoming.width
            radius: Styles.centerMenu.upcoming.radius
            color: Styles.centerMenu.upcoming.color
            border.width: Styles.centerMenu.upcoming.border.width
            border.color: Styles.centerMenu.upcoming.border.color

            readonly property string todayKey: Qt.formatDate(clock.date, "yyyy-MM-dd")

            ListModel {
                id: upcomingModel
            }

            function daysLeftLabel(days) {
                return days === 1 ? "1 day" : days + " days"
            }

            function applyUpcomingTasks() {
                upcomingModel.clear()
                if (!TodoistService.token)
                    return

                const tasks = TodoistService.upcomingNonRecurring(Styles.centerMenu.upcoming.daysAhead)
                for (let i = 0; i < tasks.length; i++) {
                    const task = tasks[i]
                    upcomingModel.append({
                        content: task.content || "",
                        daysLeft: TodoistService.daysBetween(upComing.todayKey, task.due.date)
                    })
                }
            }

            onTodayKeyChanged: applyUpcomingTasks()

            Connections {
                target: TodoistService
                function onDataVersionChanged() {
                    upComing.applyUpcomingTasks()
                }
            }

            Component.onCompleted: applyUpcomingTasks()

            Column {
                id: upcomingColumn
                anchors.fill: parent
                anchors.margins: Styles.centerMenu.upcoming.padding
                spacing: 6

                BetterText {
                    id: upcomingHeader
                    width: parent.width
                    text: Styles.centerMenu.upcoming.header.text
                    color: Styles.centerMenu.upcoming.header.color
                    horizontalAlignment: Text.AlignHCenter
                    font: Qt.font({
                        family: Styles.centerMenu.upcoming.header.font.family,
                        pixelSize: Styles.centerMenu.upcoming.header.font.pixelSize
                    })
                }

                Item {
                    width: parent.width
                    height: parent.height - upcomingHeader.height - upcomingColumn.spacing

                    BetterText {
                        anchors.centerIn: parent
                        visible: !TodoistService.loading && upcomingModel.count === 0 && !TodoistService.error
                        text: Styles.centerMenu.upcoming.empty.text
                        color: faded(Styles.centerMenu.upcoming.empty.color,
                                     Styles.centerMenu.upcoming.empty.opacity)
                        font.family: Styles.centerMenu.upcoming.task.text.font.family
                        font.pixelSize: Styles.centerMenu.upcoming.task.text.font.pixelSize
                    }

                    BetterText {
                        anchors.centerIn: parent
                        visible: TodoistService.loading && upcomingModel.count === 0
                        text: "…"
                        color: faded(Styles.centerMenu.upcoming.empty.color,
                                     Styles.centerMenu.upcoming.empty.opacity)
                        font.family: Styles.centerMenu.upcoming.task.text.font.family
                        font.pixelSize: Styles.centerMenu.upcoming.task.text.font.pixelSize
                    }

                    BetterText {
                        anchors.centerIn: parent
                        visible: TodoistService.error.length > 0 && upcomingModel.count === 0
                        width: parent.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        text: TodoistService.error
                        color: Styles.todoist.error.text.color
                        font.family: Styles.todoist.error.text.font.family
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: upcomingItems.height
                        clip: true
                        visible: upcomingModel.count > 0

                        Column {
                            id: upcomingItems
                            width: parent.width
                            spacing: Styles.centerMenu.upcoming.rowSpacing

                            Repeater {
                                model: upcomingModel

                                delegate: Row {
                                    required property string content
                                    required property int daysLeft

                                    width: upcomingItems.width
                                    spacing: Styles.centerMenu.upcoming.task.spacing

                                    BetterText {
                                        width: parent.width - upcomingDays.width - parent.spacing
                                        text: content
                                        elide: Text.ElideRight
                                        color: Styles.centerMenu.upcoming.task.text.color
                                        font.family: Styles.centerMenu.upcoming.task.text.font.family
                                        font.pixelSize: Styles.centerMenu.upcoming.task.text.font.pixelSize
                                    }

                                    BetterText {
                                        id: upcomingDays
                                        width: Styles.centerMenu.upcoming.task.days.width
                                        text: upComing.daysLeftLabel(daysLeft)
                                        horizontalAlignment: Text.AlignRight
                                        color: Styles.centerMenu.upcoming.task.days.color
                                        font.family: Styles.centerMenu.upcoming.task.days.font.family
                                        font.pixelSize: Styles.centerMenu.upcoming.task.days.font.pixelSize
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: middlePanel
            anchors.left: calendar.right
            anchors.top: parent.top
            anchors.leftMargin: Styles.centerMenu.spacing
            anchors.topMargin: Styles.centerMenu.padding
            width: Styles.centerMenu.middlePanel.width
            height: Styles.centerMenu.middlePanel.height
            color: Styles.centerMenu.middlePanel.background.color
            border.width: Styles.centerMenu.middlePanel.background.border.width
            border.color: Styles.centerMenu.middlePanel.background.border.color
            radius: Styles.centerMenu.middlePanel.background.radius

            property bool showPrayerTimes: false

            transform: Rotation {
                id: middleFlip
                origin.x: middlePanel.width / 2
                origin.y: middlePanel.height / 2
                axis.x: 0
                axis.y: 1
                axis.z: 0
                angle: 0
            }

            SequentialAnimation {
                id: middleFlipAnim

                NumberAnimation {
                    target: middleFlip
                    property: "angle"
                    from: 0
                    to: 90
                    duration: Styles.centerMenu.middlePanel.flip.duration / 2
                    easing.type: Easing.InCubic
                }

                ScriptAction {
                    script: middlePanel.showPrayerTimes = !middlePanel.showPrayerTimes
                }

                PropertyAction {
                    target: middleFlip
                    property: "angle"
                    value: -90
                }

                NumberAnimation {
                    target: middleFlip
                    property: "angle"
                    from: -90
                    to: 0
                    duration: Styles.centerMenu.middlePanel.flip.duration / 2
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 10
                anchors.bottomMargin: Styles.centerMenu.middlePanel.flip.button.anchors.bottomMargin

                Column {
                    id: middleColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: middleToggleBtn.top
                    spacing: Styles.centerMenu.middlePanel.spacing

                    BetterText {
                        id: middleHeaderTitle
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Styles.centerMenu.header.text.color
                        font: Qt.font({
                            family: Styles.centerMenu.header.text.font.family,
                            pixelSize: Styles.centerMenu.header.text.font.pixelSize
                        })
                        horizontalAlignment: Text.AlignHCenter
                        text: middlePanel.showPrayerTimes
                            ? "Prayer Times"
                            : Qt.formatDate(calendar.selectedDate, "dddd MMM d")
                    }

                    Item {
                        width: parent.width
                        height: parent.height - middleHeaderTitle.height - middleColumn.spacing

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
                                styleOverride: Styles.centerMenu.middlePanel.todoist.styleOverride
                            }
                        }

                        Flickable {
                            anchors.fill: parent
                            visible: middlePanel.showPrayerTimes
                            contentHeight: prayerTimesPanel.implicitHeight
                            clip: true

                            PrayerTimes {
                                id: prayerTimesPanel
                                anchors.fill: parent
                                anchors.centerIn: parent
                                styleOverride: Styles.centerMenu.middlePanel.prayerTimes.styleOverride
                            }
                        }
                    }
                }

                Button {
                    id: middleToggleBtn
                    readonly property int size: Styles.centerMenu.middlePanel.flip.button.size
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    implicitWidth: size
                    implicitHeight: size
                    width: size
                    height: size
                    padding: 0
                    horizontalPadding: 0
                    verticalPadding: 0
                    icon.width: size
                    icon.height: size
                    background.visible: false
                    icon.source: "../icons/Swap.svg"
                    icon.color: Styles.centerMenu.header.button.color
                    display: AbstractButton.IconOnly
                    enabled: !middleFlipAnim.running
                    onClicked: middleFlipAnim.start()
                }
            }
        }

        Rectangle {
            id: notifications
            anchors.left: middlePanel.right
            anchors.top: parent.top
            anchors.leftMargin: Styles.centerMenu.spacing
            anchors.topMargin: Styles.centerMenu.padding
            width: Styles.centerMenu.notifications.width
            height: Styles.centerMenu.notifications.height
            color: Styles.centerMenu.notifications.color
            border.width: Styles.centerMenu.notifications.border.width
            border.color: Styles.centerMenu.notifications.border.color
            radius: Styles.centerMenu.notifications.radius

            Column {
                id: notifColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Item {
                    id: notifHeaderRow
                    width: parent.width
                    height: notifTitle.height

                    BetterText {
                        id: notifTitle
                        text: "Notifications"
                        color: Styles.centerMenu.header.text.color
                        font: Qt.font({
                            family: Styles.centerMenu.header.text.font.family,
                            pixelSize: Styles.centerMenu.header.text.font.pixelSize
                        })
                        anchors.centerIn: parent
                    }

                    BetterText {
                        id: clearLabel
                        text: "Clear"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        property bool hovered: false
                        color: {
                            const base = hovered && NotificationService.count > 0
                                ? Styles.centerMenu.header.button.hoverTextColor
                                : Styles.centerMenu.header.button.color
                            return faded(base, NotificationService.count > 0 ? 1 : 0.35)
                        }
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
                        color: faded(Styles.centerMenu.notifications.empty.color,
                                     Styles.centerMenu.notifications.empty.opacity)
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
                                    color: Styles.notification.color
                                    radius: Styles.notification.radius
                                    clip: radius > 0
                                    border.width: Styles.notification.border.width
                                    border.color: Styles.notification.border.color
                                    implicitHeight: notifBody.implicitHeight
                                        + Styles.notification.padding.top
                                        + Styles.notification.padding.bottom

                                    Rectangle {
                                        width: Styles.notification.accentWidth
                                        height: parent.height - 8
                                        anchors.left: parent.left
                                        anchors.leftMargin: Styles.notification.accentLeftMargin
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: centerMenu.urgencyAccent(modelData.urgency)
                                    }

                                    BetterText {
                                        id: dismissBtn
                                        text: "×"
                                        z: 1
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: Styles.notification.dismiss.topMargin
                                        anchors.rightMargin: Styles.notification.dismiss.rightMargin
                                        property bool hovered: false
                                        property color normalColor: Styles.notification.dismiss.normalColor
                                        property color hoverColor: Styles.notification.dismiss.hoverColor
                                        color: hovered ? hoverColor : normalColor
                                        font.family: Styles.notification.dismiss.font.family
                                        font.pixelSize: Styles.notification.dismiss.font.pixelSize

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
                                        anchors.topMargin: Styles.notification.padding.top
                                        anchors.leftMargin: Styles.notification.padding.left
                                        anchors.rightMargin: Styles.notification.padding.right
                                        spacing: 2

                                        BetterText {
                                            id: notifAppName
                                            width: parent.width
                                            text: modelData.appName || "Unknown"
                                            elide: Text.ElideRight
                                            color: Styles.notification.appName.color
                                            font.family: Styles.notification.appName.font.family
                                            font.pixelSize: Styles.notification.appName.font.pixelSize
                                        }
                                        BetterText {
                                            id: notifSummary
                                            width: parent.width
                                            text: modelData.summary
                                            elide: Text.ElideRight
                                            color: Styles.notification.summary.color
                                            font.family: Styles.notification.summary.font.family
                                            font.bold: Styles.notification.summary.font.bold
                                        }
                                        BetterText {
                                            id: notifBodyText
                                            width: parent.width
                                            text: centerMenu.truncate(modelData.body, 80)
                                            elide: Text.ElideRight
                                            visible: modelData.body.length > 0
                                            color: faded(Styles.notification.body.color, Styles.notification.body.opacity)
                                            font.family: Styles.notification.body.font.family
                                            font.pixelSize: Styles.pixelSize
                                        }

                                        Row {
                                            id: actionsRow
                                            width: parent.width
                                            visible: modelData.actions.length > 0
                                            spacing: Styles.notification.actionsRow.spacing

                                            Repeater {
                                                model: modelData.actions

                                                delegate: Rectangle {
                                                    id: actionItem
                                                    required property var modelData
                                                    property bool hovered: false
                                                    property color normalColor: Styles.notification.action.normalColor
                                                    property color hoverColor: Styles.notification.action.hoverColor
                                                    property int horizontalPadding: Styles.notification.action.horizontalPadding
                                                    color: hovered ? hoverColor : normalColor
                                                    height: Styles.notification.action.height
                                                    border.width: Styles.notification.action.border.width
                                                    border.color: Styles.notification.action.border.color
                                                    width: actionLabel.paintedWidth + 2 * horizontalPadding

                                                    BetterText {
                                                        id: actionLabel
                                                        anchors.centerIn: parent
                                                        text: parent.modelData.text
                                                        property color normalColor: Styles.notification.action.text.normalColor
                                                        property color hoverColor: Styles.notification.action.text.hoverColor
                                                        color: parent.hovered ? hoverColor : normalColor
                                                        font.family: Styles.notification.action.text.font.family
                                                        font.pixelSize: Styles.notification.action.text.font.pixelSize
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onEntered: parent.hovered = true
                                                        onExited: parent.hovered = false
                                                        onClicked: parent.modelData.invoke()
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
            }
        }

        MediaPlayer {
            id: mediaSection
            anchors.left: middlePanel.left
            anchors.right: notifications.right
            anchors.top: middlePanel.bottom
            anchors.topMargin: Styles.centerMenu.spacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Styles.centerMenu.padding
        }
    }
}
