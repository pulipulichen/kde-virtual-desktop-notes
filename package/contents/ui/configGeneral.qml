import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.taskmanager 0.1 as TaskManager
import "DesktopPalette.js" as DesktopPalette

ColumnLayout {
    id: settings
    spacing: 12

    property alias cfg_noteWidth: widthSpin.value
    property alias cfg_showDesktopName: showName.checked
    property alias cfg_desktopNameOnly: nameOnly.checked
    // Persist only visual overrides, not session-only note content.
    property string cfg_desktopColors: "{}"

    property string selectedDesktopKey: ""
    property string selectedForegroundOverride: ""
    property string selectedBackgroundOverride: ""
    property string selectedTitleOverride: ""
    property string selectedNoteOverride: ""

    readonly property var desktopChoices: {
        var choices = []
        var ids = desktopInfo.desktopIds || []
        var names = desktopInfo.desktopNames || []
        for (var i = 0; i < ids.length; i++) {
            var name = names.length > i ? String(names[i]).trim() : ""
            choices.push({
                key: String(ids[i]),
                number: i + 1,
                label: name.length ? name : qsTr("Desktop %1").arg(i + 1)
            })
        }
        if (choices.length === 0) {
            var id = desktopInfo.currentDesktop
            choices.push({
                key: id === undefined || id === null || String(id) === ""
                     ? "__unknown__" : String(id),
                number: 1,
                label: qsTr("Current desktop")
            })
        }
        return choices
    }
    readonly property int selectedDesktopNumber: {
        for (var i = 0; i < desktopChoices.length; i++) {
            if (desktopChoices[i].key === selectedDesktopKey)
                return desktopChoices[i].number
        }
        return 1
    }
    readonly property var selectedPreset: DesktopPalette.forIndex(selectedDesktopNumber - 1)
    readonly property string selectedForegroundColor: DesktopPalette.isHexColor(selectedForegroundOverride)
            ? selectedForegroundOverride : selectedPreset.foreground
    readonly property string selectedBackgroundColor: DesktopPalette.isHexColor(selectedBackgroundOverride)
            ? selectedBackgroundOverride : selectedPreset.background
    readonly property string selectedTitleColor: DesktopPalette.isHexColor(selectedTitleOverride)
            ? selectedTitleOverride : selectedForegroundColor
    readonly property string selectedNoteColor: DesktopPalette.isHexColor(selectedNoteOverride)
            ? selectedNoteOverride : selectedForegroundColor

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    function readColorMap() {
        try {
            var parsed = JSON.parse(cfg_desktopColors || "{}")
            return parsed && typeof parsed === "object" && !Array.isArray(parsed)
                    ? parsed : {}
        } catch (error) {
            return {}
        }
    }

    function loadSelectedColors() {
        var entry = readColorMap()[selectedDesktopKey] || {}
        selectedForegroundOverride = DesktopPalette.isHexColor(entry.foreground) ? entry.foreground : ""
        selectedBackgroundOverride = DesktopPalette.isHexColor(entry.background) ? entry.background : ""
        selectedTitleOverride = DesktopPalette.isHexColor(entry.title) ? entry.title : ""
        selectedNoteOverride = DesktopPalette.isHexColor(entry.note) ? entry.note : ""
    }

    function syncDesktopSelection() {
        var index = -1
        for (var i = 0; i < desktopChoices.length; i++) {
            if (desktopChoices[i].key === selectedDesktopKey) {
                index = i
                break
            }
        }
        if (index === -1) {
            var active = String(desktopInfo.currentDesktop)
            for (var j = 0; j < desktopChoices.length; j++) {
                if (desktopChoices[j].key === active) {
                    index = j
                    break
                }
            }
            if (index === -1)
                index = 0
            selectedDesktopKey = desktopChoices[index].key
        }
        desktopSelect.currentIndex = index
    }

    function setColor(role, value) {
        if (!selectedDesktopKey)
            return
        if (value !== "" && !DesktopPalette.isHexColor(value))
            return

        var map = readColorMap()
        var entry = map[selectedDesktopKey] || {}
        if (value === "")
            delete entry[role]
        else
            entry[role] = value.toUpperCase()

        // A shared foreground choice supersedes historical per-text-role colors.
        if (role === "foreground") {
            delete entry.title
            delete entry.note
        }

        if (Object.keys(entry).length === 0)
            delete map[selectedDesktopKey]
        else
            map[selectedDesktopKey] = entry

        cfg_desktopColors = JSON.stringify(map)
        loadSelectedColors()
    }

    function applyPreset(index) {
        if (!selectedDesktopKey)
            return
        var chosen = DesktopPalette.forIndex(index)
        var map = readColorMap()
        map[selectedDesktopKey] = {
            foreground: chosen.foreground,
            background: chosen.background
        }
        cfg_desktopColors = JSON.stringify(map)
        loadSelectedColors()
    }

    function resetSelectedColors() {
        var map = readColorMap()
        delete map[selectedDesktopKey]
        cfg_desktopColors = JSON.stringify(map)
        loadSelectedColors()
    }

    onSelectedDesktopKeyChanged: loadSelectedColors()
    onCfg_desktopColorsChanged: loadSelectedColors()
    onDesktopChoicesChanged: Qt.callLater(syncDesktopSelection)
    Component.onCompleted: syncDesktopSelection()

    Controls.Label {
        text: qsTr("Panel widget width (pixels)")
    }

    Controls.SpinBox {
        id: widthSpin
        from: 80
        to: 900
        stepSize: 10
        editable: true
        value: 100
        Layout.preferredWidth: 180
    }

    Controls.CheckBox {
        id: nameOnly
        text: qsTr("Show only the virtual desktop name (hide notes)")
        checked: true
    }

    Controls.CheckBox {
        id: showName
        text: qsTr("Show the current virtual desktop name above notes")
        checked: true
        enabled: !nameOnly.checked
    }

    Controls.Label {
        text: qsTr("Colors for virtual desktop")
        font.bold: true
    }

    Controls.ComboBox {
        id: desktopSelect
        Layout.fillWidth: true
        model: settings.desktopChoices
        textRole: "label"
        onActivated: settings.selectedDesktopKey = settings.desktopChoices[index].key
    }

    Controls.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("Choose from 16 high-contrast Material 3-inspired color pairs. Each of desktops 1–16 gets a different automatic color; desktop 8 defaults to green. Customize foreground and background per desktop.")
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 6
        color: settings.selectedBackgroundColor
        border.color: "#808080"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Desktop %1 · %2").arg(settings.selectedDesktopNumber).arg(settings.selectedPreset.name)
                color: settings.selectedTitleColor
                font.bold: true
            }
            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Preview of the note text")
                color: settings.selectedNoteColor
            }
        }
    }

    ColorPreference {
        title: qsTr("Foreground (desktop name and notes)")
        isBackground: false
        overrideValue: settings.selectedForegroundOverride
        fallbackColor: settings.selectedPreset.foreground
        onColorChosen: settings.setColor("foreground", value)
    }

    ColorPreference {
        title: qsTr("Background")
        isBackground: true
        overrideValue: settings.selectedBackgroundOverride
        fallbackColor: settings.selectedPreset.background
        onColorChosen: settings.setColor("background", value)
    }

    Controls.CheckBox {
        id: advancedTextColors
        text: qsTr("Advanced: customize name and note text separately")
        checked: false
    }

    ColumnLayout {
        visible: advancedTextColors.checked
        Layout.fillWidth: true
        ColorPreference {
            title: qsTr("Desktop name text (optional override)")
            isBackground: false
            overrideValue: settings.selectedTitleOverride
            fallbackColor: settings.selectedForegroundColor
            onColorChosen: settings.setColor("title", value)
        }
        ColorPreference {
            title: qsTr("Note text (optional override)")
            isBackground: false
            overrideValue: settings.selectedNoteOverride
            fallbackColor: settings.selectedForegroundColor
            onColorChosen: settings.setColor("note", value)
        }
    }

    Controls.Label {
        text: qsTr("Material 3 color pair presets")
        font.bold: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: DesktopPalette.presets.length
            delegate: Controls.Button {
                Layout.fillWidth: true
                Layout.minimumWidth: 86
                Layout.preferredHeight: 38
                background: Rectangle {
                    radius: 5
                    color: DesktopPalette.forIndex(index).background
                    border.width: 1
                    border.color: "#808080"
                }
                contentItem: Controls.Label {
                    text: String(index + 1) + " · " + DesktopPalette.forIndex(index).name
                    color: DesktopPalette.forIndex(index).foreground
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: settings.applyPreset(index)
            }
        }
    }

    Controls.Button {
        text: qsTr("Restore this desktop's automatic colors")
        onClicked: settings.resetSelectedColors()
    }

    Controls.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("Click Apply to save color choices across restarts. Restoring removes this desktop's overrides and returns to its assigned preset. Notes remain session-only and are cleared on Plasma restart.")
    }
}
