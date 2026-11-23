pragma ComponentBehavior: Bound

import QtQuick
import "../Singletons"
import "../components"

/**
 * 智 AI USAGE surface: the subscription meters and local token totals for the
 * AI agents in use. The records come from AiUsage, which reads OpenCode's own
 * database and plan endpoint. Modelled on Omarchy's agents panel: a hero per
 * provider, a meter and reset countdown per limit window, then today, the last
 * seven days and the models those tokens went to.
 *
 * The OpenCode mark is the official transparent logo from opencode.ai/brand,
 * used unmodified on a neutral tile per its guidelines.
 */
PillSurface {
    id: root

    mTop: 14
    mLeft: 18
    mRight: 18
    mBottom: 16

    implicitHeight: content.implicitHeight
    property int tick: 0

    onActiveChanged: if (active) AiUsage.refresh(false)

    Timer {
        interval: 30000
        repeat: true
        running: root.active
        onTriggered: root.tick++
    }

    readonly property var provider: AiUsage.providers.length > 0 ? AiUsage.providers[0] : null

    function providerMark(provider) {
        var id = String(provider && provider.id || "").toLowerCase();
        if (id === "opencode")
            return "OC";
        var name = String(provider && provider.name || "AI");
        return name.slice(0, 2).toUpperCase();
    }

    function fmtTokens(value) {
        var n = Number(value) || 0;
        if (n >= 1000000000) return (n / 1000000000).toFixed(1) + "B";
        if (n >= 1000000) return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1) + "M";
        if (n >= 1000) return (n / 1000).toFixed(n >= 10000 ? 0 : 1) + "K";
        return String(Math.round(n));
    }

    function pct(value) {
        return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100) + "%";
    }

    function limitColor(value) {
        var n = Number(value) || 0;
        if (n >= 0.9) return Theme.verm;
        if (n >= 0.7) return Theme.flameGlow;
        return Theme.vermLit;
    }

    function resetLabel(iso) {
        void root.tick;
        if (!iso) return "";
        var when = Date.parse(iso);
        if (isNaN(when)) return "";
        var diff = when - Date.now();
        if (diff <= 0) return "resets now";
        var minutes = Math.floor(diff / 60000);
        var hours = Math.floor(minutes / 60);
        var days = Math.floor(hours / 24);
        if (days > 0) return "resets in " + days + "d " + (hours % 24) + "h";
        if (hours > 0) return "resets in " + hours + "h " + (minutes % 60) + "m";
        return "resets in " + Math.max(1, minutes) + "m";
    }

    function updatedLabel() {
        void root.tick;
        if (AiUsage.loading) return "Refreshing…";
        if (AiUsage.fetchedAtMs <= 0) return "Not loaded";
        var minutes = Math.max(0, Math.floor((Date.now() - AiUsage.fetchedAtMs) / 60000));
        if (minutes < 1) return "Updated just now";
        if (minutes < 60) return "Updated " + minutes + "m ago";
        return "Updated " + Math.floor(minutes / 60) + "h ago";
    }

    function dayLabel(iso) {
        var date = new Date(String(iso) + "T12:00:00");
        return isNaN(date.getTime()) ? "" : Qt.formatDate(date, "ddd");
    }

    function dayMax(provider) {
        var max = 0;
        var days = provider && provider.recentDays ? provider.recentDays : [];
        for (var i = 0; i < days.length; i++)
            max = Math.max(max, Number(days[i].tokens) || 0);
        return max;
    }

    function modelTotal(bucket) {
        return (Number(bucket.inputTokens) || 0)
            + (Number(bucket.outputTokens) || 0)
            + (Number(bucket.cacheReadInputTokens) || 0)
            + (Number(bucket.cacheCreationInputTokens) || 0);
    }

    function topModels(provider) {
        var usage = provider && provider.modelUsage ? provider.modelUsage : {};
        var out = [];
        for (var name in usage) {
            var total = root.modelTotal(usage[name]);
            if (total > 0)
                out.push({ name: name, tokens: total });
        }
        out.sort(function (a, b) { return b.tokens - a.tokens; });
        return out.slice(0, 4);
    }

    function topModelTokens(provider) {
        var models = root.topModels(provider);
        return models.length > 0 ? models[0].tokens : 0;
    }

    Column {
        id: content

        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 22 * root.s

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "智"
                    color: Theme.cream
                    font.family: Theme.fontJp
                    font.weight: Theme.fontJpWeight
                    font.pixelSize: 16 * root.s
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AI USAGE"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.6 * root.s
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.updatedLabel()
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Medium
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15 * root.s
                    height: 15 * root.s

                    GlyphIcon {
                        id: refreshGlyph
                        anchors.fill: parent
                        name: "reboot"
                        color: refreshArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.8

                        RotationAnimator {
                            target: refreshGlyph
                            running: AiUsage.loading
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) refreshGlyph.rotation = 0
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        anchors.margins: -5 * root.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AiUsage.refresh(true)
                    }
                }
            }
        }

        Column {
            width: parent.width
            topPadding: 12 * root.s
            bottomPadding: 10 * root.s
            spacing: 14 * root.s

            Text {
                visible: AiUsage.loading && !AiUsage.hasProviders
                width: parent.width
                text: "Reading OpenCode usage…"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: !AiUsage.loading && !AiUsage.hasProviders && AiUsage.error.length > 0
                width: parent.width
                text: AiUsage.error
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 10.5 * root.s
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: !AiUsage.loading && !AiUsage.hasProviders && AiUsage.error.length === 0
                width: parent.width
                text: "No AI usage found"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 11.5 * root.s
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: !AiUsage.loading && !AiUsage.hasProviders && AiUsage.error.length === 0
                width: parent.width
                text: "Use an agent such as OpenCode, then refresh."
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: AiUsage.providers

                Column {
                    id: providerCol
                    required property var modelData
                    width: content.width
                    spacing: 12 * root.s

                    Item {
                        width: parent.width
                        height: 38 * root.s

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10 * root.s

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36 * root.s
                                height: width
                                radius: 10 * root.s
                                color: Theme.frameBg
                                border.width: 1
                                border.color: Theme.hairSoft

                                Image {
                                    anchors.centerIn: parent
                                    visible: String(providerCol.modelData.id || "") === "opencode"
                                    width: 16 * root.s
                                    height: 20 * root.s
                                    source: Theme.light
                                        ? Qt.resolvedUrl("../assets/opencode-logo-transparent-light.svg")
                                        : Qt.resolvedUrl("../assets/opencode-logo-transparent-dark.svg")
                                    sourceSize: Qt.size(32 * root.s, 40 * root.s)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: String(providerCol.modelData.id || "") !== "opencode"
                                    text: root.providerMark(providerCol.modelData)
                                    color: Theme.vermLit
                                    font.family: Theme.font
                                    font.pixelSize: 9 * root.s
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5 * root.s
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * root.s

                                Text {
                                    text: String(providerCol.modelData.name || "OpenCode").toUpperCase()
                                    color: Theme.cream
                                    font.family: Theme.font
                                    font.pixelSize: 12.5 * root.s
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8 * root.s
                                }

                                Text {
                                    visible: String(providerCol.modelData.tierLabel || "").length > 0
                                    text: String(providerCol.modelData.tierLabel || "") + " plan"
                                    color: Theme.faint
                                    font.family: Theme.font
                                    font.pixelSize: 9.5 * root.s
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 9 * root.s

                        Repeater {
                            model: providerCol.modelData.limits || []

                            Column {
                                id: limitItem
                                required property var modelData
                                width: parent.width
                                spacing: 4 * root.s

                                Item {
                                    width: parent.width
                                    height: 14 * root.s

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: String(limitItem.modelData.label || "")
                                        color: Theme.subtle
                                        font.family: Theme.font
                                        font.pixelSize: 10.5 * root.s
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.pct(limitItem.modelData.percent)
                                        color: root.limitColor(limitItem.modelData.percent)
                                        font.family: Theme.font
                                        font.pixelSize: 10.5 * root.s
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 4 * root.s

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: Theme.hair
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(2 * root.s, parent.width * Math.max(0, Math.min(1, Number(limitItem.modelData.percent) || 0)))
                                        height: parent.height
                                        radius: height / 2
                                        color: root.limitColor(limitItem.modelData.percent)
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root.resetLabel(limitItem.modelData.resetsAt)
                                    color: Theme.faint
                                    font.family: Theme.font
                                    font.pixelSize: 8.5 * root.s
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Text {
                            visible: (providerCol.modelData.limits || []).length === 0
                            width: parent.width
                            text: String(providerCol.modelData.authHelpText || "") !== ""
                                ? String(providerCol.modelData.authHelpText)
                                : "No subscription limits reported."
                            color: String(providerCol.modelData.authHelpText || "") !== "" ? Theme.vermLit : Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 9.5 * root.s
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: (providerCol.modelData.limits || []).length > 0
                                && String(providerCol.modelData.authHelpText || "") !== ""
                            width: parent.width
                            text: String(providerCol.modelData.authHelpText || "")
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.hair
                    }

                    Row {
                        width: parent.width
                        spacing: 18 * root.s

                        Column {
                            spacing: 2 * root.s
                            Text {
                                text: "TODAY"
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 8 * root.s
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9 * root.s
                            }
                            Text {
                                text: root.fmtTokens(providerCol.modelData.todayTokens)
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                            }
                        }

                        Column {
                            spacing: 2 * root.s
                            Text {
                                text: "7 DAYS"
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 8 * root.s
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9 * root.s
                            }
                            Text {
                                text: root.fmtTokens(providerCol.modelData.weekTokens)
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                            }
                        }

                        Column {
                            spacing: 2 * root.s
                            Text {
                                text: "SESSIONS"
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 8 * root.s
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9 * root.s
                            }
                            Text {
                                text: String(providerCol.modelData.totalSessions || 0)
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 5 * root.s

                        Text {
                            text: "LAST 7 DAYS"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 8 * root.s
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9 * root.s
                        }

                        Item {
                            id: chart

                            width: parent.width
                            height: 54 * root.s

                            readonly property real barMax: root.dayMax(providerCol.modelData)

                            Row {
                                anchors.fill: parent
                                spacing: 6 * root.s

                                Repeater {
                                    model: providerCol.modelData.recentDays || []

                                    Item {
                                        id: dayItem
                                        required property int index
                                        required property var modelData
                                        width: (parent.width - 6 * 6 * root.s) / 7
                                        height: parent.height

                                        Rectangle {
                                            anchors.bottom: dayLabel.top
                                            anchors.bottomMargin: 3 * root.s
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 10 * root.s
                                            height: chart.barMax > 0
                                                ? Math.max(3 * root.s, 32 * root.s * Math.sqrt((Number(dayItem.modelData.tokens) || 0) / chart.barMax))
                                                : 3 * root.s
                                            radius: width / 2
                                            color: dayItem.index === 6 ? Theme.vermLit : Qt.alpha(Theme.vermLit, 0.42)
                                        }

                                        Text {
                                            id: dayLabel
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            text: root.dayLabel(dayItem.modelData.date)
                                            color: dayItem.index === 6 ? Theme.subtle : Theme.faint
                                            font.family: Theme.font
                                            font.pixelSize: 8 * root.s
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 4 * root.s
                        visible: root.topModels(providerCol.modelData).length > 0

                        Text {
                            text: "ALL-TIME MODELS"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 8 * root.s
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9 * root.s
                        }

                        Repeater {
                            model: root.topModels(providerCol.modelData)

                            Item {
                                id: modelRow
                                required property var modelData
                                width: parent.width
                                height: 18 * root.s

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.48
                                    text: String(modelRow.modelData.name)
                                    color: Theme.subtle
                                    font.family: Theme.font
                                    font.pixelSize: 9.5 * root.s
                                    elide: Text.ElideRight
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.leftMargin: parent.width * 0.5
                                    anchors.right: modelValue.left
                                    anchors.rightMargin: 8 * root.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 4 * root.s

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: Theme.hair
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(2 * root.s, parent.width * (Number(modelRow.modelData.tokens) || 0) / Math.max(1, root.topModelTokens(providerCol.modelData)))
                                        height: parent.height
                                        radius: height / 2
                                        color: Qt.alpha(Theme.cream, 0.38)
                                    }
                                }

                                Text {
                                    id: modelValue
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.fmtTokens(modelRow.modelData.tokens)
                                    color: Theme.faint
                                    font.family: Theme.font
                                    font.pixelSize: 8.5 * root.s
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: AiUsage.hasProviders && AiUsage.error.length > 0
                width: parent.width
                text: AiUsage.error
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                wrapMode: Text.WordWrap
            }
        }
    }
}
