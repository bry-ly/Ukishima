import QtQuick
import "../Singletons"

/**
 * A thin read-only rail for a Flickable. The wheel still belongs to the host's
 * `WheelScroller`; this is the visual answer to "there is more above or below",
 * plus a drag handle for pages that host their own nested scroll view and
 * therefore cannot take a page-level wheel bridge.
 *
 * The thumb is bound to the flickable's content position, so it also tracks
 * wheel steps and drag flicks without the host forwarding anything. Dragging is
 * arithmetic rather than `drag.target` on purpose: binding `y` to contentY and
 * then dragging the same thumb would break the binding on the first press.
 */
Item {
    id: root

    required property Flickable flick
    property real s: 1
    property color ink: Theme.cream

    readonly property bool overflowing: flick.contentHeight > flick.height + 0.5
    readonly property real maxScroll: Math.max(1, flick.contentHeight - flick.height)
    readonly property real thumbH: Math.max(24 * root.s, flick.height * flick.height / Math.max(1, flick.contentHeight))

    width: 4 * root.s
    visible: overflowing
    opacity: overflowing ? 1 : 0

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: thumb

        width: parent.width
        height: root.thumbH
        radius: width / 2
        color: root.ink
        opacity: hover.hovered || railArea.pressed ? 0.34 : 0.16
        y: Math.max(0, Math.min(root.height - height,
            flick.contentY / root.maxScroll * (root.height - height)))

        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    }

    MouseArea {
        id: railArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property real startY: 0
        property real startContentY: 0

        onPressed: (mouse) => {
            railArea.startY = mouse.y;
            railArea.startContentY = root.flick.contentY;
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;
            const travel = Math.max(1, root.height - root.thumbH);
            const delta = (mouse.y - railArea.startY) / travel * root.maxScroll;
            root.flick.contentY = Math.max(0, Math.min(root.maxScroll, railArea.startContentY + delta));
        }
    }
}
