pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live system facts for the profile page.
 *
 * Kept outside the page so the read-only information has one source of truth
 * and the file/process plumbing is not repeated in every presentation. The
 * values mirror what the old Profile surface collected: distro, host, kernel,
 * CPU, GPU, memory, disk, packages and uptime.
 *
 * The profile is informational. Nothing here writes system state.
 */
Singleton {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    readonly property string shellName: {
        const sh = Quickshell.env("SHELL") || "";
        const i = sh.lastIndexOf("/");
        return i >= 0 ? sh.slice(i + 1) : sh;
    }
    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP")
        || (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "Hyprland"
            : (Quickshell.env("NIRI_SOCKET") ? "niri" : ""))
    readonly property string sessionType: Quickshell.env("XDG_SESSION_TYPE") || "wayland"

    /** Avatar shared with the lock screen; empty means the person glyph. */
    readonly property string facePath: {
        if (!Flags.lockShowAvatar)
            return "";
        const t = String(Flags.lockAvatarPath || "").trim();
        if (t === "")
            return "";
        if (t === "~")
            return root.homeDir;
        if (t.indexOf("~/") === 0)
            return root.homeDir + t.slice(1);
        return t;
    }

    // ── Distro ────────────────────────────────────────────────────────────

    property string distro: ""
    property string distroId: ""
    readonly property var distroGlyphs: ({
        "cachyos": 0xf385, "arch": 0xf303, "ubuntu": 0xf31b, "debian": 0xf306,
        "fedora": 0xf30a, "nixos": 0xf313, "manjaro": 0xf312, "garuda": 0xf337,
        "void": 0xf32e, "kali": 0xf327, "linuxmint": 0xf30e, "elementary": 0xf309,
        "solus": 0xf32d, "parrot": 0xf329, "slackware": 0xf318, "gentoo": 0xf30d,
        "centos": 0xf304, "alpine": 0xf300, "mx": 0xf33f, "pop": 0xf32a,
        "zorin": 0xf32f, "opensuse-tumbleweed": 0xf37d, "tumbleweed": 0xf37d,
        "opensuse-leap": 0xf37e, "leap": 0xf37e, "opensuse": 0xf314
    })
    readonly property string distroGlyph: String.fromCodePoint(
        root.distroGlyphs[root.distroId] !== undefined ? root.distroGlyphs[root.distroId] : 0xf31a)

    FileView {
        id: osRelease
        path: "file:///etc/os-release"
        printErrors: false
        onLoaded: {
            const text = osRelease.text();
            let name = "";
            let id = "";
            const lines = text.split("\n");
            for (const line of lines) {
                if (line.indexOf("PRETTY_NAME=") === 0)
                    name = line.slice(12).replace(/^"|"$/g, "");
                else if (line.indexOf("NAME=") === 0 && name === "")
                    id = line.slice(5).replace(/^"|"$/g, "");
                else if (line.indexOf("ID=") === 0)
                    root.distroId = line.slice(3).replace(/^"|"$/g, "").toLowerCase();
            }
            root.distro = name !== "" ? name : id;
        }
    }

    // ── Host / kernel / arch ─────────────────────────────────────────────

    property string hostName: ""
    FileView {
        id: etcHostname
        path: "file:///etc/hostname"
        printErrors: false
        onLoaded: root.hostName = etcHostname.text().trim()
    }

    property string kernel: ""
    Process {
        id: kernelProc
        running: true
        command: ["uname", "-r"]
        stdout: SplitParser { onRead: (line) => root.kernel = line.trim() }
    }

    property string architecture: ""
    Process {
        id: archProc
        running: true
        command: ["uname", "-m"]
        stdout: SplitParser { onRead: (line) => root.architecture = line.trim() }
    }

    // ── Hardware ──────────────────────────────────────────────────────────

    property string cpu: ""
    FileView {
        id: procCpuinfo
        path: "file:///proc/cpuinfo"
        printErrors: false
        onLoaded: {
            const match = procCpuinfo.text().match(/model name\s*:\s*(.+)/);
            if (!match)
                return;
            let name = match[1].trim();
            name = name.replace(/^(AMD|Intel|Apple|AuthenticAMD)\s+/i, "");
            name = name.replace(/\s+with\s+.*(Graphics|graphics)$/i, "");
            root.cpu = name;
        }
    }

    property string gpuRaw: ""
    Process {
        id: gpuProc
        running: true
        command: ["sh", "-c", "lspci 2>/dev/null | grep -iE 'VGA|3D controller|Display controller' | head -n 1"]
        stdout: SplitParser { onRead: (line) => root.gpuRaw = line.trim() }
    }
    readonly property string gpu: {
        let text = root.gpuRaw.replace(/^[0-9a-fA-F:.]+\s+.*?:\s*/, "");
        text = text.replace(/^(Advanced Micro Devices,?\s*Inc\.?(\s*\[AMD\/ATI\])?|NVIDIA Corporation|Intel Corporation)\s*/i, "");
        text = text.replace(/\s*\(rev\s+[^)]*\)\s*$/i, "");
        return text.trim();
    }

    property real uptimeSec: 0
    FileView {
        id: procUptime
        path: "file:///proc/uptime"
        printErrors: false
        onLoaded: {
            const value = parseFloat(procUptime.text().split(" ")[0]);
            if (!isNaN(value))
                root.uptimeSec = value;
        }
    }
    readonly property string uptime: {
        let seconds = Math.floor(root.uptimeSec);
        const days = Math.floor(seconds / 86400);
        seconds -= days * 86400;
        const hours = Math.floor(seconds / 3600);
        seconds -= hours * 3600;
        const minutes = Math.floor(seconds / 60);
        if (days > 0) return days + "d " + hours + "h";
        if (hours > 0) return hours + "h " + minutes + "m";
        return minutes + "m";
    }

    property real memUsedGiB: 0
    property real memTotalGiB: 0
    readonly property real memPct: root.memTotalGiB > 0 ? root.memUsedGiB / root.memTotalGiB : 0
    readonly property string memory: root.memTotalGiB > 0
        ? root.memUsedGiB.toFixed(1) + " / " + root.memTotalGiB.toFixed(1) + " GiB"
        : ""
    FileView {
        id: procMeminfo
        path: "file:///proc/meminfo"
        printErrors: false
        onLoaded: {
            const text = procMeminfo.text();
            const total = text.match(/MemTotal:\s+(\d+)/);
            const available = text.match(/MemAvailable:\s+(\d+)/);
            if (total && available) {
                const totalGiB = parseInt(total[1], 10) / 1048576;
                const usedGiB = (parseInt(total[1], 10) - parseInt(available[1], 10)) / 1048576;
                root.memTotalGiB = totalGiB;
                root.memUsedGiB = usedGiB;
            }
        }
    }

    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    readonly property real diskPct: root.diskTotalGiB > 0 ? root.diskUsedGiB / root.diskTotalGiB : 0
    readonly property string disk: root.diskTotalGiB > 0
        ? root.diskUsedGiB.toFixed(1) + " / " + root.diskTotalGiB.toFixed(1) + " GiB"
        : ""
    Process {
        id: diskProc
        running: true
        command: ["sh", "-c", "df -B1 / | awk 'NR==2 {printf \"%.1f %.1f\", $3/1073741824, $2/1073741824}'"]
        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split(/\s+/);
                if (parts.length >= 2) {
                    root.diskUsedGiB = parseFloat(parts[0]);
                    root.diskTotalGiB = parseFloat(parts[1]);
                }
            }
        }
    }

    property string pkgCount: ""
    Process {
        id: pkgProc
        running: true
        command: ["sh", "-c",
            "if command -v pacman >/dev/null; then pacman -Q | wc -l; "
            + "elif command -v dpkg-query >/dev/null; then dpkg-query -f '${binary:Package}\\n' -W | wc -l; "
            + "elif command -v rpm >/dev/null; then rpm -qa | wc -l; fi"]
        stdout: SplitParser { onRead: (line) => root.pkgCount = line.trim() }
    }

    /** Re-read the live facts; called when the profile page is opened. */
    function refresh() {
        osRelease.reload();
        etcHostname.reload();
        procUptime.reload();
        procCpuinfo.reload();
        procMeminfo.reload();
        kernelProc.running = true;
        archProc.running = true;
        gpuProc.running = true;
        diskProc.running = true;
        pkgProc.running = true;
    }
}
