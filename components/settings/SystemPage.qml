import QtQuick
import Quickshell
import "../../Singletons"

/** System: updater/dependency checks and the read-only system profile. */
SettingsPage {
    id: root

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP")
        || (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "Hyprland" : "")

    rows: [
        { item: updateRow, kind: "activate", activate: function () { root.requestPage("updateDetails"); } },
        { item: profileRow, kind: "activate", activate: function () { root.requestPage("profileDetails"); } }
    ]

    SettingsCard {
        title: "Updates"

        SettingsCardRow {
            id: updateRow
            surface: root
            label: "Ukishima"
            sub: "Check for a newer release and verify dependencies"
            last: true

            SettingsAction {
                text: "Open…"
                onTriggered: root.requestPage("updateDetails")
            }
        }
    }

    SettingsCard {
        title: "Profile"

        SettingsCardRow {
            id: profileRow
            surface: root
            label: root.userName.length > 0 ? root.userName : "This machine"
            sub: root.wmName.length > 0 ? root.wmName + " · kernel, CPU, GPU and storage" : "Kernel, CPU, GPU and storage"
            last: true

            SettingsAction {
                text: "View…"
                onTriggered: root.requestPage("profileDetails")
            }
        }
    }
}
