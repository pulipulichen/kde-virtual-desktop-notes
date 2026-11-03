import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.taskmanager 0.1 as TaskManager

ColumnLayout {
    id: settings

    property alias cfg_noteWidth: widthSpin.value
    property alias cfg_showDesktopName: showName.checked
    property alias cfg_desktopNameOnly: nameOnly.checked
    // Only colors and UI preferences persist; notes remain session-only.
    property string cfg_desktopColors: "{}"

    property string selectedDesktopKey: ""
    property string selectedTitleColor: ""
    property string selectedNoteColor: ""
    property string selectedBackgroundColor: ""

    readonly property var desktopChoices: {
        var choices = []
        var ids = desktopInfo.desktopIds || []
        var names = desktopInfo.desktopNames || []
        for (var i = 0; i < ids.length; i++) {
            var name = names.length > i ? String(names[i]).trim() : ""
            choices.push({
                key: String(ids[i]),
                label: name.length ? name : qsTr("Desktop %1").arg(i + 1)
            })
        }
        if (choices.length === 0) {
            var id = desktopInfo.currentDesktop
            choices.push({
                key: id === undefined || id === null || String(id) === ""
                     ? "__unknown__" : String(id),
                label: qsTr("Current desktop")
            })
        }
        return choices
    }

    spacing: 12

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
        selectedTitleColor = typeof entry.title === "string" ? entry.title : ""
        selectedNoteColor = typeof entry.note === "string" ? entry.note : ""
        selectedBackgroundColor = typeof entry.background === "string" ? entry.background : ""
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
        if (value !== "" && !/^#[0-9a-fA-F]{6}$/.test(value))
            return

        var map = readColorMap()
        var entry = map[selectedDesktopKey] || {}
        if (value === "") {
            delete entry[role]
        } else {
            entry[role] = value.toUpperCase()
        }
        if (Object.keys(entry).length === 0) {
            delete map[selectedDesktopKey]
        } else {
            map[selectedDesktopKey] = entry
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
        checked: false
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
        text: qsTr("Each desktop has independent colors. Click Apply to save them across restarts.")
    }

    ColorPreference {
        title: qsTr("Desktop name text")
        colorValue: settings.selectedTitleColor
        onColorChosen: settings.setColor("title", value)
    }

    ColorPreference {
        title: qsTr("Note text")
        colorValue: settings.selectedNoteColor
        onColorChosen: settings.setColor("note", value)
    }

    ColorPreference {
        title: qsTr("Background (default is transparent)")
        colorValue: settings.selectedBackgroundColor
        onColorChosen: settings.setColor("background", value)
    }

    Controls.Button {
        text: qsTr("Reset colors for this desktop")
        onClicked: settings.resetSelectedColors()
    }

    Controls.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("In name-only mode, notes are hidden but not deleted. In normal mode, notes accept one or two lines and automatically fit the available space. Notes are erased when Plasma restarts; color preferences are not.")
    }
}
