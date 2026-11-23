pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * AI subscription usage for the pill.
 *
 * The records come from scripts/ai-usage.py, which reads OpenCode's own
 * database and usage endpoint. The singleton refreshes on startup and every
 * fifteen minutes, and keeps the last good records if a refresh fails.
 */
Singleton {
    id: root

    property var providers: []
    property bool loading: false
    property string error: ""
    property double fetchedAtMs: 0

    readonly property bool hasProviders: Array.isArray(root.providers) && root.providers.length > 0
    readonly property real topLimit: {
        var top = -1;
        for (var i = 0; i < root.providers.length; i++) {
            var limits = root.providers[i].limits || [];
            for (var j = 0; j < limits.length; j++) {
                var value = Number(limits[j].percent);
                if (!isNaN(value))
                    top = Math.max(top, value);
            }
        }
        return top;
    }

    function refresh(force) {
        if (proc.running)
            return;
        if (!force && root.fetchedAtMs > 0 && Date.now() - root.fetchedAtMs < 60000)
            return;
        root.loading = true;
        root.error = "";
        proc.running = true;
    }

    function apply(raw) {
        try {
            var data = JSON.parse(String(raw || "{}"));
            var list = data.providers;
            root.providers = Array.isArray(list) ? list : [];
            root.error = typeof data.error === "string" ? data.error : "";
            root.fetchedAtMs = Date.now();
        } catch (e) {
            root.error = "Could not read the AI usage report.";
        }
    }

    Component.onCompleted: root.refresh(true)

    Process {
        id: proc

        command: ["python3", Config.hyprPath("scripts", "ai-usage.py")]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.apply(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.error = String(text).trim()
        }
        onExited: function(exitCode) {
            root.loading = false;
            if (exitCode !== 0 && root.error === "")
                root.error = "Could not read AI usage.";
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh(true)
    }
}
