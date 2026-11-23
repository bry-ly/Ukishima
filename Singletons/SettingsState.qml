pragma Singleton
import QtQuick
import Quickshell

/**
 * State for the standalone settings window.
 *
 * The pill used to own settings as one more surface in its morph stack. That
 * tied the settings' lifetime, placement and input handling to the pill: they
 * grew out of the bar, could not be opened without the pill, and every page
 * inherited the pill's morphology. Settings are a peer of the pill now, so the
 * state has to live outside both the pill and the window that draws them.
 *
 * `page` is intentionally retained across close: reopening the cog returns to
 * the last page visited, the way a normal preferences window does. `monitor`
 * remembers which screen the window was opened on so a multi-monitor setup
 * reopens where the user was working.
 *
 * The page ids and editor sheet ids are owned by the window
 * (`components/SettingsWindow.qml`); this singleton only carries the state and
 * never validates names, so a page or sheet can be added or renamed in one place
 * without touching this file.
 */
Singleton {
    id: root

    property bool open: false
    property string monitor: ""
    property string page: "barIsland"
    /**
     * Advanced editors are modal sheets over the current category page rather
     * than pages of their own, so the page the user was reading stays behind
     * them. Empty means no sheet is up.
     */
    property string dialog: ""

    /** Open on `mon`, optionally switching to `page` first. */
    function show(mon, page) {
        root.closeDialog();
        if (mon && String(mon).length > 0)
            root.monitor = String(mon);
        if (page !== undefined && page !== null && String(page).length > 0)
            root.page = String(page);
        root.open = true;
    }

    function hide() {
        root.closeDialog();
        root.open = false;
    }

    function openDialog(id) {
        root.dialog = (id === undefined || id === null) ? "" : String(id);
    }

    function closeDialog() {
        root.dialog = "";
    }

    /** The cog's behaviour: toggle when already up on this monitor. */
    function toggle(mon) {
        if (root.open && (!mon || root.monitor === mon)) {
            root.hide();
            return;
        }
        root.show(mon);
    }

    /** Open `page` on `mon`, or close if that exact page is already showing. */
    function togglePage(mon, page) {
        if (root.open && root.monitor === mon && root.page === page) {
            root.hide();
            return;
        }
        root.show(mon, page);
    }

    function navigate(page) {
        if (page && String(page).length > 0)
            root.page = String(page);
    }
}
