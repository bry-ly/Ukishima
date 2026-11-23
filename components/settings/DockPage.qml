import QtQuick
import "../../Singletons"

/**
 * Dock: behavior, appearance, pinned apps and motion. Behavior controls write
 * the dock's own flags; theme and app management open on the existing pages so
 * the dock keeps its separate palette and pin logic.
 */
SettingsPage {
    id: root

    readonly property var scales: [0.9, 1.0, 1.1, 1.25]
    readonly property var gaps: [0.25, 0.5, 1, 1.5]
    readonly property string themeShown: (Flags.dockTheme === "auto" || Flags.dockTheme === "transparent")
        ? "dark" : Flags.dockTheme
    readonly property string themeLabel: {
        if (root.themeShown === "light") return "Light";
        if (root.themeShown === "dark") return "Dark";
        if (root.themeShown === "dynamic") return "Dynamic";
        return "Manual";
    }
    readonly property int scaleIndex: {
        var i = root.scales.indexOf(Flags.dockUiScale);
        return i >= 0 ? i : 1;
    }
    readonly property int gapIndex: {
        var i = root.gaps.indexOf(Flags.dockGap);
        return i >= 0 ? i : 2;
    }
    readonly property string pinText: DockPins.pins.length === 0
        ? "Choose apps"
        : DockPins.pins.length + (DockPins.pins.length === 1 ? " app pinned" : " apps pinned")

    function scalePct(v) { return Math.round(root.scales[Math.round(v)] * 100) + "%"; }
    function gapPct(v) { return Math.round(root.gaps[Math.round(v)] * 100) + "%"; }

    rows: {
        var base = [
            { item: autoHideRow, kind: "toggle", get: function () { return Flags.dockAutoHide; }, set: function (v) { Flags.dockAutoHide = v; } },
            { item: scaleRow, kind: "seg", vals: [0, 1, 2, 3], get: function () { return root.scaleIndex; }, set: function (v) { Flags.dockUiScale = root.scales[Math.round(v)]; } },
            { item: gapRow, kind: "seg", vals: [0, 1, 2, 3], get: function () { return root.gapIndex; }, set: function (v) { Flags.dockGap = root.gaps[Math.round(v)]; } },
            { item: minimalRow, kind: "toggle", get: function () { return Flags.dockMinimal; }, set: function (v) { Flags.dockMinimal = v; } },
            { item: themeRow, kind: "activate", activate: function () { root.requestPage("dockThemeDetails"); } }
        ];
        if (root.themeShown === "dark")
            base.push({ item: oledRow, kind: "toggle", get: function () { return Flags.dockOled; }, set: function (v) { Flags.dockOled = v; } });
        base.push(
            { item: glassRow, kind: "seg", vals: ["transparent", "solid"], get: function () { return Flags.dockStyle; }, set: function (v) { Flags.dockStyle = v; } }
        );
        if (root.themeShown === "manual")
            base.push({ item: manualRow, kind: "activate", activate: function () { root.requestPage("dockThemeDetails"); } });
        base.push(
            { item: appsRow, kind: "activate", activate: function () { root.requestPage("dockApps"); } },
            { item: motionRow, kind: "seg", vals: ["standard", "snap", "float", "bounce"], get: function () { return Flags.dockMotionStyle; }, set: function (v) { Flags.dockMotionStyle = v; } }
        );
        return base;
    }

    SettingsCard {
        title: "Behavior"

        SettingsCardRow {
            id: autoHideRow
            surface: root
            label: "Auto-hide"
            sub: "Slide below the screen edge until the pointer finds it"

            SettingsSwitch { on: Flags.dockAutoHide; onToggled: Flags.dockAutoHide = !Flags.dockAutoHide }
        }

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
            onMoved: (v) => Flags.dockUiScale = root.scales[Math.round(v)]
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
            onMoved: (v) => Flags.dockGap = root.gaps[Math.round(v)]
        }

        SettingsCardRow {
            id: minimalRow
            surface: root
            label: "Minimal dock"
            sub: "Icon-only chips with the small active dot"
            last: true

            SettingsSwitch { on: Flags.dockMinimal; onToggled: Flags.dockMinimal = !Flags.dockMinimal }
        }
    }

    SettingsCard {
        title: "Appearance"

        SettingsCardRow {
            id: themeRow
            surface: root
            label: "Dock theme"

            SettingsAction {
                text: root.themeLabel
                onTriggered: root.requestPage("dockThemeDetails")
            }
        }

        SettingsCardRow {
            id: oledRow
            surface: root
            label: "OLED"
            sub: "Pure black dock surfaces"
            visible: root.themeShown === "dark"

            SettingsSwitch { on: Flags.dockOled; onToggled: Flags.dockOled = !Flags.dockOled }
        }

        SettingsCardRow {
            id: glassRow
            surface: root
            label: "Dock glass"
            last: root.themeShown !== "manual"

            SettingsChoice {
                options: [{ label: "Transparent", value: "transparent" }, { label: "Solid", value: "solid" }]
                value: Flags.dockStyle
                onPicked: (v) => Flags.dockStyle = v
            }
        }

        SettingsCardRow {
            id: manualRow
            surface: root
            label: "Manual hue"
            sub: "Dock palette from your own hue"
            visible: root.themeShown === "manual"
            last: true

            SettingsAction {
                text: "Edit…"
                onTriggered: root.requestPage("dockThemeDetails")
            }
        }
    }

    SettingsCard {
        title: "Apps"

        SettingsCardRow {
            id: appsRow
            surface: root
            label: "Pinned apps"
            sub: "Search installed applications and reorder the dock"
            last: true

            SettingsAction {
                text: root.pinText
                onTriggered: root.requestPage("dockApps")
            }
        }
    }

    SettingsCard {
        title: "Motion"

        SettingsCardRow {
            id: motionRow
            surface: root
            label: "Style"
            sub: "The dock's own animation feel"
            last: true

            SettingsChoice {
                options: [
                    { label: "Standard", value: "standard" }, { label: "Snap", value: "snap" },
                    { label: "Float", value: "float" }, { label: "Bounce", value: "bounce" }
                ]
                value: Flags.dockMotionStyle
                onPicked: (v) => Flags.dockMotionStyle = v
            }
        }
    }
}
