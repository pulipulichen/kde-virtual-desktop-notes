#!/usr/bin/env bash
# Helper invoked by the Plasma 5 widget's executable data engine.
# Desktop names are persistent KDE/KWin settings; session-only notes never enter here.
set -euo pipefail

usage() {
    echo "Usage: desktop-control.sh settings | rename <desktop-id-or-number> <position> <new-name> | reset-all <desktop-id-or-number> <position> [<desktop-id-or-number> <position> ...]" >&2
    exit 2
}

# Reuse the same KWin D-Bus rename path for one desktop or for the full batch.
rename_desktop() {
    local desktop_key="$1" position="$2" name="$3" config_file
    [[ "$position" =~ ^[1-9][0-9]*$ ]] || { echo "Invalid desktop position." >&2; return 2; }
    [[ -n "$desktop_key" && "$desktop_key" != *$'\n'* && "$desktop_key" != *$'\r'* ]] || {
        echo "Invalid desktop ID." >&2
        return 2
    }
    [[ "$name" != *$'\n'* && "$name" != *$'\r'* ]] || {
        echo "The desktop name must be on one line." >&2
        return 2
    }
    # Blank names restore the stable English Desktop N default.
    if [[ -z "${name//[[:space:]]/}" ]]; then
        name="Desktop ${position}"
    fi
    command -v dbus-send >/dev/null 2>&1 || { echo "dbus-send is required." >&2; return 1; }

    # TaskManager.VirtualDesktopInfo exposes 1-based numbers on X11 but
    # UUID strings on Wayland. KWin's D-Bus setter always expects a UUID.
    if [[ "$desktop_key" =~ ^[1-9][0-9]*$ ]]; then
        [[ "$desktop_key" == "$position" ]] || { echo "Desktop ID/position mismatch." >&2; return 2; }
        if command -v kreadconfig5 >/dev/null 2>&1; then
            desktop_key="$(kreadconfig5 --file kwinrc --group Desktops --key "Id_${position}")" || {
                echo "Could not read the KWin desktop UUID." >&2
                return 1
            }
        else
            config_file="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc"
            [[ -f "$config_file" ]] || { echo "Could not locate KWin configuration." >&2; return 1; }
            desktop_key="$(awk -F= -v wanted="Id_${position}" '$1 == wanted { print substr($0, index($0, "=") + 1); exit }' "$config_file")"
        fi
        [[ -n "$desktop_key" ]] || { echo "Could not resolve the KWin desktop UUID." >&2; return 1; }
    fi
    dbus-send --session --print-reply --reply-timeout=4000 \
        --dest=org.kde.KWin /VirtualDesktopManager \
        org.kde.KWin.VirtualDesktopManager.setDesktopName \
        "string:${desktop_key}" "string:${name}" >/dev/null || {
            echo "KWin could not rename Desktop ${position}." >&2
            return 1
        }

    # Persist the numbered name in kwinrc for affected KWin releases.
    # Do not restart KWin or touch notes, colors, and icons.
    if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kwinrc --group Desktops --key "Name_${position}" "$name" || {
            echo "Could not persist the name of Desktop ${position}." >&2
            return 1
        }
    fi
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
        rename_desktop "$2" "$3" "$4"
        ;;
    reset-all)
        # Accept the IDs and their 1-based positions from VirtualDesktopInfo.
        # Validate the whole request before changing any names.
        [[ $# -ge 3 && $((($# - 1) % 2)) -eq 0 ]] || usage
        shift
        args=("$@")
        declare -A seen_positions=()
        for ((i = 0; i < ${#args[@]}; i += 2)); do
            key="${args[i]}"
            position="${args[i+1]}"
            [[ -n "$key" && "$key" != *$'\n'* && "$key" != *$'\r'* ]] || {
                echo "Invalid desktop ID." >&2
                exit 2
            }
            [[ "$position" =~ ^[1-9][0-9]*$ ]] || {
                echo "Invalid desktop position." >&2
                exit 2
            }
            if [[ "$key" =~ ^[1-9][0-9]*$ && "$key" != "$position" ]]; then
                echo "Desktop ID/position mismatch." >&2
                exit 2
            fi
            [[ -z "${seen_positions[$position]+x}" ]] || {
                echo "Duplicate desktop position: ${position}." >&2
                exit 2
            }
            seen_positions[$position]=1
        done

        failures=0
        for ((i = 0; i < ${#args[@]}; i += 2)); do
            position="${args[i+1]}"
            if ! rename_desktop "${args[i]}" "$position" "Desktop ${position}"; then
                echo "Failed to reset Desktop ${position}." >&2
                failures=$((failures + 1))
            fi
        done
        if (( failures > 0 )); then
            echo "Unable to reset ${failures} virtual desktop name(s)." >&2
            exit 1
        fi
        printf 'Reset %s desktop name(s).\n' "${#seen_positions[@]}"
        ;;
    *) usage ;;
esac
