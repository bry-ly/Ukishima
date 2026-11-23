import QtQuick
import "../../Singletons"
import ".."

/**
 * A card row in the reference style: label (and optional caption) on the left,
 * one control on the right, rounded hover/focus fill and an inset hairline.
 * It intentionally has no leading icon; section cards are scanned by label.
 *
 * The row reports hover and activation through the owning `SettingsPage`, so
 * the window's keyboard cursor and the mouse share the same target.
 */
Item {
    id: row

    property var surface: null
    property string label: ""
    property string sub: ""
    property bool last: false
    property bool chevron: false
    /** Informational rows do not hover, take focus or invite a click. */
    property bool interactive: true

    default property alias control: slot.data

    readonly property real s: row.surface ? row.surface.s : 1
    readonly property bool focused: row.surface ? row.surface.focusRowItem === row : false
    property bool hovered: false

    width: parent ? parent.width : 0
    height: Math.max(56 * row.s, textCol.implicitHeight + 20 * row.s)

    HoverHandler {
        enabled: row.interactive
        onHoveredChanged: {
            row.hovered = hovered;
            if (row.surface)
                row.surface.reportRowHover(row, hovered);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4 * row.s
        radius: 10 * row.s
        color: row.focused
            ? Qt.alpha(Theme.vermLit, 0.10)
            : (row.hovered ? Theme.frameBg : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: row.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: if (row.surface) row.surface.activateRow(row)
    }

    Column {
        id: textCol

        anchors.left: parent.left
        anchors.leftMargin: 16 * row.s
        anchors.right: slot.left
        anchors.rightMargin: 14 * row.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * row.s

        Text {
            width: parent.width
            text: row.label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 13.5 * row.s
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: row.sub.length > 0
            text: row.sub
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 11 * row.s
            elide: Text.ElideRight
        }
    }

    Item {
        id: slot

        property real s: row.s
        property bool hovered: row.hovered

        anchors.right: parent.right
        anchors.rightMargin: 16 * row.s
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width + (row.chevron ? 18 * row.s : 0)
        height: childrenRect.height
    }

    GlyphIcon {
        anchors.right: parent.right
        anchors.rightMargin: 16 * row.s
        anchors.verticalCenter: parent.verticalCenter
        width: 16 * row.s
        height: width
        visible: row.chevron
        name: "chevron-right"
        color: row.focused ? Theme.cream : Theme.iconDim
        stroke: 2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16 * row.s
        anchors.rightMargin: 16 * row.s
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.hairSoft
        visible: !row.last
    }
}
