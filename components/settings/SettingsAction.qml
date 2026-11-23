import QtQuick
import "../../Singletons"
import ".."

/**
 * A right-aligned action/value control. Used for rows that open a subpage or a
 * command ("Choose…", "Manage apps", "Open update") rather than selecting a
 * value in place. The `boxed` variant reads like the reference's rounded font
 * fields.
 */
Item {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property string text: "Choose…"
    property bool boxed: false
    property bool hovered: false

    signal triggered()

    width: root.boxed
        ? 230 * root.s
        : Math.min(260 * root.s, Math.max(72 * root.s, actionText.implicitWidth + 26 * root.s))
    height: root.boxed ? 34 * root.s : 28 * root.s

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    Rectangle {
        anchors.fill: parent
        visible: root.boxed
        radius: 8 * root.s
        color: Qt.alpha(Theme.cream, 0.04)
        border.width: 1
        border.color: root.hovered ? Qt.alpha(Theme.vermLit, 0.45) : Theme.hairSoft
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
    }

    Text {
        id: actionText

        anchors.left: parent.left
        anchors.leftMargin: root.boxed ? 10 * root.s : 0
        anchors.right: chevron.left
        anchors.rightMargin: 6 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.hovered ? Theme.cream : Theme.subtle
        font.family: Theme.font
        font.pixelSize: 12.5 * root.s
        elide: Text.ElideRight
        horizontalAlignment: root.boxed ? Text.AlignLeft : Text.AlignRight
    }

    GlyphIcon {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: root.boxed ? 10 * root.s : 0
        anchors.verticalCenter: parent.verticalCenter
        width: 14 * root.s
        height: width
        name: "chevron-right"
        color: root.hovered ? Theme.cream : Theme.iconDim
        stroke: 2
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
