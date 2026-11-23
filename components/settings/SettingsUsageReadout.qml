import QtQuick
import "../../Singletons"

/**
 * Right-aligned value with a thin capacity bar, used for memory and disk on the
 * profile page. The bar is informational; it never takes input.
 */
Item {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property string text: ""
    property real fraction: 0

    width: 180 * root.s
    height: valueText.implicitHeight + 8 * root.s

    Text {
        id: valueText

        anchors.right: parent.right
        width: parent.width
        text: root.text.length > 0 ? root.text : "—"
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 12.5 * root.s
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 4 * root.s
        radius: height / 2
        color: Qt.alpha(Theme.cream, 0.10)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            height: parent.height
            radius: parent.radius
            color: Theme.vermLit
        }
    }
}
