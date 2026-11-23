# Keybindings and IPC

Ukishima does not install compositor keybindings. Add only the actions you want to your own configuration. The examples use `~/.local/share/quickshell/ukishima`; adjust the path if you installed elsewhere.

## Start at login

**Hyprland — hyprlang**

```ini
exec-once = ~/.local/share/quickshell/ukishima/launch.sh
exec-once = awww-daemon
```

**Hyprland — Lua**

```lua
hl.exec_cmd("~/.local/share/quickshell/ukishima/launch.sh")
hl.exec_cmd("awww-daemon")
```

**niri — KDL**

```kdl
spawn-at-startup "sh" "-c" "exec $HOME/.local/share/quickshell/ukishima/launch.sh"
spawn-at-startup "awww-daemon"
```

## Example bindings

The Quickshell IPC command opens the named surface on the focused monitor when the monitor argument is `""`.

**Hyprland — hyprlang**

```ini
bind = SUPER SHIFT, W, exec, qs -p ~/.local/share/quickshell/ukishima ipc call ukishima wallpaper ""
bind = SUPER SHIFT, V, exec, qs -p ~/.local/share/quickshell/ukishima ipc call ukishima clipboard ""
bind = SUPER, slash, exec, qs -p ~/.local/share/quickshell/ukishima ipc call ukishima launcher ""
bind = SUPER, N, exec, qs -p ~/.local/share/quickshell/ukishima ipc call ukishima notifications ""
bind = SUPER, L, exec, ~/.local/share/quickshell/ukishima/scripts/lock.sh
```

**Hyprland — Lua**

`var_mainMod` should be replaced with the main modifier variable in your config.

```lua
local uk = "qs -p ~/.local/share/quickshell/ukishima"
hl.bind(var_mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(uk .. " ipc call ukishima wallpaper \"\""))
hl.bind(var_mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(uk .. " ipc call ukishima clipboard \"\""))
hl.bind(var_mainMod .. " + slash", hl.dsp.exec_cmd(uk .. " ipc call ukishima launcher \"\""))
hl.bind(var_mainMod .. " + N", hl.dsp.exec_cmd(uk .. " ipc call ukishima notifications \"\""))
hl.bind(var_mainMod .. " + L", hl.dsp.exec_cmd("~/.local/share/quickshell/ukishima/scripts/lock.sh"))
```

**niri — KDL**

`Mod` is Super by default. niri's `spawn-sh` runs each command through a shell.

```kdl
binds {
    Mod+Shift+W { spawn-sh "qs -p $HOME/.local/share/quickshell/ukishima ipc call ukishima wallpaper \"\""; }
    Mod+Shift+V { spawn-sh "qs -p $HOME/.local/share/quickshell/ukishima ipc call ukishima clipboard \"\""; }
    Mod+Slash { spawn-sh "qs -p $HOME/.local/share/quickshell/ukishima ipc call ukishima launcher \"\""; }
    Mod+N { spawn-sh "qs -p $HOME/.local/share/quickshell/ukishima ipc call ukishima notifications \"\""; }
    Mod+L { spawn-sh "$HOME/.local/share/quickshell/ukishima/scripts/lock.sh"; }
}
```

For media keys on niri, use niri's native bindings. Ukishima's global shortcut provider is Hyprland-only.

## IPC reference

List the calls exposed by the running shell:

```bash
qs -p ~/.local/share/quickshell/ukishima ipc show
```

Open the launcher on the focused monitor:

```bash
qs -p ~/.local/share/quickshell/ukishima ipc call ukishima launcher ""
```

Open the settings window on the focused monitor:

```bash
qs -p ~/.local/share/quickshell/ukishima ipc call ukishima settings ""
```

Calling a surface again toggles it closed. Most surface calls accept a monitor name; use `""` for the focused monitor.

- `launcher` — app launcher
- `wallpaper` — wallpaper strip and Wallhaven search
- `clipboard` — clipboard history
- `notifications` — notification history
- `battery` — battery surface
- `sysmon` / `system` — system monitor
- `recorder` / `record` / `screenrec` — screen recorder
- `quickRecord` — start, stop, cancel or dismiss quick recording
- `gameMode` — toggle game mode
- `power` — power menu
- `peek` — toggle the pill's peek view
- `hide` — close the open surface and the settings window
- `page` — open a surface by name; legacy settings-surface names open the matching settings page
- `settings` — open or close the settings window on the focused monitor
- `settingsPage` — open the settings window at a page or editor sheet id
- `unloadAll` — free closed surfaces
- `minimizeWindow` / `restoreWindow` — minimize or restore a Hyprland window
- `emoji` — emoji picker
- `calendar` — calendar
- `mixer` — audio mixer
- `media` — media surface, when a player is running
- `barIsland`, `appearance`, `motion`, `interface`, `lock`, `dock`, `systemSettings` — main settings pages for `settingsPage`
- `themeDetails`, `accentEditor`, `fontColorEditor`, `fontPicker`, `rightClickDetails`, `lockDetails`, `dockThemeDetails`, `dockApps`, `updateDetails` — editor sheets, opened over their parent settings page
- `profileDetails` — the Profile page (the only settings subpage)
- `appearance`, `appcat`, `display`, `modules`, `theme`, `accent`, `glass`, `fontcolor`, `rightclick`, `fontpicker`, `locksettings`, `update`, `profile`, `surfacestyles`, `dockSettings`, `dockBehavior`, `dockAppearance`, `dockApps`, `dockMotion` — legacy settings-surface names, mapped to the new pages and editor sheets
- `wifi`, `bt`, `weather`, `timer` — regular surfaces

Locking is started with `scripts/lock.sh`; it is not an IPC surface. `awww-daemon` can be started at login or left for the shell to start on demand.
