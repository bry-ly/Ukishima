import QtQuick
import "../../Singletons"
import ".."

/** Compact circular tool button used by the settings toolbar. */
Item {
    id: root

    property real s: 1
    property string icon: ""
    property bool hovered: false

    signal triggered()

    width: 32 * root.s
    height: width
    opacity: enabled ? 1 : 0.32

    HoverHandler {
        enabled: root.enabled
        onHoveredChanged: root.hovered = hovered
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.hovered ? Qt.alpha(Theme.cream, 0.10) : Theme.frameBg
        border.width: 1
        border.color: Theme.hairSoft
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    GlyphIcon {
        anchors.centerIn: parent
        width: 15 * root.s
        height: width
        name: root.icon
        color: root.hovered ? Theme.cream : Theme.iconDim
        stroke: 2
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
