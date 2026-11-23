import QtQuick
import "../../Singletons"
import ".."

/**
 * Hosts one of the existing settings pages as a reference-style subpage. The
 * old page keeps its logic and controls; the host hides its pill header and
 * zeroes the pill margins so it reads as a card row stack instead of a surface.
 *
 * Complex editors (theme hue, accent, font list, lock, dock apps, updater,
 * profile) stay in their proven implementations rather than being copied into
 * new pages where they would drift.
 */
Item {
    id: root

    property real s: parent && parent.s !== undefined ? parent.s : 1
    property string title: ""
    property Component page: null
    property bool framed: true
    /** DockPanel pages take a palette; SettingsSurface pages own a read-only one. */
    property bool assignPal: false

    signal requestPage(string page)
    signal requestBack()

    readonly property SettingsPalette pal: SettingsPalette {
        ink: Theme.cream
        sub: Theme.subtle
        faint: Theme.faint
        dim: Theme.dim
        tile: Theme.frameBg
        hair: Theme.hairSoft
        edge: Theme.border
        accentInk: Theme.cream
        accent: Theme.vermLit
        paneTop: Theme.cardTop
        paneBot: Theme.cardBot
    }

    width: parent ? parent.width : 0
    implicitHeight: loader.y + loader.height + (root.framed ? 6 * root.s : 0)

    Item {
        id: section

        width: parent.width
        height: root.title.length > 0 ? sectionLabel.implicitHeight : 0

        Text {
            id: sectionLabel

            visible: root.title.length > 0
            width: parent.width
            text: root.title
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10.5 * root.s
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.4 * root.s
        }
    }

    Item {
        id: sectionGap
        width: 1
        height: section.height > 0 ? 7 * root.s : 0
    }

    Rectangle {
        id: cardBg

        visible: root.framed
        y: section.height + sectionGap.height
        width: parent.width
        height: loader.height + 12 * root.s
        radius: 16 * root.s
        color: Qt.alpha(Theme.cream, 0.045)
        border.width: 1
        border.color: Theme.hairSoft
    }

    Loader {
        id: loader

        y: root.framed
            ? section.height + sectionGap.height + 6 * root.s
            : section.height + sectionGap.height
        x: root.framed ? 10 * root.s : 0
        width: parent.width - (root.framed ? 20 * root.s : 0)
        height: item ? item.implicitHeight : 0
        sourceComponent: root.page

        onLoaded: {
            if (!item)
                return;
            item.s = root.s;
            if (item.open !== undefined)
                item.open = true;
            if (item.morphCloseness !== undefined)
                item.morphCloseness = 1;
            if (item.showHeader !== undefined)
                item.showHeader = false;
            if (item.mTop !== undefined) {
                item.mTop = 0;
                item.mLeft = 0;
                item.mRight = 0;
                item.mBottom = 0;
            }
            if (item.pal !== undefined && root.assignPal)
                item.pal = root.pal;
            if (item.backSurface !== undefined)
                item.backSurface = "";
            if (item.requestSurface)
                item.requestSurface.connect(function (name) { root.requestPage(name); });
            if (item.requestClose)
                item.requestClose.connect(function () { root.requestBack(); });
        }
    }

    function kbMove(dir) {
        if (loader.item && loader.item.kbMove)
            loader.item.kbMove(dir);
    }

    function kbAdjust(dir) {
        if (loader.item && loader.item.kbAdjust)
            loader.item.kbAdjust(dir);
    }

    function kbActivate() {
        if (loader.item && loader.item.kbActivate)
            loader.item.kbActivate();
    }
}
