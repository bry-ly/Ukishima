import QtQuick
import QtQuick.Shapes
import "../Singletons"

/** The stroked bolt from the lockscreen battery, scaled to the pill. */
Shape {
    id: root

    property real u: 1
    property color tint: Theme.cream

    width: 10 * root.u
    height: 10 * root.u
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.tint
        strokeWidth: 1.4
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap

        PathSvg {
            path: "M6.5 1 L2.5 5.8 h2.5 L4.6 9.2 L8 4.6 H5.5 Z"
        }
    }
}
