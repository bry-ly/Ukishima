import QtQuick
import "../../Singletons"

/**
 * One section in the reference settings layout: a small all-caps section label
 * above a rounded card. Rows live inside the card and are separated by inset
 * hairlines, not by the card outline itself.
 *
 * `s` is inherited from the page (the parent Column), so pages only write
 * `SettingsCard { title: "..." }` and the card follows the window scale.
 */
Column {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property string title: ""

    default property alias contentData: body.data

    width: parent ? parent.width : 0
    spacing: 0

    Item {
        id: section

        width: parent.width
        height: root.title.length > 0 ? sectionLabel.implicitHeight : 0

        Text {
            id: sectionLabel

            visible: root.title.length > 0
            width: parent.width
            text: root.title
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10.5 * root.s
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.4 * root.s
        }
    }

    Item {
        width: 1
        height: section.height > 0 ? 7 * root.s : 0
    }

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: body.implicitHeight + 12 * root.s
        radius: 16 * root.s
        color: Qt.alpha(Theme.cream, 0.045)
        border.width: 1
        border.color: Theme.hairSoft

        Column {
            id: body

            width: parent.width - 20 * root.s
            x: 10 * root.s
            y: 6 * root.s
            spacing: 0
        }
    }
}
