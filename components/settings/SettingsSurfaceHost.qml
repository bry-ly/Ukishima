import QtQuick
import "../../Singletons"
import ".."

/**
 * Hosts one of the shell's existing settings surfaces inside a reference-style
 * container. The surface keeps its logic and controls; the host hides the
 * pill/dock header, zeroes the surface margins so it reads as a row stack, and
 * supplies the palette the dock pages expect.
 *
 * Used by the standalone settings window's modal sheets. Keeping the
 * adaptation in one file means a surface behaves the same whether it is hosted
 * on a page or in a dialog.
 */
Item {
    id: root

    property real s: 1
    property Component page: null
    /** DockPanel pages take a palette; SettingsSurface pages own a read-only one. */
    property bool assignPal: false
    /** Hide a hosted surface's own slab (the dock panel's backdrop). */
    property bool chromeless: false

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
    implicitHeight: loader.height

    Loader {
        id: loader

        width: parent.width
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
            if (item.showBackdrop !== undefined)
                item.showBackdrop = !root.chromeless;
            if (item.mTop !== undefined) {
                item.mTop = 0;
                item.mLeft = 0;
                item.mRight = 0;
                item.mBottom = 0;
            }
            if (item.acceptsPalette === true && root.assignPal)
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

    /** Focus a hosted surface's own starting control (e.g. its search field). */
    function focusInitial() {
        if (loader.item && typeof loader.item.focusInitial === "function") {
            loader.item.focusInitial();
            return true;
        }
        return false;
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
