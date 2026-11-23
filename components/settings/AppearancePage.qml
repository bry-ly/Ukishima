import QtQuick
import "../../Singletons"

/**
 * Appearance: theme, accent, material, typography and the per-surface styles.
 * Complex editors (hue, accent, colour, font family) open as subpages and reuse
 * the existing implementations, so every flag keeps one source of truth.
 */
SettingsPage {
    id: root

    readonly property string themeMode: Flags.paletteMode === "static" ? "dark" : Flags.paletteMode
    readonly property string paletteLabel: {
        if (root.themeMode === "light") return "Light";
        if (root.themeMode === "dark") return "Dark";
        if (root.themeMode === "dynamic") return "Dynamic";
        if (root.themeMode === "manual") return "Manual";
        return "Dark";
    }
    readonly property string accentLabel: Flags.accentOverride.length > 0
        ? "Custom · " + Flags.accentOverride
        : "Follows theme"
    readonly property string textLabel: Flags.textOverride.length > 0
        ? "Custom · " + Flags.textOverride
        : "Follows theme"

    rows: {
        var base = [
            { item: themeRow, kind: "activate", activate: function () { root.requestPage("themeDetails"); } }
        ];
        if (root.themeMode === "dark")
            base.push({ item: oledRow, kind: "toggle", get: function () { return Flags.oled; }, set: function (v) { Flags.oled = v; } });
        base.push(
            { item: wallpaperRow, kind: "activate", activate: function () { root.requestPage("themeDetails"); } }
        );
        if (root.themeMode === "manual")
            base.push({ item: manualRow, kind: "activate", activate: function () { root.requestPage("themeDetails"); } });
        base.push(
            { item: accentRow, kind: "activate", activate: function () { root.requestPage("accentEditor"); } },
            { item: glassRow, kind: "toggle", get: function () { return Flags.glass; }, set: function (v) { Flags.glass = v; } },
            { item: contrastRow, kind: "seg", vals: [0, 0.5, 1], get: function () { return Flags.glassText; }, set: function (v) { Flags.glassText = v; } },
            { item: fontColourRow, kind: "activate", activate: function () { root.requestPage("fontColorEditor"); } },
            { item: fontRow, kind: "activate", activate: function () { root.requestPage("fontPicker"); } },
            { item: pillStyleRow, kind: "seg", vals: ["minimal", "classic", "system", "status", "strip"], get: function () { return Flags.mainDisplay; }, set: function (v) { Flags.mainDisplay = v; } },
            { item: mediaStyleRow, kind: "seg", vals: ["default", "rail", "sleeve", "ledger", "matrix", "title"], get: function () { return Flags.styleMedia; }, set: function (v) { Flags.styleMedia = v; } },
            { item: mixerStyleRow, kind: "seg", vals: ["default", "comb", "slats", "stipple", "weave"], get: function () { return Flags.styleMixer; }, set: function (v) { Flags.styleMixer = v; } },
            { item: sysmonStyleRow, kind: "seg", vals: ["default", "rail", "ledger", "matrix", "title"], get: function () { return Flags.styleSysmon; }, set: function (v) { Flags.styleSysmon = v; } },
            { item: scratchStyleRow, kind: "seg", vals: ["default", "cassette", "index", "console", "ash"], get: function () { return Flags.styleScratch; }, set: function (v) { Flags.styleScratch = v; } },
            { item: lockStyleRow, kind: "seg", vals: ["default", "relay", "folio", "editorial", "phase", "spine", "reactive"], get: function () { return Flags.styleLock; }, set: function (v) { Flags.styleLock = v; } }
        );
        return base;
    }

    SettingsCard {
        title: "Theme"

        SettingsCardRow {
            id: themeRow
            surface: root
            label: "Theme"
            sub: "Light, dark, dynamic or manual palette"

            SettingsAction {
                text: root.paletteLabel
                onTriggered: root.requestPage("themeDetails")
            }
        }

        SettingsCardRow {
            id: oledRow
            surface: root
            label: "OLED"
            sub: "Pure black surfaces while on Dark"
            visible: root.themeMode === "dark"

            SettingsSwitch { on: Flags.oled; onToggled: Flags.oled = !Flags.oled }
        }

        SettingsCardRow {
            id: wallpaperRow
            surface: root
            label: "Wallpaper"
            sub: Walls.wpDir
            last: root.themeMode !== "manual"

            SettingsAction {
                text: "Choose…"
                onTriggered: root.requestPage("themeDetails")
            }
        }

        SettingsCardRow {
            id: manualRow
            surface: root
            label: "Manual palette"
            sub: "Hue, saturation and exact hex"
            visible: root.themeMode === "manual"
            last: true

            SettingsAction {
                text: "Edit…"
                onTriggered: root.requestPage("themeDetails")
            }
        }
    }

    SettingsCard {
        title: "Accent"

        SettingsCardRow {
            id: accentRow
            surface: root
            label: "Accent colour"
            sub: "Override the warm accent for the whole pill"
            last: true

            SettingsAction {
                text: root.accentLabel
                onTriggered: root.requestPage("accentEditor")
            }
        }
    }

    SettingsCard {
        title: "Material"

        SettingsCardRow {
            id: glassRow
            surface: root
            label: "Transparency mode"
            sub: "Translucent pill · desktop shows through"

            SettingsSwitch { on: Flags.glass; onToggled: Flags.glass = !Flags.glass }
        }

        SettingsCardRow {
            id: contrastRow
            surface: root
            label: "Contrast"
            sub: "Extra contrast for copy on the glass"
            last: true

            SettingsChoice {
                options: [{ label: "Off", value: 0 }, { label: "Soft", value: 0.5 }, { label: "Strong", value: 1 }]
                value: Flags.glassText
                onPicked: (v) => Flags.glassText = v
            }
        }
    }

    SettingsCard {
        title: "Typography"

        SettingsCardRow {
            id: fontColourRow
            surface: root
            label: "Font colour"
            sub: "Recolour the primary text family"

            SettingsAction {
                text: root.textLabel
                onTriggered: root.requestPage("fontColorEditor")
            }
        }

        SettingsCardRow {
            id: fontRow
            surface: root
            label: "UI font"
            sub: "Family used by the shell"
            last: true

            SettingsAction {
                text: Theme.font
                boxed: true
                onTriggered: root.requestPage("fontPicker")
            }
        }
    }

    SettingsCard {
        title: "Surface styles"

        SettingsCardRow {
            id: pillStyleRow
            surface: root
            label: "Pill display"

            SettingsChoice {
                options: [
                    { label: "Minimal", value: "minimal" }, { label: "Classic", value: "classic" },
                    { label: "System", value: "system" }, { label: "Status", value: "status" },
                    { label: "Strip", value: "strip" }
                ]
                value: Flags.mainDisplay
                onPicked: (v) => Flags.mainDisplay = v
            }
        }

        SettingsCardRow {
            id: mediaStyleRow
            surface: root
            label: "Media player"

            SettingsChoice {
                options: [
                    { label: "Default", value: "default" }, { label: "Rail", value: "rail" },
                    { label: "Sleeve", value: "sleeve" }, { label: "Ledger", value: "ledger" },
                    { label: "Matrix", value: "matrix" }, { label: "Title", value: "title" }
                ]
                value: Flags.styleMedia
                onPicked: (v) => Flags.styleMedia = v
            }
        }

        SettingsCardRow {
            id: mixerStyleRow
            surface: root
            label: "Mixer"

            SettingsChoice {
                options: [
                    { label: "Default", value: "default" }, { label: "Comb", value: "comb" },
                    { label: "Slats", value: "slats" }, { label: "Stipple", value: "stipple" },
                    { label: "Weave", value: "weave" }
                ]
                value: Flags.styleMixer
                onPicked: (v) => Flags.styleMixer = v
            }
        }

        SettingsCardRow {
            id: sysmonStyleRow
            surface: root
            label: "System monitor"

            SettingsChoice {
                options: [
                    { label: "Default", value: "default" }, { label: "Rail", value: "rail" },
                    { label: "Ledger", value: "ledger" }, { label: "Matrix", value: "matrix" },
                    { label: "Title", value: "title" }
                ]
                value: Flags.styleSysmon
                onPicked: (v) => Flags.styleSysmon = v
            }
        }

        SettingsCardRow {
            id: scratchStyleRow
            surface: root
            label: "Scratchpad"

            SettingsChoice {
                options: [
                    { label: "Default", value: "default" }, { label: "Cassette", value: "cassette" },
                    { label: "Index", value: "index" }, { label: "Console", value: "console" },
                    { label: "Ash", value: "ash" }
                ]
                value: Flags.styleScratch
                onPicked: (v) => Flags.styleScratch = v
            }
        }

        SettingsCardRow {
            id: lockStyleRow
            surface: root
            label: "Lock screen"
            last: true

            SettingsChoice {
                options: [
                    { label: "Default", value: "default" }, { label: "Relay", value: "relay" },
                    { label: "Folio", value: "folio" }, { label: "Editorial", value: "editorial" },
                    { label: "Phase", value: "phase" }, { label: "Spine", value: "spine" },
                    { label: "Reactive", value: "reactive" }
                ]
                value: Flags.styleLock
                onPicked: (v) => Flags.styleLock = v
            }
        }
    }
}
