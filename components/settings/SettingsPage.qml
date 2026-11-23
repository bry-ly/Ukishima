import QtQuick
import "../../Singletons"
import ".."

/**
 * Base for the reference-style settings pages: a vertical column of section
 * cards with the same keyboard row model the rest of the shell uses.
 *
 * The page owns only behaviour. Cards, rows, sliders and fields provide the
 * look, so a page can be rearranged without touching the cursor logic.
 */
Column {
    id: root

    property real s: 1
    property bool active: true
    property var rows: []

    signal requestPage(string page)
    signal requestClose()

    readonly property SettingsRows nav: SettingsRows {
        active: root.active
        rows: root.rows
        onRequestSurface: (name) => root.requestPage(name)
    }

    readonly property Item focusRowItem: nav.focusRowItem
    readonly property int kbIndex: nav.kbIndex

    function reportRowHover(item, hovered) { nav.reportRowHover(item, hovered); }
    function activateRow(item) { nav.activateRow(item); }
    function kbMove(dir) { nav.kbMove(dir); }
    function kbAdjust(dir) { nav.kbAdjust(dir); }
    function kbActivate() { nav.kbActivate(); }

    width: parent ? parent.width : 0
    spacing: 20 * root.s
}
