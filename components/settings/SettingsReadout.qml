import QtQuick
import "../../Singletons"

/** Right-aligned read-only value for card rows on informational pages. */
Item {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property string text: ""
    property bool emphasis: false

    width: Math.min(260 * root.s, Math.max(48 * root.s, valueText.implicitWidth))
    height: valueText.implicitHeight

    Text {
        id: valueText

        anchors.right: parent.right
        width: parent.width
        text: root.text.length > 0 ? root.text : "—"
        color: root.emphasis ? Theme.cream : Theme.subtle
        font.family: Theme.font
        font.pixelSize: 12.5 * root.s
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
}
