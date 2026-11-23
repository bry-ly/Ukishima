import QtQuick
import QtQuick.Effects
import "../Singletons"

/** The percentage + bolt row used inside the pill's status battery. */
Row {
    id: root

    property real u: 1
    property int value: 0
    property color tint: Theme.cream
    /** Add the soft halo used by the travelling charging sheen. */
    property bool glow: false

    spacing: 2 * root.u

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0.8 * root.u
        text: root.value + ""
        color: root.tint
        font.family: Theme.font
        font.pixelSize: 12 * root.u
        font.weight: Font.DemiBold
    }

    MiniBatteryBolt {
        anchors.verticalCenter: parent.verticalCenter
        u: root.u
        tint: root.tint
    }

    layer.enabled: root.glow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.light ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.95)
        shadowBlur: 0.8
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
