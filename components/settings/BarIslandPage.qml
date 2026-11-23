import QtQuick
import "../../Singletons"

/**
 * Bar & Island: the pill's clock, resting face, expansion and optional modules.
 * Grouped as reference-style cards rather than one long list.
 */
SettingsPage {
    id: root

    rows: {
        var base = [
            { item: timeRow, kind: "seg", vals: [false, true], get: function () { return Flags.time12h; }, set: function (v) { Flags.time12h = v; } },
            { item: secRow, kind: "toggle", get: function () { return Flags.clockSeconds; }, set: function (v) { Flags.clockSeconds = v; } },
            { item: glyphRow, kind: "toggle", get: function () { return Flags.showGlyphs; }, set: function (v) { Flags.showGlyphs = v; } }
        ];
        if (!Flags.showGlyphs)
            base.push({ item: iconRow, kind: "toggle", get: function () { return Flags.clockIcon; }, set: function (v) { Flags.clockIcon = v; } });
        base.push(
            { item: vizRow, kind: "toggle", get: function () { return Flags.musicViz; }, set: function (v) { Flags.musicViz = v; } },
            { item: expandRow, kind: "seg", vals: ["media", "pill"], get: function () { return Flags.expandTo; }, set: function (v) { Flags.expandTo = v; } },
            { item: dockRow, kind: "toggle", get: function () { return Flags.dockEnabled; }, set: function (v) { Flags.dockEnabled = v; } }
        );
        var mods = [
            [sysmonRow, "pillShowSysmon"], [recRow, "pillShowRecorder"], [timerRow, "pillShowTimer"],
            [wallRow, "pillShowWallpaper"], [scratchRow, "pillShowScratch"], [launchRow, "pillShowLauncher"],
            [emojiRow, "pillShowEmoji"], [trayRow, "pillShowFileTray"], [powerRow, "pillShowPower"]
        ];
        for (var i = 0; i < mods.length; i++) {
            (function (item, flag) {
                base.push({ item: item, kind: "toggle",
                    get: function () { return Flags[flag]; },
                    set: function (v) { Flags[flag] = v; } });
            })(mods[i][0], mods[i][1]);
        }
        return base;
    }

    SettingsCard {
        title: "Clock"

        SettingsCardRow {
            id: timeRow
            surface: root
            label: "Time format"
            sub: "The clock face on the resting pill"

            SettingsChoice {
                options: [{ label: "24-hour", value: false }, { label: "12-hour", value: true }]
                value: Flags.time12h
                onPicked: (v) => Flags.time12h = v
            }
        }

        SettingsCardRow {
            id: secRow
            surface: root
            label: "Clock seconds"

            SettingsSwitch {
                on: Flags.clockSeconds
                onToggled: Flags.clockSeconds = !Flags.clockSeconds
            }
        }

        SettingsCardRow {
            id: glyphRow
            surface: root
            label: "Japanese glyphs"
            sub: "Show the kanji marks in place of clock icons"

            SettingsSwitch {
                on: Flags.showGlyphs
                onToggled: Flags.showGlyphs = !Flags.showGlyphs
            }
        }

        SettingsCardRow {
            id: iconRow
            surface: root
            label: "Clock icon"
            sub: "Only available when the glyphs are off"
            visible: !Flags.showGlyphs

            SettingsSwitch {
                on: Flags.clockIcon
                onToggled: Flags.clockIcon = !Flags.clockIcon
            }
        }

        SettingsCardRow {
            id: vizRow
            surface: root
            label: "Music visualizer"
            last: true

            SettingsSwitch {
                on: Flags.musicViz
                onToggled: Flags.musicViz = !Flags.musicViz
            }
        }
    }

    SettingsCard {
        title: "Island"

        SettingsCardRow {
            id: expandRow
            surface: root
            label: "Expand"
            sub: "What the media card opens into"

            SettingsChoice {
                options: [{ label: "Media", value: "media" }, { label: "Full pill", value: "pill" }]
                value: Flags.expandTo
                onPicked: (v) => Flags.expandTo = v
            }
        }

        SettingsCardRow {
            id: dockRow
            surface: root
            label: "Dock"
            sub: "Show the bottom app bar"
            last: true

            SettingsSwitch {
                on: Flags.dockEnabled
                onToggled: Flags.dockEnabled = !Flags.dockEnabled
            }
        }
    }

    SettingsCard {
        title: "Modules"

        SettingsCardRow {
            id: sysmonRow
            surface: root
            label: "System monitor"

            SettingsSwitch { on: Flags.pillShowSysmon; onToggled: Flags.pillShowSysmon = !Flags.pillShowSysmon }
        }
        SettingsCardRow {
            id: recRow
            surface: root
            label: "Recorder"

            SettingsSwitch { on: Flags.pillShowRecorder; onToggled: Flags.pillShowRecorder = !Flags.pillShowRecorder }
        }
        SettingsCardRow {
            id: timerRow
            surface: root
            label: "Timer"

            SettingsSwitch { on: Flags.pillShowTimer; onToggled: Flags.pillShowTimer = !Flags.pillShowTimer }
        }
        SettingsCardRow {
            id: wallRow
            surface: root
            label: "Wallpaper"

            SettingsSwitch { on: Flags.pillShowWallpaper; onToggled: Flags.pillShowWallpaper = !Flags.pillShowWallpaper }
        }
        SettingsCardRow {
            id: scratchRow
            surface: root
            label: "Scratchpad"

            SettingsSwitch { on: Flags.pillShowScratch; onToggled: Flags.pillShowScratch = !Flags.pillShowScratch }
        }
        SettingsCardRow {
            id: launchRow
            surface: root
            label: "Launcher"

            SettingsSwitch { on: Flags.pillShowLauncher; onToggled: Flags.pillShowLauncher = !Flags.pillShowLauncher }
        }
        SettingsCardRow {
            id: emojiRow
            surface: root
            label: "Emoji"

            SettingsSwitch { on: Flags.pillShowEmoji; onToggled: Flags.pillShowEmoji = !Flags.pillShowEmoji }
        }
        SettingsCardRow {
            id: trayRow
            surface: root
            label: "File tray"

            SettingsSwitch { on: Flags.pillShowFileTray; onToggled: Flags.pillShowFileTray = !Flags.pillShowFileTray }
        }
        SettingsCardRow {
            id: powerRow
            surface: root
            label: "Power"
            last: true

            SettingsSwitch { on: Flags.pillShowPower; onToggled: Flags.pillShowPower = !Flags.pillShowPower }
        }
    }
}
