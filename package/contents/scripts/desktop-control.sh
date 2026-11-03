#!/usr/bin/env bash
# Helper invoked by the Plasma 5 widget's executable data engine.
# Desktop names are persistent KDE/KWin settings; session-only notes never enter here.
set -euo pipefail

usage() {
    echo "Usage: desktop-control.sh settings | rename <desktop-id-or-number> <position> <new-name>" >&2
    exit 2
}

command="${1:-}"
case "$command" in
    settings)
        [[ $# -eq 1 ]] || usage
        if command -v systemsettings5 >/dev/null 2>&1; then
            nohup systemsettings5 kcm_kwin_virtualdesktops >/dev/null 2>&1 </dev/null &
        elif command -v kcmshell5 >/dev/null 2>&1; then
            nohup kcmshell5 kcm_kwin_virtualdesktops >/dev/null 2>&1 </dev/null &
        else
            echo "KDE System Settings 5 is not installed." >&2
            exit 1
        fi
        ;;
    rename)
        [[ $# -eq 4 ]] || usage
        desktop_key="$2"
        position="$3"
        name="$4"
        [[ "$position" =~ ^[1-9][0-9]*$ ]] || { echo "Invalid desktop position." >&2; exit 2; }
        [[ "$name" != *$'\n'* && "$name" != *$'\r'* ]] || {
            echo "The desktop name must be on one line." >&2
            exit 2
        }
        # Keep helper and popup consistent: blank names restore Desktop N.
        if [[ -z "${name//[[:space:]]/}" ]]; then
            name="Desktop ${position}"
        fi
        command -v dbus-send >/dev/null 2>&1 || { echo "dbus-send is required." >&2; exit 1; }

        # TaskManager.VirtualDesktopInfo exposes 1-based numbers on X11 but
        # UUID strings on Wayland. KWin's D-Bus setter *always* expects a UUID.
        if [[ "$desktop_key" =~ ^[1-9][0-9]*$ ]]; then
            [[ "$desktop_key" == "$position" ]] || { echo "Desktop ID/position mismatch." >&2; exit 2; }
            if command -v kreadconfig5 >/dev/null 2>&1; then
                desktop_key="$(kreadconfig5 --file kwinrc --group Desktops --key "Id_${position}")"
            else
                config_file="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc"
                [[ -f "$config_file" ]] || { echo "Could not locate KWin configuration." >&2; exit 1; }
                desktop_key="$(awk -F= -v wanted="Id_${position}" '$1 == wanted { print substr($0, index($0, "=") + 1); exit }' "$config_file")"
            fi
            [[ -n "$desktop_key" ]] || { echo "Could not resolve the KWin desktop UUID." >&2; exit 1; }
        fi
        dbus-send --session --print-reply --reply-timeout=4000 \
            --dest=org.kde.KWin /VirtualDesktopManager \
            org.kde.KWin.VirtualDesktopManager.setDesktopName \
            "string:${desktop_key}" "string:${name}" >/dev/null

        # Also persist the numbered name in kwinrc for affected KWin releases.
        # Keep the in-memory KWin rename authoritative; never restart KWin.
        if command -v kwriteconfig5 >/dev/null 2>&1; then
            kwriteconfig5 --file kwinrc --group Desktops --key "Name_${position}" "$name"
        fi
        ;;
    *) usage ;;
esac
