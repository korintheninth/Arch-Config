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

    function applyTaskRowStyles(checkLabel, taskText) {
        Styler.apply(checkLabel, Styles.todoist.task.check)
        Styler.apply(taskText, Styles.todoist.task.text)
        if (styleOverride) {
            Styler.apply(checkLabel, styleOverride.task?.check)
            Styler.apply(taskText, styleOverride.task?.text)
        }
    }

    Component.onCompleted: {
        Styler.apply(todoist, Styles.todoist)
        if (styleOverride)
            Styler.apply(todoist, styleOverride)
        Styler.apply(emptyLabel, Styles.todoist.empty.text)
        Styler.apply(loadingLabel, Styles.todoist.empty.text)
        Styler.apply(errorLabel, Styles.todoist.error.text)
        if (styleOverride) {
            Styler.apply(emptyLabel, styleOverride.empty?.text)
            Styler.apply(loadingLabel, styleOverride.empty?.text)
            Styler.apply(errorLabel, styleOverride.error?.text)
        }
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
                    id: taskText
                    Layout.fillWidth: true
                    text: content
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    opacity: closing ? 0.45 : 1
                    font.strikeout: closing
                }

                Component.onCompleted: todoist.applyTaskRowStyles(checkLabel, taskText)
            }
        }

        BetterText {
            id: emptyLabel
            visible: !TodoistService.loading && taskModel.count === 0 && !TodoistService.error
            text: "No tasks"
        }

        BetterText {
            id: loadingLabel
            visible: TodoistService.loading && taskModel.count === 0
            text: "…"
        }

        BetterText {
            id: errorLabel
            visible: TodoistService.error.length > 0
            text: TodoistService.error
            wrapMode: Text.Wrap
            width: taskColumn.width
        }
    }

    implicitWidth: taskColumn.implicitWidth
    implicitHeight: taskColumn.implicitHeight
}
