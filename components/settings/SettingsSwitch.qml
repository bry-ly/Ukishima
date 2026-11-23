import QtQuick
import "../../Singletons"

/** Reference-style switch: a wider track, a round knob and the shell accent. */
Rectangle {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property bool on: false

    signal toggled()

    width: 40 * root.s
    height: 22 * root.s
    radius: 999
    color: root.on ? Theme.vermLit : Qt.alpha(Theme.cream, 0.12)
    border.width: root.on ? 0 : 1
    border.color: Theme.hairSoft

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 16 * root.s
        height: 16 * root.s
        radius: width / 2
        color: Theme.cream
        x: root.on ? root.width - width - 3 * root.s : 3 * root.s
        Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
