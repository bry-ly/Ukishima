import QtQuick
import Quickshell.Widgets
import "../../Singletons"
import ".."

/**
 * Profile — a read-only identity and system page.
 *
 * References:
 *   - macOS General > About: identity-first hero with the important hardware
 *     facts close together.
 *   - GNOME Settings > System > About: device name, OS, kernel, processor,
 *     memory and disk as the canonical system facts.
 *   - JAQC-shell (Quickshell): treating User info and About as first-class
 *     settings destinations inside the shell's own settings window.
 *
 * All values come from SystemInfo; this page never writes system state.
 */
SettingsPage {
    id: root

    rows: []

    Component.onCompleted: SystemInfo.refresh()

    readonly property string sessionLabel: {
        const value = SystemInfo.sessionType;
        return value.length > 0 ? value.charAt(0).toUpperCase() + value.slice(1) : "";
    }
    readonly property string themeLabel: {
        const mode = Flags.paletteMode === "static" ? "dark" : Flags.paletteMode;
        if (mode === "light") return "Light";
        if (mode === "dark") return "Dark";
        if (mode === "dynamic") return "Dynamic";
        if (mode === "manual") return "Manual";
        return "Dark";
    }
    readonly property string accentLabel: Flags.accentOverride.length > 0
        ? "Custom · " + Flags.accentOverride
        : "Follows theme"
    readonly property string scaleLabel: Math.round(Flags.uiScale * 100) + "%"
    readonly property string motionLabel: {
        const style = Flags.motionStyle;
        return style.length > 0 ? style.charAt(0).toUpperCase() + style.slice(1) : "Standard";
    }
    readonly property var chips: {
        var out = [];
        if (SystemInfo.distro.length > 0)
            out.push(SystemInfo.distro);
        if (SystemInfo.wmName.length > 0)
            out.push(SystemInfo.wmName);
        if (root.sessionLabel.length > 0)
            out.push(root.sessionLabel);
        out.push("Ukishima");
        return out;
    }

    // ── Identity hero ─────────────────────────────────────────────────────

    SettingsCard {
        Item {
            id: hero

            width: parent.width
            implicitHeight: Math.max(avatarRing.height + 32 * root.s,
                identity.implicitHeight + 32 * root.s,
                avatarAction.height + 32 * root.s)

            Rectangle {
                id: avatarRing

                x: 16 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 88 * root.s
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.vermLit, 0.12)
                border.width: 1
                border.color: Qt.alpha(Theme.vermLit, 0.28)

                ClippingRectangle {
                    anchors.centerIn: parent
                    width: 76 * root.s
                    height: width
                    radius: width / 2
                    color: Theme.frameBg

                    Image {
                        id: face

                        anchors.fill: parent
                        source: SystemInfo.facePath.length > 0 ? "file://" + SystemInfo.facePath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                        sourceSize: Qt.size(168 * root.s, 168 * root.s)
                    }

                    GlyphIcon {
                        anchors.centerIn: parent
                        visible: !face.visible
                        width: 30 * root.s
                        height: width
                        name: "user"
                        color: Theme.faint
                        stroke: 1.4
                    }
                }
            }

            Column {
                id: identity

                anchors.left: avatarRing.right
                anchors.leftMargin: 18 * root.s
                anchors.right: avatarAction.left
                anchors.rightMargin: 16 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s

                Text {
                    width: parent.width
                    text: SystemInfo.userName.length > 0 ? SystemInfo.userName : "User"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 22 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: SystemInfo.hostName.length > 0 ? "@" + SystemInfo.hostName : "Local profile"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    elide: Text.ElideRight
                }

                Flow {
                    width: parent.width
                    spacing: 6 * root.s
                    topPadding: 4 * root.s

                    Repeater {
                        model: root.chips

                        Rectangle {
                            required property string modelData
                            width: chipLabel.implicitWidth + 16 * root.s
                            height: 22 * root.s
                            radius: 6 * root.s
                            color: Qt.alpha(Theme.cream, 0.05)
                            border.width: 1
                            border.color: Theme.hairSoft

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: chipLabel.parent.modelData
                                color: Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            SettingsAction {
                id: avatarAction
                s: root.s
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Edit avatar"
                onTriggered: root.requestPage("lockDetails")
            }
        }
    }

    // ── System ────────────────────────────────────────────────────────────

    SettingsCard {
        title: "System"

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Device name"

            SettingsReadout { text: SystemInfo.hostName }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Operating system"
            sub: SystemInfo.architecture

            SettingsReadout { text: SystemInfo.distro }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Kernel"
            sub: "Linux"

            SettingsReadout { text: SystemInfo.kernel }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Uptime"
            last: true

            SettingsReadout { text: SystemInfo.uptime }
        }
    }

    // ── Hardware ──────────────────────────────────────────────────────────

    SettingsCard {
        title: "Hardware"

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Processor"

            SettingsReadout { text: SystemInfo.cpu; emphasis: true }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Graphics"

            SettingsReadout { text: SystemInfo.gpu; emphasis: true }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Memory"
            sub: SystemInfo.memTotalGiB > 0 ? Math.round(SystemInfo.memPct * 100) + "% used" : ""

            SettingsUsageReadout { text: SystemInfo.memory; fraction: SystemInfo.memPct }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Disk"
            sub: "Root filesystem"
            last: true

            SettingsUsageReadout { text: SystemInfo.disk; fraction: SystemInfo.diskPct }
        }
    }

    // ── Shell ─────────────────────────────────────────────────────────────

    SettingsCard {
        title: "Shell"

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Desktop"
            sub: root.sessionLabel

            SettingsReadout { text: SystemInfo.wmName }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Login shell"

            SettingsReadout { text: SystemInfo.shellName }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Packages"
            sub: "Installed on this system"

            SettingsReadout { text: SystemInfo.pkgCount }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Theme"

            SettingsReadout { text: root.themeLabel }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Accent"

            SettingsReadout { text: root.accentLabel }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "UI scale"

            SettingsReadout { text: root.scaleLabel }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "UI font"

            SettingsReadout { text: Theme.font }
        }

        SettingsCardRow {
            surface: root
            interactive: false
            label: "Motion"
            last: true

            SettingsReadout { text: root.motionLabel }
        }
    }
}
