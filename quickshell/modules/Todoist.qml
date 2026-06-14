import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../services"

Rectangle {
    id: todoist

    color: "transparent"

    property var date: null
    property int maxTasks: 0
    property int taskMaxWidth: Styles.todoist.taskMaxWidth
    property int rowSpacing: 3

    property var styleOverride: null
    
    ListModel {
        id: taskModel
    }

    function setTasks(tasks) {
        taskModel.clear()
        if (!tasks || !tasks.length)
            return

        const limit = maxTasks > 0 ? Math.min(tasks.length, maxTasks) : tasks.length
        for (let i = 0; i < limit; i++) {
            const task = tasks[i]
            taskModel.append({
                id: String(task.id),
                content: task.content || "",
                priority: task.priority || 1,
                closing: false
            })
        }
    }

    function applyLocalTasks() {
        if (!TodoistService.token) {
            setTasks([])
            return
        }
        setTasks(TodoistService.tasksForDate(date))
    }

    function completeTask(index) {
        taskModel.setProperty(index, "closing", true)

        TodoistService.completeTask(taskModel.get(index).id, function(success, message) {
            if (success)
                return

                taskModel.setProperty(index, "closing", false)
        })
    }

    Connections {
        target: TodoistService
        function onDataVersionChanged() {
            applyLocalTasks()
        }
    }

    Component.onCompleted: {
        Styler.apply(todoist, Styles.todoist)
        if (styleOverride)
            Styler.apply(todoist, styleOverride)
        applyLocalTasks()
    }

    onDateChanged: applyLocalTasks()

    Column {
        id: taskColumn
        width: todoist.taskMaxWidth
        spacing: todoist.rowSpacing

        Repeater {
            model: taskModel

            delegate: RowLayout {
                required property int index
                required property string content
                required property int priority
                required property bool closing

                width: taskColumn.width
                spacing: 6

                Item {
                    Layout.preferredWidth: checkLabel.paintedWidth
                    Layout.preferredHeight: checkLabel.paintedHeight

                    BetterText {
                        id: checkLabel
                        text: closing ? "◌" : "□"
                        opacity: closing ? 0.45 : 1
                        property bool hovered: false
                        Component.onCompleted: {
                            Styler.apply(checkLabel, Styles.todoist.task.check)
                            if (styleOverride)
                                Styler.apply(checkLabel, styleOverride.task?.check)
                        }
                        color: hovered
                            ? Styles.todoist.task.check.hoverColor
                            : TodoistService.priorityColor(priority)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !closing
                        onEntered: checkLabel.hovered = true
                        onExited: checkLabel.hovered = false
                        onClicked: todoist.completeTask(index)
                    }
                }

                BetterText {
                    Layout.fillWidth: true
                    text: content
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    opacity: closing ? 0.45 : 1
                    font.strikeout: closing
                    Component.onCompleted: {
                        Styler.apply(this, Styles.todoist.task.text)
                        if (styleOverride)
                            Styler.apply(this, styleOverride.task.text)
                    }
                }
            }
        }

        BetterText {
            visible: !TodoistService.loading && taskModel.count === 0 && !TodoistService.error
            text: "No tasks"
            Component.onCompleted: {
                Styler.apply(this, Styles.todoist.empty.text)
                if (styleOverride)
                    Styler.apply(this, styleOverride.empty.text)
            }
        }

        BetterText {
            visible: TodoistService.loading && taskModel.count === 0
            text: "…"
            Component.onCompleted: {
                Styler.apply(this, Styles.todoist.empty.text)
                if (styleOverride)
                    Styler.apply(this, styleOverride.empty.text)
            }
        }

        BetterText {
            visible: TodoistService.error.length > 0
            text: TodoistService.error
            wrapMode: Text.Wrap
            width: taskColumn.width
            Component.onCompleted: {
                Styler.apply(this, Styles.todoist.error.text)
                if (styleOverride)
                    Styler.apply(this, styleOverride.error.text)
            }
        }
    }

    implicitWidth: taskColumn.implicitWidth
    implicitHeight: taskColumn.implicitHeight
}
