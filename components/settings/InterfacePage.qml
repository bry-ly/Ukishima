import QtQuick
import "../../Singletons"

/**
 * Interface: layout scale, auto-hide, memory saver and the right-click walk.
 * The scale and gap rows use the reference's ticked sliders while still
 * writing the same discrete Flags values as the pill surfaces.
 */
SettingsPage {
    id: root

    readonly property var scales: [0.9, 1.0, 1.1, 1.25]
    readonly property var gaps: [0.25, 0.5, 1, 1.5]

    readonly property int scaleIndex: {
        var i = root.scales.indexOf(Flags.uiScale);
        return i >= 0 ? i : 1;
    }
    readonly property int gapIndex: {
        var i = root.gaps.indexOf(Flags.appGap);
        return i >= 0 ? i : 2;
    }

    function scalePct(v) {
        return Math.round(root.scales[Math.round(v)] * 100) + "%";
    }
    function gapPct(v) {
        return Math.round(root.gaps[Math.round(v)] * 100) + "%";
    }

    rows: [
        { item: scaleRow, kind: "seg", vals: [0, 1, 2, 3], get: function () { return root.scaleIndex; }, set: function (v) { Flags.uiScale = root.scales[Math.round(v)]; } },
        { item: autoHideRow, kind: "toggle", get: function () { return Flags.autoHide; }, set: function (v) { Flags.autoHide = v; } },
        { item: memoryRow, kind: "toggle", get: function () { return Flags.memorySaver; }, set: function (v) { Flags.memorySaver = v; } },
        { item: gapRow, kind: "seg", vals: [0, 1, 2, 3], get: function () { return root.gapIndex; }, set: function (v) { Flags.appGap = root.gaps[Math.round(v)]; } },
        { item: wsOsdRow, kind: "seg", vals: ["auto", "always", "off"], get: function () { return Flags.workspaceOsd; }, set: function (v) { Flags.workspaceOsd = v; } },
        { item: clickRow, kind: "activate", activate: function () { root.requestPage("rightClickDetails"); } }
    ]

    SettingsCard {
        title: "Layout"

        SettingsSliderRow {
            id: scaleRow
            surface: root
            label: "UI scale"
            from: 0
            to: 3
            stepSize: 1
            tickCount: 4
            value: root.scaleIndex
            format: root.scalePct
            onMoved: (v) => Flags.uiScale = root.scales[Math.round(v)]
        }

        SettingsCardRow {
            id: autoHideRow
            surface: root
            label: "Auto hide"
            sub: "Retract the island when the pointer leaves"

            SettingsSwitch { on: Flags.autoHide; onToggled: Flags.autoHide = !Flags.autoHide }
        }

        SettingsCardRow {
            id: memoryRow
            surface: root
            label: "Memory saver"
            sub: "Release closed surfaces after their idle tail"

            SettingsSwitch { on: Flags.memorySaver; onToggled: Flags.memorySaver = !Flags.memorySaver }
        }

        SettingsSliderRow {
            id: gapRow
            surface: root
            label: "Window gap"
            from: 0
            to: 3
            stepSize: 1
            tickCount: 4
            value: root.gapIndex
            format: root.gapPct
            last: true
            onMoved: (v) => Flags.appGap = root.gaps[Math.round(v)]
        }
    }

    SettingsCard {
        title: "On-screen display"

        SettingsCardRow {
            id: wsOsdRow
            surface: root
            label: "Workspace OSD"
            sub: "Auto hides it while the Status pill face shows the workspace bars"
            last: true

            SettingsChoice {
                options: [
                    { label: "Auto", value: "auto" },
                    { label: "Always", value: "always" },
                    { label: "Off", value: "off" }
                ]
                value: Flags.workspaceOsd
                onPicked: (v) => Flags.workspaceOsd = v
            }
        }
    }

    SettingsCard {
        title: "Right-click"

        SettingsCardRow {
            id: clickRow
            surface: root
            label: "Walk stops"
            sub: "Choose the 4th and 5th surface after the media card and timer"
            last: true

            SettingsAction {
                text: "Configure…"
                onTriggered: root.requestPage("rightClickDetails")
            }
        }
    }
}
