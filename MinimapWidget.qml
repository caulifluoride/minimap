import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "niri-minimap"

    readonly property string scope: pluginData.scope ?? "monitor"
    readonly property bool showIcons: pluginData.showIcons ?? true
    readonly property bool showFloating: pluginData.showFloating ?? false
    readonly property int maxWidth: pluginData.maxWidth ?? 320
    readonly property int tileGap: 2

    readonly property string outputName: parentScreen?.name ?? NiriService.currentOutput

    readonly property var targetWorkspace: {
        const all = Object.values(NiriService.workspaces);
        if (scope === "focused")
            return all.find(ws => ws.is_focused) ?? null;
        return all.find(ws => ws.output === outputName && ws.is_active) ?? all.find(ws => ws.is_focused) ?? null;
    }

    readonly property var targetOutput: targetWorkspace ? NiriService.outputs[targetWorkspace.output] : null
    readonly property real outputWidth: targetOutput?.logical?.width ?? 1920
    readonly property real outputHeight: targetOutput?.logical?.height ?? 1080

    // Tiled windows grouped into columns by pos_in_scrolling_layout, rows sorted top to bottom.
    readonly property var columns: {
        const ws = targetWorkspace;
        if (!ws)
            return [];
        const byColumn = {};
        for (const w of NiriService.windows) {
            if (w.workspace_id !== ws.id || w.is_floating)
                continue;
            const pos = w.layout?.pos_in_scrolling_layout;
            if (!pos)
                continue;
            if (!byColumn[pos[0]])
                byColumn[pos[0]] = [];
            byColumn[pos[0]].push(w);
        }
        return Object.keys(byColumn).map(Number).sort((a, b) => a - b).map(index => {
            const wins = byColumn[index].sort((a, b) => a.layout.pos_in_scrolling_layout[1] - b.layout.pos_in_scrolling_layout[1]);
            return {
                "index": index,
                "width": Math.max(...wins.map(w => w.layout.tile_size[0])),
                "totalHeight": wins.reduce((sum, w) => sum + w.layout.tile_size[1], 0),
                "windows": wins
            };
        });
    }

    readonly property var floatingWindows: {
        const ws = targetWorkspace;
        if (!ws || !showFloating)
            return [];
        return NiriService.windows.filter(w => w.workspace_id === ws.id && w.is_floating);
    }

    function isActive(w) {
        return w.is_focused || targetWorkspace?.active_window_id === w.id;
    }

    function closeWindow(id) {
        NiriService.send({
            "Action": {
                "CloseWindow": {
                    "id": id
                }
            }
        });
    }

    pillRightClickAction: () => NiriService.toggleOverview()

    DTooltipV2 {
        id: tooltip
    }

    horizontalBarPill: Component {
        Item {
            id: map

            readonly property real mapHeight: Math.max(8, root.widgetThickness * 0.62)
            readonly property real naturalScale: mapHeight / root.outputHeight
            readonly property real gapsWidth: Math.max(0, root.columns.length - 1) * root.tileGap
            readonly property real naturalWidth: root.columns.reduce((sum, c) => sum + c.width * naturalScale, 0)
            readonly property real floatingWidth: root.floatingWindows.length > 0 ? root.floatingWindows.length * (mapHeight * 0.6 + root.tileGap) + Theme.spacingXS : 0
            readonly property real budget: Math.max(16, root.maxWidth - gapsWidth - floatingWidth)
            // Compress horizontally (keeping bar height) once the strip exceeds the configured width.
            readonly property real xScale: naturalWidth > budget ? naturalScale * budget / naturalWidth : naturalScale

            implicitHeight: mapHeight
            implicitWidth: root.columns.length === 0 && root.floatingWindows.length === 0 ? mapHeight * root.outputWidth / root.outputHeight : tiled.width + floatingWidth

            // Empty workspace: faint outline of the screen.
            Rectangle {
                anchors.fill: parent
                visible: root.columns.length === 0 && root.floatingWindows.length === 0
                color: "transparent"
                radius: Theme.cornerRadiusS
                border.width: 1
                border.color: Theme.withAlpha(Theme.widgetTextColor, 0.25)
            }

            Row {
                id: tiled
                height: parent.height
                spacing: root.tileGap

                Repeater {
                    model: root.columns

                    Column {
                        id: col

                        required property var modelData

                        width: Math.max(3, modelData.width * map.xScale)
                        height: map.mapHeight
                        spacing: root.tileGap

                        Behavior on width {
                            enabled: !SettingsData.reduceMotion
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }

                        Repeater {
                            model: col.modelData.windows

                            WindowTile {
                                required property var modelData
                                win: modelData
                                minimap: root
                                tooltip: tooltip
                                width: col.width
                                // Rows split the column proportionally; tabbed columns end up evenly split.
                                height: Math.max(2, (col.height - (col.modelData.windows.length - 1) * root.tileGap) * modelData.layout.tile_size[1] / col.modelData.totalHeight)
                            }
                        }
                    }
                }
            }

            Row {
                x: tiled.width + Theme.spacingXS
                height: parent.height
                spacing: root.tileGap
                visible: root.floatingWindows.length > 0

                Repeater {
                    model: root.floatingWindows

                    WindowTile {
                        required property var modelData
                        win: modelData
                        minimap: root
                        tooltip: tooltip
                        width: map.mapHeight * 0.6
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.85
                    }
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x;
                    if (delta > 0)
                        NiriService.focusColumnLeft(root.targetWorkspace?.output);
                    else if (delta < 0)
                        NiriService.focusColumnRight(root.targetWorkspace?.output);
                }
            }
        }
    }
}
