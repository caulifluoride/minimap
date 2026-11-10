import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Services

Rectangle {
    id: tile

    required property var win
    property var minimap: null
    property var tooltip: null

    readonly property bool active: minimap ? minimap.isActive(win) : win.is_focused
    readonly property var entry: DesktopEntries.heuristicLookup(Paths.moddedAppId(win.app_id ?? ""))

    radius: Math.min(Theme.cornerRadiusS, width / 4, height / 4)
    color: {
        if (win.is_urgent)
            return Theme.withAlpha(Theme.error, 0.55);
        if (active)
            return Theme.withAlpha(Theme.primary, win.is_focused ? 0.6 : 0.35);
        return Theme.withAlpha(Theme.widgetTextColor, tileMouse.containsMouse ? 0.3 : 0.15);
    }
    border.width: active ? 1 : 0
    border.color: Theme.primary

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: Math.min(parent.width, parent.height) * 0.7
        visible: (tile.minimap?.showIcons ?? true) && implicitSize >= 8
        source: Paths.getAppIcon(tile.win.app_id ?? "", tile.entry) || Quickshell.iconPath("application-x-executable", "image-missing")
        asynchronous: true
        opacity: tile.active ? 1 : 0.75
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                tile.minimap?.closeWindow(tile.win.id);
            else
                NiriService.focusWindow(tile.win.id);
        }
        onEntered: tile.tooltip?.show(tile.win.title || tile.win.app_id || "", tile, 0, 0)
        onExited: tile.tooltip?.hide()
    }
}
