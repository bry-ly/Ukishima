import QtQuick
import "../../Singletons"

/** Lock screen: the full editor lives on a subpage; indicators are direct. */
SettingsPage {
    id: root

    readonly property string methodLabel: {
        if (Flags.lockMethod === "hyprlock") return "Hyprlock";
        if (Flags.lockMethod === "swaylock") return "swaylock";
        return "Quickshell";
    }

    rows: [
        { item: lockRow, kind: "activate", activate: function () { root.requestPage("lockDetails"); } },
        { item: avatarRow, kind: "toggle", get: function () { return Flags.lockShowAvatar; }, set: function (v) { Flags.lockShowAvatar = v; } },
        { item: wifiRow, kind: "toggle", get: function () { return Flags.lockShowWifi; }, set: function (v) { Flags.lockShowWifi = v; } },
        { item: batteryRow, kind: "toggle", get: function () { return Flags.lockShowBattery; }, set: function (v) { Flags.lockShowBattery = v; } },
        { item: mediaRow, kind: "toggle", get: function () { return Flags.lockShowMedia; }, set: function (v) { Flags.lockShowMedia = v; } }
    ]

    SettingsCard {
        title: "Lock screen"

        SettingsCardRow {
            id: lockRow
            surface: root
            label: "Method & backdrop"
            sub: root.methodLabel + " · capture, wallpaper or solid"
            last: true

            SettingsAction {
                text: "Configure…"
                onTriggered: root.requestPage("lockDetails")
            }
        }
    }

    SettingsCard {
        title: "Indicators"

        SettingsCardRow {
            id: avatarRow
            surface: root
            label: "Avatar"
            sub: "Profile image above the username"

            SettingsSwitch { on: Flags.lockShowAvatar; onToggled: Flags.lockShowAvatar = !Flags.lockShowAvatar }
        }

        SettingsCardRow {
            id: wifiRow
            surface: root
            label: "Wi-Fi"
            sub: "Connection indicator on the lock surface"

            SettingsSwitch { on: Flags.lockShowWifi; onToggled: Flags.lockShowWifi = !Flags.lockShowWifi }
        }

        SettingsCardRow {
            id: batteryRow
            surface: root
            label: "Battery"
            sub: "Charge and profile indicator"

            SettingsSwitch { on: Flags.lockShowBattery; onToggled: Flags.lockShowBattery = !Flags.lockShowBattery }
        }

        SettingsCardRow {
            id: mediaRow
            surface: root
            label: "Media player"
            sub: "Now-playing card under the clock"
            last: true

            SettingsSwitch { on: Flags.lockShowMedia; onToggled: Flags.lockShowMedia = !Flags.lockShowMedia }
        }
    }
}
