import QtQuick
import "../../Singletons"

/** Motion: the pill's animation feel and the reduced-motion switch. */
SettingsPage {
    id: root

    rows: [
        { item: styleRow, kind: "seg", vals: ["standard", "snap", "float", "bounce"], get: function () { return Flags.motionStyle; }, set: function (v) { Flags.motionStyle = v; } },
        { item: reduceRow, kind: "toggle", get: function () { return Flags.reduceMotion; }, set: function (v) { Flags.reduceMotion = v; } }
    ]

    SettingsCard {
        title: "Motion"

        SettingsCardRow {
            id: styleRow
            surface: root
            label: "Style"
            sub: "How the pill's morph, hover and reveal move"

            SettingsChoice {
                options: [
                    { label: "Standard", value: "standard" }, { label: "Snap", value: "snap" },
                    { label: "Float", value: "float" }, { label: "Bounce", value: "bounce" }
                ]
                value: Flags.motionStyle
                onPicked: (v) => Flags.motionStyle = v
            }
        }

        SettingsCardRow {
            id: reduceRow
            surface: root
            label: "Reduce motion"
            sub: "Shorten every animation in the shell"
            last: true

            SettingsSwitch { on: Flags.reduceMotion; onToggled: Flags.reduceMotion = !Flags.reduceMotion }
        }
    }
}
