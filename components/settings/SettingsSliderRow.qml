import QtQuick
import QtQuick.Controls
import "../../Singletons"

/**
 * A reference-style slider row: label and value on one line, a ticked track
 * with a large accent handle beneath it. `values` lets a page expose discrete
 * choices through the same visual control (UI scale, window gap, etc.).
 *
 * `value` is the real setting; the slider is kept in sync when the value is
 * changed from outside (keyboard, another page) and commits through `moved`.
 */
Item {
    id: row

    property var surface: null
    property string label: ""
    property string sub: ""
    property bool last: false
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property real value: 0
    property int tickCount: 7
    property var format: function (v) { return String(v); }
    property bool hovered: false

    signal moved(real value)

    readonly property real s: row.surface ? row.surface.s : 1
    readonly property bool focused: row.surface ? row.surface.focusRowItem === row : false

    width: parent ? parent.width : 0
    height: 88 * row.s

    HoverHandler {
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

    Text {
        id: labelText

        anchors.left: parent.left
        anchors.leftMargin: 16 * row.s
        anchors.right: valueText.left
        anchors.rightMargin: 16 * row.s
        anchors.top: parent.top
        anchors.topMargin: 12 * row.s
        text: row.label
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 13.5 * row.s
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Text {
        id: valueText

        anchors.right: parent.right
        anchors.rightMargin: 16 * row.s
        anchors.top: parent.top
        anchors.topMargin: 12 * row.s
        text: row.format(slider.value)
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 11.5 * row.s
        font.features: { "tnum": 1 }
    }

    Slider {
        id: slider

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16 * row.s
        anchors.rightMargin: 16 * row.s
        anchors.top: labelText.bottom
        anchors.topMargin: 14 * row.s
        height: 26 * row.s
        from: row.from
        to: row.to
        stepSize: row.stepSize
        value: row.value
        onMoved: row.moved(slider.value)

        Component.onCompleted: slider.value = row.value

        Connections {
            target: row
            function onValueChanged() {
                if (!slider.pressed)
                    slider.value = row.value;
            }
        }

        background: Item {
            width: slider.availableWidth
            height: slider.availableHeight

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6 * row.s
                radius: height / 2
                color: Qt.alpha(Theme.cream, 0.14)
            }

            Repeater {
                model: row.tickCount

                Rectangle {
                    required property int index
                    readonly property real t: row.tickCount <= 1 ? 0 : index / (row.tickCount - 1)
                    x: t * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3 * row.s
                    height: width
                    radius: width / 2
                    color: Qt.alpha(Theme.cream, 0.22)
                }
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.availableHeight / 2 - height / 2
            width: 18 * row.s
            height: width
            radius: width / 2
            color: Theme.vermLit
            border.width: 2 * row.s
            border.color: Theme.cream
        }
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
