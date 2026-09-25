import QtQuick
import "../themes"
import "../services"

Item {
    id: scope

    property int displaySize: Styles.vectorscope.displaySize
    implicitWidth: displaySize
    implicitHeight: displaySize
    clip: true

    property color traceColor: Styles.vectorscope.color
    property color backgroundColor: Styles.vectorscope.background
    property bool running: true
    property bool _held: false

    function syncHold() {
        const want = running && visible
        if (want === _held)
            return
        if (want) {
            VectorscopeService.color = traceColor
            VectorscopeService.retain()
        } else {
            VectorscopeService.release()
        }
        _held = want
    }

    onTraceColorChanged: {
        if (_held)
            VectorscopeService.color = traceColor
    }
    onRunningChanged: syncHold()
    onVisibleChanged: syncHold()
    Component.onCompleted: syncHold()
    Component.onDestruction: {
        if (_held)
            VectorscopeService.release()
    }

    Rectangle {
        anchors.fill: parent
        color: scope.backgroundColor
    }

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        asynchronous: false
        sourceSize.width: VectorscopeService.bufferSize
        sourceSize.height: VectorscopeService.bufferSize
        source: VectorscopeService.frameSource
    }
}
