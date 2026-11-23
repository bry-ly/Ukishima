import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../Singletons"
import "../surfaces"
import "settings"

/**
 * Reference-style settings window.
 *
 * The proportions follow macOS Sequoia System Settings (centred 66% x 80%
 * window, search-first sidebar, compact back/forward toolbar and rounded
 * section cards). GNOME Settings 47 supplies the single grouped navigation
 * list and search-first behaviour. The shell accent replaces the reference's
 * fixed teal so light/dark/dynamic palettes stay cohesive.
 *
 * Complex editors stay as proven subpages (theme hue, accent, font colour,
 * font list, lock, dock theme/apps, updater, profile); the category pages are
 * new grouped card surfaces and all binding logic remains on the shared Flags
 * and singletons.
 */
Item {
    id: root

    property real s: 1
    property string screenName: ""

    property bool hostActive: false
    property bool alive: false
    visible: alive

    readonly property string pickerKey: "settings:" + screenName
    readonly property bool open: SettingsState.open && root.hostActive
    readonly property bool pickerHere: root.open && Selector.open && Selector.owner === root.pickerKey

    property string query: ""
    property string hoveredNav: ""

    property var history: ["barIsland"]
    property int historyIndex: 0
    property bool historyNav: false

    readonly property bool canBack: root.historyIndex > 0
    readonly property bool canForward: root.historyIndex < root.history.length - 1

    // ── Page catalogue ────────────────────────────────────────────────────
    //
    // Only the seven top-level entries are in the sidebar. Subpages carry a
    // parent and stay out of the list; the toolbar's back/forward history and
    // the sidebar highlight make their position legible.

    readonly property var pageDefs: [
        { id: "barIsland", label: "Bar & Island", icon: "monitor",
          keywords: "pill bar island clock time date display modules expand gap dock visualizer glyphs seconds" },
        { id: "appearance", label: "Appearance", icon: "palette",
          keywords: "theme accent colour color glass material typography font surface styles wallpaper oled" },
        { id: "motion", label: "Motion", icon: "bolt",
          keywords: "motion animation snap float bounce reduce" },
        { id: "interface", label: "Interface", icon: "scaling",
          keywords: "scale ui auto hide memory gap right click stops" },
        { id: "lock", label: "Lock Screen", icon: "lock",
          keywords: "lock hyprlock swaylock quickshell avatar wifi battery media blur" },
        { id: "dock", label: "Dock", icon: "dock",
          keywords: "dock apps pin theme motion auto hide scale gap" },
        { id: "systemSettings", label: "System", icon: "cog",
          keywords: "update profile dependencies system info kernel cpu gpu" },

        { id: "themeDetails", label: "Theme", icon: "palette", parent: "appearance", sidebar: false,
          keywords: "theme wallpaper hue manual dynamic light dark" },
        { id: "accentEditor", label: "Accent colour", icon: "sparkles", parent: "appearance", sidebar: false,
          keywords: "accent colour color hue saturation hex" },
        { id: "fontColorEditor", label: "Font colour", icon: "type", parent: "appearance", sidebar: false,
          keywords: "font text colour color hue saturation hex" },
        { id: "fontPicker", label: "Font family", icon: "language", parent: "appearance", sidebar: false,
          keywords: "font family typeface" },
        { id: "rightClickDetails", label: "Right-click", icon: "cursor", parent: "interface", sidebar: false,
          keywords: "right click cycle stop slots" },
        { id: "lockDetails", label: "Lock screen", icon: "lock", parent: "lock", sidebar: false,
          keywords: "lock method backdrop blur avatar" },
        { id: "dockThemeDetails", label: "Dock theme", icon: "palette", parent: "dock", sidebar: false,
          keywords: "dock theme oled glass hue manual" },
        { id: "dockApps", label: "Dock apps", icon: "grid", parent: "dock", sidebar: false,
          keywords: "dock apps pin pinned applications" },
        { id: "updateDetails", label: "Updates", icon: "refresh", parent: "systemSettings", sidebar: false,
          keywords: "update git dependencies" },
        { id: "profileDetails", label: "Profile", icon: "user", parent: "systemSettings", sidebar: false,
          keywords: "profile system info host kernel gpu cpu memory disk" }
    ]

    function defFor(id) {
        for (var i = 0; i < root.pageDefs.length; i++)
            if (root.pageDefs[i].id === id)
                return root.pageDefs[i];
        return null;
    }

    readonly property var currentDef: root.defFor(SettingsState.page) || root.pageDefs[0]
    readonly property string crumb: {
        if (!root.currentDef || !root.currentDef.parent)
            return "";
        var parent = root.defFor(root.currentDef.parent);
        return (parent ? parent.label + " / " : "") + root.currentDef.label;
    }
    readonly property string activeCategory: {
        var d = root.currentDef;
        while (d && d.parent) {
            var p = root.defFor(d.parent);
            if (!p)
                break;
            d = p;
        }
        return d ? d.id : "barIsland";
    }

    readonly property var navModel: {
        var q = String(root.query || "").trim().toLowerCase();
        var out = [];
        for (var i = 0; i < root.pageDefs.length; i++) {
            var p = root.pageDefs[i];
            if (p.sidebar === false)
                continue;
            var hay = String(p.label + " " + p.keywords).toLowerCase();
            if (q.length > 0 && hay.indexOf(q) < 0)
                continue;
            out.push({ id: p.id, label: p.label, icon: p.icon });
        }
        return out;
    }

    function validPage(id) {
        return root.defFor(id) !== null;
    }

    function normalizePage(id) {
        var map = {
            display: "barIsland", modules: "barIsland",
            appearance: "appearance", appcat: "appearance",
            theme: "themeDetails", accent: "accentEditor", glass: "appearance",
            fontcolor: "fontColorEditor", interface: "interface",
            rightclick: "rightClickDetails", fontpicker: "fontPicker",
            locksettings: "lockDetails", update: "updateDetails", profile: "profileDetails",
            surfacestyles: "appearance",
            dockBehavior: "dock", dockAppearance: "dockThemeDetails",
            dockApps: "dockApps", dockMotion: "dock", dockSettings: "dock",
            system: "systemSettings"
        };
        var out = map[id] !== undefined ? map[id] : id;
        return root.validPage(out) ? out : "barIsland";
    }

    readonly property bool pageHasNestedScroll: SettingsState.page === "fontPicker"
        || SettingsState.page === "dockApps"

    // ── Geometry ──────────────────────────────────────────────────────────

    readonly property real cardW: root.width > 0
        ? Math.max(620 * root.s, Math.min(1080 * root.s, root.width - 80 * root.s))
        : 1080 * root.s
    readonly property real cardH: root.height > 0
        ? Math.max(460 * root.s, Math.min(720 * root.s, root.height - 160 * root.s))
        : 720 * root.s
    readonly property real sidebarW: Math.max(220 * root.s, Math.min(280 * root.s, root.cardW * 0.26))
    readonly property real toolbarH: 62 * root.s
    readonly property real pagePad: 32 * root.s
    readonly property real pageMaxW: 780 * root.s
    readonly property real pageScale: root.s
    readonly property real legacyScale: root.s * 1.12
    readonly property real pageTopPad: 16 * root.s
    readonly property real pageBottomPad: 30 * root.s
    readonly property real pageW: Math.max(0, Math.min(root.pageMaxW,
        root.cardW - root.sidebarW - 1 - 2 * root.pagePad))

    // ── Page components ───────────────────────────────────────────────────

    Component {
        id: compBarIsland
        BarIslandPage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compAppearance
        AppearancePage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compMotion
        MotionPage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compInterface
        InterfacePage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compLock
        LockPage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compDock
        DockPage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compSystem
        SystemPage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    Component {
        id: compThemeDetails
        LegacyPage {
            s: root.legacyScale
            title: "Palette"
            page: Component { ThemeSurface {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compAccentEditor
        LegacyPage {
            s: root.legacyScale
            title: "Accent"
            page: Component { AccentSurface {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compFontColorEditor
        LegacyPage {
            s: root.legacyScale
            title: "Typography"
            page: Component { FontColorSurface {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compFontPicker
        LegacyPage {
            s: root.legacyScale
            title: "Font family"
            page: Component { FontPicker { listMaxHeight: 420 } }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compRightClickDetails
        LegacyPage {
            s: root.legacyScale
            title: "Walk stops"
            page: Component { RightClickSurface {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compLockDetails
        LegacyPage {
            s: root.legacyScale
            title: "Lock screen"
            page: Component { LockSettings {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compDockThemeDetails
        LegacyPage {
            s: root.legacyScale
            title: "Dock palette"
            assignPal: true
            page: Component { DockAppearance {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compDockApps
        LegacyPage {
            s: root.legacyScale
            framed: false
            assignPal: true
            page: Component { DockApps { listMaxHeight: 420 } }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compUpdateDetails
        LegacyPage {
            s: root.legacyScale
            title: "Updates"
            page: Component { UpdateSurface {} }
            onRequestPage: (page) => root.openSurfacePage(page)
            onRequestBack: root.goBack()
        }
    }

    Component {
        id: compProfileDetails
        ProfilePage {
            s: root.pageScale
            active: true
            onRequestPage: (page) => root.goPage(page)
            onRequestClose: SettingsState.hide()
        }
    }

    readonly property var pageComponents: ({
        barIsland: compBarIsland,
        appearance: compAppearance,
        motion: compMotion,
        interface: compInterface,
        lock: compLock,
        dock: compDock,
        systemSettings: compSystem,
        themeDetails: compThemeDetails,
        accentEditor: compAccentEditor,
        fontColorEditor: compFontColorEditor,
        fontPicker: compFontPicker,
        rightClickDetails: compRightClickDetails,
        lockDetails: compLockDetails,
        dockThemeDetails: compDockThemeDetails,
        dockApps: compDockApps,
        updateDetails: compUpdateDetails,
        profileDetails: compProfileDetails
    })

    // ── Navigation / history ──────────────────────────────────────────────

    function takeFocus() {
        if (root.alive && root.open)
            pageFocus.forceActiveFocus();
    }

    function resetQuery() {
        root.query = "";
        if (searchField.text.length > 0)
            searchField.text = "";
    }

    function pushHistory(page) {
        var h = root.history.slice(0, root.historyIndex + 1);
        if (h.length === 0 || h[h.length - 1] !== page)
            h.push(page);
        root.history = h;
        root.historyIndex = h.length - 1;
    }

    function initHistory() {
        var page = root.normalizePage(SettingsState.page);
        if (page !== SettingsState.page)
            SettingsState.page = page;
        if (root.history.length === 0 || !root.validPage(root.history[root.historyIndex])) {
            root.history = [page];
            root.historyIndex = 0;
        } else if (root.history[root.historyIndex] !== page) {
            root.pushHistory(page);
        }
    }

    function goPage(page) {
        var next = root.normalizePage(page);
        if (next === SettingsState.page)
            return;
        SettingsState.navigate(next);
    }

    function goBack() {
        if (!root.canBack)
            return;
        root.historyNav = true;
        root.historyIndex--;
        SettingsState.navigate(root.history[root.historyIndex]);
    }

    function goForward() {
        if (!root.canForward)
            return;
        root.historyNav = true;
        root.historyIndex++;
        SettingsState.navigate(root.history[root.historyIndex]);
    }

    function openSurfacePage(name) {
        var map = {
            appearance: "appearance", appcat: "appearance",
            display: "barIsland", modules: "barIsland",
            theme: "themeDetails", accent: "accentEditor", glass: "appearance",
            fontcolor: "fontColorEditor", interface: "interface",
            rightclick: "rightClickDetails", fontpicker: "fontPicker",
            locksettings: "lockDetails", update: "updateDetails", profile: "profileDetails",
            surfacestyles: "appearance",
            dockSettings: "dock", dockBehavior: "dock",
            dockAppearance: "dockThemeDetails", dockApps: "dockApps", dockMotion: "dock"
        };
        var page = map[name] !== undefined ? map[name] : name;
        if (root.validPage(page))
            root.goPage(page);
        else
            root.goBack();
    }

    function pickCategory(id) {
        root.resetQuery();
        root.goPage(id);
        pageFocus.forceActiveFocus();
    }

    function revealCategory() {
        for (var i = 0; i < root.navModel.length; i++) {
            if (root.navModel[i].id === root.activeCategory) {
                navList.positionViewAtIndex(i, ListView.Contain);
                return;
            }
        }
    }

    function categoryVisible() {
        for (var i = 0; i < root.navModel.length; i++)
            if (root.navModel[i].id === root.activeCategory)
                return true;
        return false;
    }

    function activateSearch() {
        if (root.navModel.length > 0)
            root.pickCategory(root.navModel[0].id);
    }

    function pageMove(dir) {
        var page = pageLoader.item;
        if (!page || typeof page.kbMove !== "function")
            return false;
        page.kbMove(dir);
        return true;
    }

    function pageAdjust(dir) {
        var page = pageLoader.item;
        if (!page || typeof page.kbAdjust !== "function")
            return false;
        page.kbAdjust(dir);
        return true;
    }

    function pageActivate() {
        var page = pageLoader.item;
        if (!page || typeof page.kbActivate !== "function")
            return false;
        page.kbActivate();
        return true;
    }

    // ── Open / close lifecycle ────────────────────────────────────────────

    Component.onCompleted: {
        if (root.open) {
            root.alive = true;
            root.initHistory();
            Qt.callLater(root.takeFocus);
            Qt.callLater(root.revealCategory);
        }
    }

    onAliveChanged: if (root.alive) Qt.callLater(root.takeFocus)

    onOpenChanged: {
        if (root.open) {
            root.alive = true;
            closeTimer.stop();
            root.resetQuery();
            root.hoveredNav = "";
            pageScroll.contentY = 0;
            root.initHistory();
            if (Selector.open)
                Selector.close();
            Qt.callLater(root.takeFocus);
            Qt.callLater(root.revealCategory);
        } else if (root.alive) {
            if (Selector.open)
                Selector.close();
            closeTimer.restart();
        }
    }

    Connections {
        target: SettingsState

        function onPageChanged() {
            var page = root.normalizePage(SettingsState.page);
            if (page !== SettingsState.page) {
                SettingsState.page = page;
                return;
            }
            if (root.historyNav)
                root.historyNav = false;
            else if (root.history.length === 0 || root.history[root.historyIndex] !== page)
                root.pushHistory(page);
            pageScroll.contentY = 0;
            if (!root.categoryVisible())
                root.resetQuery();
            Qt.callLater(root.revealCategory);
        }
    }

    Connections {
        target: root
        function onQueryChanged() { Qt.callLater(root.revealCategory); }
        function onNavModelChanged() { Qt.callLater(root.revealCategory); }
    }

    Timer {
        id: closeTimer
        interval: Motion.standard + 20
        onTriggered: root.alive = false
    }

    // ── Backdrop ──────────────────────────────────────────────────────────

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Theme.light ? 0.10 : 0.22)
        opacity: root.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: SettingsState.hide()
        }
    }

    // ── Card ──────────────────────────────────────────────────────────────

    Item {
        id: card

        readonly property real radius: 28 * root.s

        anchors.centerIn: parent
        width: root.cardW
        height: root.cardH
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.975
        z: 1

        transform: Translate {
            y: root.open ? 0 : 12 * root.s
            Behavior on y {
                NumberAnimation { duration: Motion.standard; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Motion.standard; easing.type: Easing.OutCubic }
        }

        LiquidGlass {
            anchors.fill: parent
            radius: card.radius
            style: "clear"
            materialOpacity: 0.94
            legacyOpacity: 1
            accent: 0.045
            veil: 0.08
            borderColor: Theme.border
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: 0.95
                shadowVerticalOffset: 24 * root.s
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: pageFocus.forceActiveFocus()
        }

        // ── Sidebar ───────────────────────────────────────────────────────

        Item {
            id: sidebar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: root.sidebarW

            Rectangle {
                anchors.fill: parent
                topLeftRadius: card.radius
                bottomLeftRadius: card.radius
                color: Qt.alpha(Theme.cream, 0.02)
            }

            Item {
                id: searchBox
                anchors.top: parent.top
                anchors.topMargin: 22 * root.s
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20 * root.s
                anchors.rightMargin: 20 * root.s
                height: 40 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 10 * root.s
                    color: searchField.activeFocus ? Theme.frameBg : Qt.alpha(Theme.cream, 0.035)
                    border.width: 1
                    border.color: searchField.activeFocus
                        ? Qt.alpha(Theme.vermLit, 0.42)
                        : Theme.hairSoft
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                GlyphIcon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 13 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15 * root.s
                    height: width
                    name: "search"
                    color: searchField.activeFocus ? Theme.cream : Theme.iconDim
                    stroke: 1.7
                }

                TextField {
                    id: searchField
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 9 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 34 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    background: null
                    padding: 0
                    color: Theme.cream
                    placeholderText: "Search Settings"
                    placeholderTextColor: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                    selectByMouse: true
                    selectionColor: Theme.vermLit

                    onTextChanged: root.query = text

                    Keys.onEscapePressed: (e) => {
                        if (searchField.text.length > 0) {
                            root.resetQuery();
                        } else {
                            pageFocus.forceActiveFocus();
                        }
                        e.accepted = true;
                    }

                    onAccepted: root.activateSearch()
                }

                Rectangle {
                    visible: searchField.text.length === 0 && !searchField.activeFocus
                    anchors.right: parent.right
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 19 * root.s
                    height: 19 * root.s
                    radius: 6 * root.s
                    color: Theme.frameBg
                    border.width: 1
                    border.color: Theme.hairSoft

                    Text {
                        anchors.centerIn: parent
                        text: "/"
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                        font.weight: Font.DemiBold
                    }
                }

                Item {
                    visible: searchField.text.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 13 * root.s
                        height: width
                        name: "close"
                        color: clearArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.9
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetQuery();
                            pageFocus.forceActiveFocus();
                        }
                    }
                }
            }

            ListView {
                id: navList
                anchors.top: searchBox.bottom
                anchors.topMargin: 18 * root.s
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14 * root.s
                anchors.rightMargin: 14 * root.s
                anchors.bottom: sideFoot.top
                anchors.bottomMargin: 10 * root.s
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.navModel
                spacing: 4 * root.s

                onContentYChanged: root.hoveredNav = ""
                onModelChanged: root.hoveredNav = ""

                HoverHandler {
                    onHoveredChanged: if (!hovered) root.hoveredNav = ""
                }

                delegate: Item {
                    id: navRow

                    required property int index
                    required property var modelData

                    readonly property bool active: root.activeCategory === navRow.modelData.id

                    width: ListView.view.width
                    height: 46 * root.s

                    Rectangle {
                        id: navBg
                        anchors.fill: parent
                        radius: 11 * root.s
                        color: navRow.active
                            ? Qt.alpha(Theme.vermLit, 0.16)
                            : (root.hoveredNav === navRow.modelData.id ? Theme.frameBg : "transparent")
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }

                    Rectangle {
                        id: iconTile
                        x: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30 * root.s
                        height: 30 * root.s
                        radius: 9 * root.s
                        color: navRow.active
                            ? Qt.alpha(Theme.vermLit, 0.18)
                            : Qt.alpha(Theme.cream, 0.04)
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }

                    GlyphIcon {
                        anchors.centerIn: iconTile
                        width: 18 * root.s
                        height: width
                        name: navRow.modelData.icon
                        color: navRow.active ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    Text {
                        x: 50 * root.s
                        anchors.right: parent.right
                        anchors.rightMargin: 14 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: navRow.modelData.label
                        color: navRow.active ? Theme.cream : Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                        font.weight: navRow.active ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoveredNav = navRow.modelData.id
                        onExited: if (root.hoveredNav === navRow.modelData.id) root.hoveredNav = ""
                        onClicked: root.pickCategory(navRow.modelData.id)
                    }
                }
            }

            WheelScroller {
                anchors.fill: navList
                s: root.s
                flick: navList
            }

            ScrollRail {
                anchors.top: navList.top
                anchors.bottom: navList.bottom
                anchors.right: parent.right
                anchors.rightMargin: 5 * root.s
                s: root.s
                flick: navList
                ink: Theme.cream
            }

            Text {
                anchors.centerIn: navList
                visible: root.navModel.length === 0
                width: navList.width - 20 * root.s
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No settings found"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }

            Item {
                id: sideFoot
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 18 * root.s
                anchors.rightMargin: 18 * root.s
                anchors.bottomMargin: 14 * root.s
                height: 20 * root.s

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    Rectangle {
                        width: 6 * root.s
                        height: width
                        radius: width / 2
                        color: Theme.vermLit
                        opacity: 0.75
                    }
                    Text {
                        text: "Changes apply live"
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }
                }

                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28 * root.s
                    height: 18 * root.s

                    Rectangle {
                        anchors.fill: parent
                        radius: 6 * root.s
                        color: Theme.frameBg
                        border.width: 1
                        border.color: Theme.hairSoft
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "esc"
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 9 * root.s
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.4 * root.s
                    }
                }
            }
        }

        Rectangle {
            id: divider
            x: root.sidebarW
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.hairSoft
        }

        // ── Content ───────────────────────────────────────────────────────

        FocusScope {
            id: pageFocus

            anchors.left: divider.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            focus: root.open

            Keys.onEscapePressed: (e) => {
                if (Selector.open) {
                    Selector.close();
                } else if (root.currentDef.parent) {
                    root.goBack();
                } else {
                    SettingsState.hide();
                }
                e.accepted = true;
            }
            Keys.onUpPressed: (e) => { if (root.pageMove(-1)) e.accepted = true; }
            Keys.onDownPressed: (e) => { if (root.pageMove(1)) e.accepted = true; }
            Keys.onLeftPressed: (e) => { if (root.pageAdjust(-1)) e.accepted = true; }
            Keys.onRightPressed: (e) => { if (root.pageAdjust(1)) e.accepted = true; }
            Keys.onReturnPressed: (e) => { if (root.pageActivate()) e.accepted = true; }
            Keys.onEnterPressed: (e) => { if (root.pageActivate()) e.accepted = true; }
            Keys.onSpacePressed: (e) => { if (root.pageActivate()) e.accepted = true; }

            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Slash && !searchField.activeFocus && e.text === "/") {
                    searchField.forceActiveFocus();
                    e.accepted = true;
                }
            }

            Item {
                id: toolbar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.toolbarH

                SettingsToolButton {
                    s: root.s
                    icon: "chevron-left"
                    anchors.left: parent.left
                    anchors.leftMargin: 20 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: root.canBack
                    onTriggered: root.goBack()
                }

                SettingsToolButton {
                    s: root.s
                    icon: "chevron-right"
                    anchors.left: parent.left
                    anchors.leftMargin: 58 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: root.canForward
                    onTriggered: root.goForward()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 112 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: closeButton.left
                    anchors.rightMargin: 16 * root.s
                    visible: root.crumb.length > 0
                    text: root.crumb
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 14.5 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                SettingsToolButton {
                    id: closeButton
                    s: root.s
                    icon: "close"
                    anchors.right: parent.right
                    anchors.rightMargin: 22 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    onTriggered: SettingsState.hide()
                }
            }

            Item {
                id: pageArea
                anchors.top: toolbar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true

                Flickable {
                    id: pageScroll
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: Math.max(height, pageHost.y + pageHost.height + root.pageBottomPad)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    Item {
                        id: pageHost
                        width: root.pageW
                        height: pageLoader.item ? pageLoader.item.implicitHeight : 0
                        x: (pageScroll.width - width) / 2
                        y: root.pageTopPad
                        opacity: 0

                        Loader {
                            id: pageLoader
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            active: root.alive
                            sourceComponent: root.pageComponents[SettingsState.page] !== undefined
                                ? root.pageComponents[SettingsState.page]
                                : compBarIsland

                            onLoaded: {
                                pageHost.opacity = 0;
                                pageEnter.start();
                            }
                        }
                    }
                }

                NumberAnimation {
                    id: pageEnter
                    target: pageHost
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Motion.fast
                    easing.type: Easing.OutCubic
                }

                WheelScroller {
                    anchors.fill: parent
                    s: root.s
                    flick: pageScroll
                    enabled: !root.pageHasNestedScroll
                }

                ScrollRail {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 8 * root.s
                    anchors.topMargin: 10 * root.s
                    anchors.bottomMargin: 10 * root.s
                    s: root.s
                    flick: pageScroll
                    ink: Theme.cream
                }
            }
        }
    }

    // ── Centred picker, hosted by this window ─────────────────────────────

    FocusScope {
        id: pickerFocus

        anchors.fill: parent
        z: 1000
        focus: root.pickerHere

        Keys.onEscapePressed: Selector.close()
        Keys.onUpPressed: (e) => { Selector.move(-1); e.accepted = true; }
        Keys.onDownPressed: (e) => { Selector.move(1); e.accepted = true; }
        Keys.onLeftPressed: (e) => { Selector.move(-1); e.accepted = true; }
        Keys.onRightPressed: (e) => { Selector.move(1); e.accepted = true; }
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                if (!e.isAutoRepeat)
                    Selector.activate();
                e.accepted = true;
            }
        }

        StopSelector {
            anchors.fill: parent
            s: root.s
            active: root.pickerHere
        }
    }

    onPickerHereChanged: {
        if (root.pickerHere)
            pickerFocus.forceActiveFocus();
        else
            Qt.callLater(root.takeFocus);
    }

    onScreenNameChanged: {
        if (Selector.open && Selector.owner !== root.pickerKey)
            Selector.close();
    }
}
