import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../themes"
import "../services"

Rectangle {
    id: todoist

    color: styleOverride?.color ?? Styles.todoist.color
    radius: styleOverride?.radius ?? Styles.todoist.radius

    property var date: null
    property int maxTasks: 0
    property int taskMaxWidth: styleOverride?.taskMaxWidth ?? Styles.todoist.taskMaxWidth
    property int rowSpacing: styleOverride?.rowSpacing ?? Styles.todoist.rowSpacing

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

    Component.onCompleted: applyLocalTasks()

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
                        property bool hovered: false
                        color: {
                            const base = hovered
                                ? (todoist.styleOverride?.task?.check?.hoverColor ?? Styles.todoist.task.check.hoverColor)
                                : TodoistService.priorityColor(priority)
                            return faded(base, closing ? 0.45 : 1)
                        }
                        font.family: todoist.styleOverride?.task?.check?.font?.family ?? Styles.todoist.task.check.font.family
                        font.bold: todoist.styleOverride?.task?.check?.font?.bold ?? Styles.todoist.task.check.font.bold
                        font.pixelSize: todoist.styleOverride?.task?.check?.font?.pixelSize ?? Styles.todoist.task.check.font.pixelSize
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
                    font.strikeout: closing
                    color: faded(
                        todoist.styleOverride?.task?.text?.color ?? Styles.todoist.task.text.color,
                        closing ? 0.45 : 1
                    )
                    font.family: todoist.styleOverride?.task?.text?.font?.family ?? Styles.todoist.task.text.font.family
                    font.bold: todoist.styleOverride?.task?.text?.font?.bold ?? Styles.todoist.task.text.font.bold
                    font.pixelSize: todoist.styleOverride?.task?.text?.font?.pixelSize ?? Styles.todoist.task.text.font.pixelSize
                }
            }
        }

        BetterText {
            id: emptyLabel
            visible: !TodoistService.loading && taskModel.count === 0 && !TodoistService.error
            text: "No tasks"
            color: todoist.styleOverride?.empty?.text?.color ?? Styles.todoist.empty.text.color
            font.family: todoist.styleOverride?.empty?.text?.font?.family ?? Styles.todoist.empty.text.font.family
            font.bold: todoist.styleOverride?.empty?.text?.font?.bold ?? Styles.todoist.empty.text.font.bold
        }

        BetterText {
            id: loadingLabel
            visible: TodoistService.loading && taskModel.count === 0
            text: "…"
            color: todoist.styleOverride?.empty?.text?.color ?? Styles.todoist.empty.text.color
            font.family: todoist.styleOverride?.empty?.text?.font?.family ?? Styles.todoist.empty.text.font.family
            font.bold: todoist.styleOverride?.empty?.text?.font?.bold ?? Styles.todoist.empty.text.font.bold
        }

        BetterText {
            id: errorLabel
            visible: TodoistService.error.length > 0
            text: TodoistService.error
            wrapMode: Text.Wrap
            width: taskColumn.width
            color: todoist.styleOverride?.error?.text?.color ?? Styles.todoist.error.text.color
            font.family: todoist.styleOverride?.error?.text?.font?.family ?? Styles.todoist.error.text.font.family
            font.bold: todoist.styleOverride?.error?.text?.font?.bold ?? Styles.todoist.error.text.font.bold
        }
    }

    implicitWidth: taskColumn.implicitWidth
    implicitHeight: taskColumn.implicitHeight
}
