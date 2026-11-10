import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "niriMinimap"

    SelectionSetting {
        settingKey: "scope"
        label: "Workspace"
        description: "Which workspace the minimap follows"
        options: [
            {
                label: "Active on this monitor",
                value: "monitor"
            },
            {
                label: "Focused (any monitor)",
                value: "focused"
            }
        ]
        defaultValue: "monitor"
    }

    SliderSetting {
        settingKey: "maxWidth"
        label: "Maximum width"
        description: "Columns are squeezed horizontally once the minimap reaches this width"
        minimum: 60
        maximum: 1000
        defaultValue: 320
        unit: "px"
    }

    ToggleSetting {
        settingKey: "showIcons"
        label: "Show app icons"
        description: "Draw the app icon inside each window tile"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showFloating"
        label: "Show floating windows"
        description: "Append floating windows after the tiled columns"
        defaultValue: false
    }
}
