import QtQuick
import "../../Singletons"
import ".."

/**
 * Right-aligned value control used by reference card rows. It shows the current
 * choice with a chevron and hands the actual selection to the shell's centred
 * Selector, the same picker every other dropdown uses.
 */
Item {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    required property var options
    property var value
    property string title: ""
    property bool hovered: false

    signal picked(var value)

    readonly property int curIndex: {
        for (var i = 0; i < root.options.length; i++)
            if (String(root.options[i].value) === String(root.value))
                return i;
        return -1;
    }
    readonly property string curLabel: root.curIndex >= 0 ? root.options[root.curIndex].label : ""

    readonly property string pickerTitle: {
        if (root.title.length > 0)
            return root.title;
        var p = root.parent;
        while (p) {
            if (p.label !== undefined && String(p.label).length > 0)
                return String(p.label);
            p = p.parent;
        }
        return "";
    }

    width: Math.min(260 * root.s, Math.max(72 * root.s, valueText.implicitWidth + 26 * root.s))
    height: 28 * root.s

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    Text {
        id: valueText

        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.rightMargin: 6 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.curLabel.length > 0 ? root.curLabel : "—"
        color: root.hovered ? Theme.cream : Theme.subtle
        font.family: Theme.font
        font.pixelSize: 12.5 * root.s
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
    }

    GlyphIcon {
        id: chevron

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 14 * root.s
        height: width
        name: "chevron-right"
        color: root.hovered ? Theme.cream : Theme.iconDim
        stroke: 2
    }

    function hostKey() {
        var p = root.parent;
        while (p) {
            if (p.pickerKey !== undefined)
                return p.pickerKey;
            p = p.parent;
        }
        return "";
    }

    function openPicker() {
        Selector.show({
            title: root.pickerTitle,
            options: root.options,
            value: root.value,
            tag: root,
            owner: root.hostKey()
        });
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openPicker()
    }

    Connections {
        target: Selector
        function onPicked(value, tag) {
            if (tag === root)
                root.picked(value);
        }
    }
}
