import QtQuick
import QtQuick.Shapes
import "../Singletons"

/**
 * Pill-side port of the lockscreen battery (lockscreen/LockBattery.qml).
 *
 * The lock runs in a separate process, so its copy bakes UPower access, sizes
 * and colours. This shared component keeps the same artwork for the pill's
 * Status face: a rounded 35%-ink shell, a green fill (red at or below 20%)
 * with the percentage inside, a bolt + percentage row while charging, and the
 * sliding shadcn sheen. The lockscreen copy remains the source of the
 * geometry; keep the two in sync by hand.
 */
Item {
    id: root

    property real s: 1
    /** Sweep the charging row; hosts pass !Flags.reduceMotion. */
    property bool shimmerOn: true
    /** Draw the charge number inside the shell; off leaves the fill and bolt. */
    property bool showPercent: true

    readonly property int pct: Battery.pct
    readonly property bool full: Battery.full || root.pct >= 100
    readonly property bool charging: Battery.charging && !root.full
    readonly property bool low: root.pct <= 20
    readonly property bool roundedEnd: root.pct >= 85
    readonly property bool sheenActive: root.charging && root.shimmerOn
    readonly property color fillColor: root.low ? "#ff3b30" : "#34c759"
    readonly property color bodyColor: Qt.alpha(Theme.cream, 0.35)
    readonly property color inkColor: Theme.cream
    readonly property real bodyW: (root.showPercent ? 34 : 22) * root.s

    visible: Battery.present
    implicitWidth: root.bodyW + 3 * root.s
    implicitHeight: 17 * root.s
    Accessible.role: Accessible.StaticText
    Accessible.name: "Battery " + root.pct + " percent" + (root.charging ? ", charging" : (root.full ? ", fully charged" : ""))

    Rectangle {
        id: body

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.bodyW
        height: 17 * root.s
        radius: 6 * root.s
        color: root.bodyColor
        clip: true

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            topLeftRadius: 6 * root.s
            bottomLeftRadius: 6 * root.s
            topRightRadius: root.roundedEnd ? 6 * root.s : 0
            bottomRightRadius: root.roundedEnd ? 6 * root.s : 0
            width: Math.max((root.showPercent ? 12 : 7) * root.s, parent.width * root.pct / 100)
            color: root.fillColor

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        //* Charging overlay: % + bolt under the lockscreen's sheen. The plain
        //* percentage below takes over when unplugged or full.
        Item {
            id: chargeShimmer

            anchors.centerIn: parent
            width: chargeBase.implicitWidth
            height: chargeBase.implicitHeight
            visible: root.charging && root.showPercent
            z: 2

            ChargeRow {
                id: chargeBase

                anchors.centerIn: parent
                u: root.s
                value: root.pct
                tint: root.inkColor
                opacity: root.sheenActive ? 0.95 : 1
            }

            Item {
                id: sheenMover

                readonly property real coreWidth: Math.max(10 * root.s, chargeShimmer.width * 0.3)

                width: Math.max(20 * root.s, chargeShimmer.width * 0.6)
                height: chargeShimmer.height
                visible: root.sheenActive

                Item {
                    anchors.fill: parent
                    clip: true

                    ChargeRow {
                        y: (chargeShimmer.height - height) / 2
                        x: (chargeShimmer.width - implicitWidth) / 2 - sheenMover.x
                        u: root.s
                        value: root.pct
                        tint: root.inkColor
                        opacity: 0.45
                    }
                }

                Item {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: sheenMover.coreWidth
                    clip: true

                    ChargeRow {
                        y: (chargeShimmer.height - height) / 2
                        x: (chargeShimmer.width - implicitWidth) / 2 - sheenMover.x
                            - (sheenMover.width - sheenMover.coreWidth) / 2
                        u: root.s
                        value: root.pct
                        tint: root.inkColor
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: root.sheenActive

                    PauseAnimation { duration: 250 }

                    NumberAnimation {
                        from: -sheenMover.width
                        to: chargeShimmer.width
                        duration: 2000
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0.8 * root.s
            visible: !root.charging && root.showPercent
            z: 2
            text: root.pct + ""
            color: root.inkColor
            font.family: Theme.font
            font.pixelSize: 13 * root.s
            font.weight: root.low ? Font.Bold : Font.DemiBold
        }

        MiniBatteryBolt {
            anchors.centerIn: parent
            u: root.s
            tint: root.inkColor
            visible: root.charging && !root.showPercent
            z: 2
        }
    }

    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: 1 * root.s
        anchors.verticalCenter: parent.verticalCenter
        width: 2 * root.s
        height: 5 * root.s
        radius: 1 * root.s
        color: root.pct >= 100 ? root.fillColor : root.bodyColor

        Behavior on color { ColorAnimation { duration: 300 } }
    }

    //* One % + bolt row, instantiated 3x by the sheen so the highlight stays
    //* registered over the text exactly like the lockscreen.
    component ChargeRow: Row {
        id: chargeRow

        property real u: 1
        property int value: 0
        property color tint: Theme.cream

        spacing: 2 * chargeRow.u

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0.8 * chargeRow.u
            text: chargeRow.value + ""
            color: chargeRow.tint
            font.family: Theme.font
            font.pixelSize: 12 * chargeRow.u
            font.weight: Font.DemiBold
        }

        MiniBatteryBolt {
            anchors.verticalCenter: parent.verticalCenter
            u: chargeRow.u
            tint: chargeRow.tint
        }
    }
}
