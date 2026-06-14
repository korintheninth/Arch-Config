pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: notificationService

    readonly property var list: server.trackedNotifications
    readonly property int count: list.values.length
    property var popups: []

    NotificationServer {
        id: server

        imageSupported: true
        actionsSupported: true
        bodySupported: true

        onNotification: (notification) => {
            notification.tracked = true
            notificationService.showPopup(notification)
        }
    }

    function showPopup(notification) {
        popups = [...popups.filter(n => n.id !== notification.id), notification]
        const maxPopups = 5
        if (popups.length > maxPopups)
            popups = popups.slice(popups.length - maxPopups)
    }

    function hidePopup(notification) {
        popups = popups.filter(n => n !== notification)
    }

    function dismissAll() {
        const items = list.values
        for (let i = items.length - 1; i >= 0; i--)
            items[i].dismiss()
    }
}
