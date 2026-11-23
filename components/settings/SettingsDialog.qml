import QtQuick
import QtQuick.Effects
import "../../Singletons"
import ".."
import "."

/**
 * A modal sheet drawn over the standalone settings card.
 *
 * The reference settings windows present advanced editors as sheets attached to
 * the window rather than as another column page: the category stays visible,
 * the sheet carries its own heading, and dismissing it returns exactly where the
 * user was. The same model is used here so row actions such as Theme, Accent or
 * Dock apps no longer replace the page they were opened from.
 *
 * A single instance is reused for every editor. `components` maps a dialog id
 * to the surface component and `meta` carries its title, subtitle and hosting
 * flags; the currently open pair is held until the close animation ends so the
 * sheet never blanks mid-fade.
 */
Item {
    id: root

    property real s: 1
    property real cornerRadius: 28 * root.s
    property bool open: false
    property string dialogId: ""
    property var meta: ({})
    property var components: ({})

    signal closed()
    signal requestPage(string page)

    readonly property var def: root.dialogId.length > 0 && root.meta[root.dialogId] !== undefined
        ? root.meta[root.dialogId] : null

    property string heldId: ""
    property string heldTitle: ""
    property string heldSubtitle: ""
    property bool heldNested: false
    property bool heldAssignPal: false
    property bool heldChromeless: false
    property bool alive: false

    readonly property real headerH: 76 * root.s
    readonly property real contentPad: 20 * root.s
    readonly property real maxSheetH: Math.max(280 * root.s,
        (root.parent ? root.parent.height : 720 * root.s) - 96 * root.s)
    readonly property real maxBodyH: Math.max(160 * root.s, root.maxSheetH - root.headerH)
    readonly property real wantedBodyH: host.implicitHeight + 2 * root.contentPad
    readonly property real bodyH: Math.min(root.wantedBodyH, root.maxBodyH)

    anchors.fill: parent
    z: 500
    visible: root.alive || root.open
    opacity: root.open ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
    }

    function takeFocus() {
        if (!root.alive || !root.open)
            return;
        // Keep focus where a hosted surface already put it (a search field, a
        // slider the user just clicked) so a late callLater cannot pull the
        // caret out of the control being used.
        var win = root.Window.window;
        var item = win ? win.activeFocusItem : null;
        while (item) {
            if (item === focusScope)
                return;
            item = item.parent;
        }
        // Searchable surfaces ask for the caret as soon as they load; prefer
        // that over parking focus on the scope with no visible target.
        if (host.focusInitial())
            return;
        focusScope.forceActiveFocus();
    }

    function syncHeld() {
        if (!root.def)
            return;
        root.heldId = root.dialogId;
        root.heldTitle = root.def.title || "";
        root.heldSubtitle = root.def.subtitle || "";
        root.heldNested = root.def.nested === true;
        root.heldAssignPal = root.def.assignPal === true;
        root.heldChromeless = root.def.chromeless === true;
    }

    onOpenChanged: {
        if (root.open) {
            closeTimer.stop();
            root.alive = true;
            root.syncHeld();
            Qt.callLater(root.takeFocus);
        } else if (root.alive) {
            closeTimer.restart();
        }
    }

    onDialogIdChanged: if (root.open) root.syncHeld()

    Timer {
        id: closeTimer
        interval: Motion.fast + 20
        onTriggered: {
            root.alive = false;
            root.heldId = "";
        }
    }

    // ── Backdrop ──────────────────────────────────────────────────────────

    Rectangle {
        id: scrim

        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(0, 0, 0, Theme.light ? 0.20 : 0.36)
        visible: root.alive
        opacity: root.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.closed()
        }
    }

    // ── Sheet ─────────────────────────────────────────────────────────────

    Item {
        id: sheet

        anchors.centerIn: parent
        width: Math.min(620 * root.s,
            (root.parent ? root.parent.width : 620 * root.s) - 96 * root.s)
        height: root.headerH + root.bodyH + 1
        visible: root.alive
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.985

        transform: Translate {
            y: root.open ? 0 : 10 * root.s
            Behavior on y {
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: sheetBg

            anchors.fill: parent
            radius: 22 * root.s
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.cardTop }
                GradientStop { position: 1.0; color: Theme.cardBot }
            }
            border.width: 1
            border.color: Theme.border

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: 0.9
                shadowVerticalOffset: 18 * root.s
            }
        }

        /** Swallow clicks on the sheet so only the scrim dismisses it. */
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: focusScope.forceActiveFocus()
        }

        Item {
            id: header

            width: parent.width
            height: root.headerH

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 24 * root.s
                anchors.right: closeButton.left
                anchors.rightMargin: 16 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * root.s

                Text {
                    width: parent.width
                    text: root.heldTitle
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 17 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: root.heldSubtitle
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 11.5 * root.s
                    elide: Text.ElideRight
                }
            }

            SettingsToolButton {
                id: closeButton

                s: root.s
                icon: "close"
                anchors.right: parent.right
                anchors.rightMargin: 18 * root.s
                anchors.verticalCenter: parent.verticalCenter
                onTriggered: root.closed()
            }
        }

        Rectangle {
            id: headerRule

            anchors.top: header.bottom
            width: parent.width
            height: 1
            color: Theme.hairSoft
        }

        FocusScope {
            id: focusScope

            anchors.top: headerRule.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            focus: root.open

            Keys.onEscapePressed: (e) => {
                root.closed();
                e.accepted = true;
            }
            Keys.onUpPressed: (e) => { host.kbMove(-1); e.accepted = true; }
            Keys.onDownPressed: (e) => { host.kbMove(1); e.accepted = true; }
            Keys.onLeftPressed: (e) => { host.kbAdjust(-1); e.accepted = true; }
            Keys.onRightPressed: (e) => { host.kbAdjust(1); e.accepted = true; }
            Keys.onReturnPressed: (e) => { host.kbActivate(); e.accepted = true; }
            Keys.onEnterPressed: (e) => { host.kbActivate(); e.accepted = true; }
            Keys.onSpacePressed: (e) => { host.kbActivate(); e.accepted = true; }

            Flickable {
                id: bodyFlick

                anchors.fill: parent
                contentWidth: width
                contentHeight: host.y + host.implicitHeight + root.contentPad
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                SettingsSurfaceHost {
                    id: host

                    x: root.contentPad
                    y: root.contentPad
                    width: bodyFlick.width - 2 * root.contentPad
                    s: root.s * 1.12
                    page: root.components[root.heldId] || null
                    assignPal: root.heldAssignPal
                    chromeless: root.heldChromeless
                    onRequestPage: (page) => root.requestPage(page)
                    onRequestBack: root.closed()
                }
            }

            WheelScroller {
                anchors.fill: parent
                s: root.s
                flick: bodyFlick
                enabled: !root.heldNested
            }

            ScrollRail {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 6 * root.s
                anchors.topMargin: 10 * root.s
                anchors.bottomMargin: 10 * root.s
                s: root.s
                flick: bodyFlick
                ink: Theme.cream
                visible: bodyFlick.contentHeight > bodyFlick.height + 0.5
            }
        }
    }
}
