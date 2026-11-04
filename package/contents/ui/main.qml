import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.taskmanager 0.1 as TaskManager
import "DesktopPalette.js" as DesktopPalette

Item {
    id: root

    // Notes are session-only. Only UI preferences go into KConfig.
    property var notesByDesktop: ({})
    property string currentNote: ""
    property bool editing: false
    property bool restoring: false
    property bool renamingDesktop: false
    property bool renamePending: false
    property string renameError: ""
    property string pendingRenameCommand: ""
    property string pendingRenameKey: ""
    // Stage edits until the KWin rename succeeds; Cancel/failure must not save notes.
    property bool pendingNoteSave: false
    property string pendingNoteDraft: ""

    // Color overrides persist by desktop ID; default pairs follow desktop order.
    readonly property var desktopColors: {
        try {
            var parsed = JSON.parse(plasmoid.configuration.desktopColors || "{}")
            return parsed && typeof parsed === "object" && !Array.isArray(parsed)
                    ? parsed : {}
        } catch (error) {
            return {}
        }
    }
    readonly property var currentDesktopColors: desktopColors[desktopKey] || ({})

    // Icons are persistent appearance choices keyed to the same stable KWin IDs.
    // With no icon selected, the panel continues showing the desktop name.
    readonly property var desktopIcons: {
        try {
            var parsed = JSON.parse(plasmoid.configuration.desktopIcons || "{}")
            return parsed && typeof parsed === "object" && !Array.isArray(parsed)
                    ? parsed : {}
        } catch (error) {
            return {}
        }
    }
    readonly property var currentDesktopIcon: {
        var entry = desktopIcons[desktopKey] || {}
        var kind = entry.kind === "emoji" || entry.kind === "icon" ? entry.kind : ""
        var value = typeof entry.value === "string" ? entry.value : ""
        return kind && value ? {kind: kind, value: value} : {kind: "", value: ""}
    }
    readonly property int desktopIndex: {
        var ids = desktopInfo.desktopIds || []
        for (var i = 0; i < ids.length; i++) {
            if (String(ids[i]) === desktopKey)
                return i
        }
        return 0
    }
    readonly property var defaultColors: DesktopPalette.forIndex(desktopIndex)
    // KWin's standard 1-based name; keep the requested Desktop N format.
    readonly property string defaultDesktopName: "Desktop " + String(desktopIndex + 1)
    readonly property color titleTextColor: DesktopPalette.roleColor(currentDesktopColors, "title", defaultColors)
    readonly property color noteTextColor: DesktopPalette.roleColor(currentDesktopColors, "note", defaultColors)
    readonly property color backgroundColor: DesktopPalette.roleColor(currentDesktopColors, "background", defaultColors)

    // Plasma 5 provides an executable data engine, avoiding a compiled plugin.
    // Commands always go to our fixed helper with shell-quoted arguments.
    PlasmaCore.DataSource {
        id: helperSource
        engine: "executable"
        connectedSources: []
        onNewData: {
            if (sourceName === root.pendingRenameCommand) {
                var succeeded = Number(data["exit code"]) === 0
                var targetUnchanged = root.desktopKey === root.pendingRenameKey
                var shouldSaveNote = root.pendingNoteSave
                var noteDraft = root.pendingNoteDraft
                root.pendingNoteSave = false
                root.pendingNoteDraft = ""
                root.renamePending = false
                root.pendingRenameCommand = ""
                root.pendingRenameKey = ""
                if (targetUnchanged) {
                    if (succeeded) {
                        if (shouldSaveNote)
                            root.saveNote(noteDraft)
                        root.finishEditing()
                    } else {
                        var details = String(data["stderr"] || "").trim()
                        root.renameError = details.length ? details
                                : qsTr("Unable to rename this virtual desktop.")
                    }
                }
            }
            disconnectSource(sourceName)
        }
    }

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    readonly property string desktopKey: {
        var id = desktopInfo.currentDesktop
        return (id === undefined || id === null || String(id) === "")
                ? "__unknown__" : String(id)
    }

    // The ID/name arrays are parallel, and react to renames as well as switches.
    readonly property string desktopName: {
        var ids = desktopInfo.desktopIds
        var names = desktopInfo.desktopNames
        var current = desktopInfo.currentDesktop

        for (var i = 0; i < ids.length; i++) {
            if (String(ids[i]) === String(current)) {
                var label = names.length > i ? String(names[i]).trim() : ""
                return label.length ? label : qsTr("Desktop %1").arg(i + 1)
            }
        }
        return qsTr("Desktop")
    }

    function normalizeNote(value) {
        // A single editable field: one or two explicit lines, no third line.
        return String(value).replace(/\r\n?/g, "\n").split("\n").slice(0, 2).join("\n")
    }

    function loadNote() {
        restoring = true
        editing = false
        currentNote = Object.prototype.hasOwnProperty.call(notesByDesktop, desktopKey)
                ? notesByDesktop[desktopKey] : ""
        restoring = false
    }

    function saveNote(text) {
        if (restoring) {
            return
        }
        var normalized = normalizeNote(text)
        if (normalized !== currentNote) {
            notesByDesktop[desktopKey] = normalized
            currentNote = normalized
        }
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function helperCommand(action, args) {
        var fileUrl = String(Qt.resolvedUrl("../scripts/desktop-control.sh"))
        if (fileUrl.indexOf("file://") !== 0)
            return ""
        var command = "bash " + shellQuote(decodeURIComponent(fileUrl.substring(7)))
                + " " + shellQuote(action)
        for (var i = 0; i < args.length; i++)
            command += " " + shellQuote(args[i])
        return command
    }

    // Always edit in Plasma's own anchored popup window instead of the
    // narrow panel QQuickItem. The IME receives usable caret screen coordinates.
    function startRenamingDesktop() {
        if (desktopKey === "__unknown__" || renamePending)
            return
        editing = false
        renameError = ""
        renamingDesktop = true
        plasmoid.expanded = true
    }

    function startEditingNote() {
        if (renamePending)
            return
        renamingDesktop = false
        editing = true
        plasmoid.expanded = true
    }

    function finishEditing() {
        if (renamePending)
            return
        renamingDesktop = false
        editing = false
        renameError = ""
        plasmoid.expanded = false
    }

    function submitDesktopRename(rawName, forceUpdate, noteDraft) {
        if ((!renamingDesktop && !editing) || renamePending)
            return
        var name = String(rawName).replace(/[\r\n]+/g, " ").trim()
        var useDefault = !name
        if (useDefault)
            name = defaultDesktopName
        // The UI can already *display* Desktop N as a fallback for a blank
        // KWin name. Persist the actual name when blank or resetting.
        if (name === desktopName && !useDefault && !forceUpdate) {
            if (noteDraft !== undefined)
                saveNote(noteDraft)
            finishEditing()
            return
        }
        var command = helperCommand("rename", [desktopKey, String(desktopIndex + 1), name])
        if (!command) {
            renameError = qsTr("Cannot locate the KDE virtual desktop helper.")
            return
        }
        pendingRenameKey = desktopKey
        pendingRenameCommand = command
        pendingNoteSave = noteDraft !== undefined
        pendingNoteDraft = pendingNoteSave ? normalizeNote(noteDraft) : ""
        renamePending = true
        renameError = ""
        helperSource.connectSource(command)
    }

    function resetDesktopName() {
        submitDesktopRename(defaultDesktopName, true)
    }

    // The quick palette uses the same persistent per-ID KConfig map as Appearance.
    // Replacing a pair clears any old per-title/note overrides so the sample
    // foreground matches both text roles. It does not edit the desktop name.
    function saveCurrentDesktopColorPair(pair) {
        if (desktopKey === "__unknown__" || renamePending)
            return
        var map = {}
        var keys = Object.keys(desktopColors)
        for (var i = 0; i < keys.length; i++)
            map[keys[i]] = desktopColors[keys[i]]
        if (pair) {
            map[desktopKey] = {
                foreground: pair.foreground,
                background: pair.background
            }
        } else {
            delete map[desktopKey]
        }
        plasmoid.configuration.desktopColors = JSON.stringify(map)
    }

    function restoreAutomaticColors() {
        saveCurrentDesktopColorPair(null)
    }

    function saveCurrentDesktopIcon(kind, value) {
        if (desktopKey === "__unknown__" || renamePending)
            return
        var map = {}
        var keys = Object.keys(desktopIcons)
        for (var i = 0; i < keys.length; i++)
            map[keys[i]] = desktopIcons[keys[i]]
        if ((kind === "emoji" || kind === "icon") && String(value).length)
            map[desktopKey] = {kind: kind, value: String(value)}
        else
            delete map[desktopKey]
        plasmoid.configuration.desktopIcons = JSON.stringify(map)
    }

    // Plasma 5's native right-click menu appends these actions to Configure.
    function action_renameDesktop() {
        startRenamingDesktop()
    }

    function action_openDesktopSettings() {
        var command = helperCommand("settings", [])
        if (command)
            helperSource.connectSource(command)
    }

    onDesktopKeyChanged: {
        renamingDesktop = false
        editing = false
        renameError = ""
        plasmoid.expanded = false
        loadNote()
    }

    Connections {
        target: plasmoid
        function onExpandedChanged() {
            if (!plasmoid.expanded && !root.renamePending) {
                root.renamingDesktop = false
                root.editing = false
                root.renameError = ""
            }
        }
    }

    Component.onCompleted: {
        loadNote()
        Plasmoid.setAction("renameDesktop", qsTr("Rename current virtual desktop"), "edit-rename")
        Plasmoid.setAction("openDesktopSettings", qsTr("Open virtual desktop settings"), "preferences-desktop-virtual")
    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: FocusScope {
        id: compact

        Layout.minimumWidth: 80
        Layout.preferredWidth: Math.max(80, Math.min(900, plasmoid.configuration.noteWidth))
        Layout.maximumWidth: 900
        Layout.fillHeight: true

        readonly property bool nameOnly: plasmoid.configuration.desktopNameOnly
        readonly property bool showDesktopTitle: nameOnly || plasmoid.configuration.showDesktopName

        onNameOnlyChanged: {
            if (nameOnly) {
                root.editing = false
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: root.backgroundColor
        }

        Text {
            id: desktopTitle
            visible: compact.showDesktopTitle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            height: visible ? (compact.nameOnly ? compact.height : Math.min(18, Math.max(11, compact.height * 0.32))) : 0

            text: root.currentDesktopIcon.kind === "icon" ? ""
                  : root.currentDesktopIcon.kind === "emoji"
                    ? root.currentDesktopIcon.value : root.desktopName
            textFormat: Text.PlainText
            color: root.titleTextColor
            opacity: 1
            font.bold: true
            font.pixelSize: root.currentDesktopIcon.kind === "emoji"
                            ? (compact.nameOnly ? 34 : 22)
                            : (compact.nameOnly ? 24 : 14)
            minimumPixelSize: 8
            fontSizeMode: Text.Fit
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        PlasmaCore.IconItem {
            visible: compact.showDesktopTitle && root.currentDesktopIcon.kind === "icon"
            anchors.centerIn: desktopTitle
            width: Math.min(compact.width - 6, compact.nameOnly ? compact.height - 6 : desktopTitle.height - 2)
            height: width
            source: root.currentDesktopIcon.kind === "icon" ? root.currentDesktopIcon.value : ""
        }

        // Click the title to open a properly anchored KDE editor.
        MouseArea {
            anchors.fill: desktopTitle
            visible: desktopTitle.visible
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            onClicked: root.startRenamingDesktop()
        }

        FocusScope {
            id: noteArea
            visible: !compact.nameOnly
            anchors.top: desktopTitle.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Text {
                id: fittedNote
                anchors.fill: parent
                anchors.margins: 2

                text: root.currentNote.length ? root.currentNote : qsTr("Click to add a note")
                textFormat: Text.PlainText
                color: root.noteTextColor
                opacity: 1
                font.italic: root.currentNote.length === 0

                font.pixelSize: 24
                minimumPixelSize: 8
                fontSizeMode: Text.Fit
                wrapMode: Text.NoWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.IBeamCursor
                onClicked: root.startEditingNote()
            }
        }
    }

    // KDE renders fullRepresentation in a real popup window anchored to
    // compactRepresentation. Both the keyboard focus and IME caret are
    // therefore associated with the popup instead of a panel sub-item.
    Plasmoid.fullRepresentation: FocusScope {
        id: editPopup
        Layout.minimumWidth: colorDialog.opened || iconDialog.opened ? 430 : 300
        Layout.preferredWidth: colorDialog.opened || iconDialog.opened ? 440 : 340
        Layout.maximumWidth: 500
        // Keep each modal inside Plasma's anchored popup, with room for grids.
        Layout.minimumHeight: colorDialog.opened || iconDialog.opened
                              ? 520 : (plasmoid.configuration.desktopNameOnly ? 135 : 235)
        Layout.preferredHeight: colorDialog.opened || iconDialog.opened
                                ? 540 : (plasmoid.configuration.desktopNameOnly ? 150 : 255)

        function focusEditor() {
            if (!visible || !plasmoid.expanded)
                return
            if (!root.renamingDesktop && !root.editing)
                return
            // Both fields share one popup and one commit, regardless of entry point.
            desktopNameEditor.text = root.desktopName
            noteEditor.text = root.currentNote
            if (root.editing && !plasmoid.configuration.desktopNameOnly) {
                noteEditor.forceActiveFocus()
                noteEditor.cursorPosition = noteEditor.length
            } else {
                desktopNameEditor.forceActiveFocus()
                desktopNameEditor.selectAll()
            }
        }

        Component.onCompleted: Qt.callLater(focusEditor)
        onVisibleChanged: {
            if (visible)
                Qt.callLater(focusEditor)
        }

        Connections {
            target: root
            function onRenamingDesktopChanged() {
                if (root.renamingDesktop)
                    Qt.callLater(editPopup.focusEditor)
            }
            function onEditingChanged() {
                if (root.editing)
                    Qt.callLater(editPopup.focusEditor)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: qsTr("Rename virtual desktop")
                font.bold: true
                // Follow the active Plasma popup palette in light and dark modes.
                color: PlasmaCore.Theme.textColor
            }

            RowLayout {
                visible: root.renamingDesktop || root.editing
                Layout.fillWidth: true
                spacing: 6

                PlasmaComponents3.Button {
                    id: iconPickerButton
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: desktopNameEditor.implicitHeight
                    enabled: !root.renamePending && root.desktopKey !== "__unknown__"
                    padding: 3
                    text: qsTr("Choose icon or emoji")
                    contentItem: Item {
                        Text {
                            visible: root.currentDesktopIcon.kind !== "icon"
                            anchors.centerIn: parent
                            text: root.currentDesktopIcon.kind === "emoji"
                                  ? root.currentDesktopIcon.value : "☺"
                            textFormat: Text.PlainText
                            font.pixelSize: 23
                            color: PlasmaCore.Theme.textColor
                        }
                        PlasmaCore.IconItem {
                            visible: root.currentDesktopIcon.kind === "icon"
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: root.currentDesktopIcon.kind === "icon"
                                    ? root.currentDesktopIcon.value : ""
                        }
                    }
                    onClicked: iconDialog.openIcons(root.currentDesktopIcon.kind,
                                                   root.currentDesktopIcon.value)
                }

                PlasmaComponents3.TextField {
                    id: desktopNameEditor
                    Layout.fillWidth: true
                    enabled: !root.renamePending
                    maximumLength: 128
                    selectByMouse: true
                    font.pixelSize: 17
                    text: root.desktopName
                    placeholderText: root.defaultDesktopName
                    onAccepted: root.submitDesktopRename(
                                    text, false,
                                    plasmoid.configuration.desktopNameOnly ? undefined : noteEditor.text)
                    Keys.onEscapePressed: root.finishEditing()
                }

                PlasmaComponents3.Button {
                    id: colorPickerButton
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: desktopNameEditor.implicitHeight
                    enabled: !root.renamePending && root.desktopKey !== "__unknown__"
                    padding: 3
                    text: qsTr("Choose colors")
                    // The button is a live sample of the currently saved pair.
                    contentItem: Rectangle {
                        radius: 4
                        color: root.backgroundColor
                        border.width: 1
                        border.color: "#808080"
                        implicitWidth: 48
                        implicitHeight: 29

                        Text {
                            anchors.centerIn: parent
                            text: "Aa"
                            textFormat: Text.PlainText
                            color: root.titleTextColor
                            font.bold: true
                            font.pixelSize: 17
                        }
                    }
                    onClicked: colorDialog.openColors(
                                   DesktopPalette.roleColor(root.currentDesktopColors, "title", root.defaultColors),
                                   DesktopPalette.roleColor(root.currentDesktopColors, "background", root.defaultColors))
                }
            }

            PlasmaComponents3.Label {
                visible: !plasmoid.configuration.desktopNameOnly
                Layout.fillWidth: true
                text: qsTr("Edit temporary desktop note")
                color: PlasmaCore.Theme.textColor
            }

            PlasmaComponents3.TextArea {
                id: noteEditor
                visible: !plasmoid.configuration.desktopNameOnly
                enabled: !root.renamePending
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                selectByMouse: true
                font.pixelSize: 17
                wrapMode: TextEdit.NoWrap
                text: root.currentNote

                // The draft is committed only with the name, never by IME preedit.
                onTextChanged: {
                    if (inputMethodComposing)
                        return
                    var normalized = root.normalizeNote(text)
                    if (normalized !== text) {
                        var pos = cursorPosition
                        text = normalized
                        cursorPosition = Math.min(pos, text.length)
                    }
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape) {
                        root.finishEditing()
                        event.accepted = true
                    } else if (!inputMethodComposing
                            && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                            && text.indexOf("\n") !== -1) {
                        event.accepted = true
                    }
                }
            }

            PlasmaComponents3.Label {
                visible: root.renameError.length > 0 && (root.renamingDesktop || root.editing)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: PlasmaCore.Theme.negativeTextColor
                text: root.renameError
            }

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents3.Button {
                    visible: root.renamingDesktop || root.editing
                    text: qsTr("Reset")
                    enabled: !root.renamePending
                    onClicked: root.resetDesktopName()
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents3.Button {
                    text: qsTr("Cancel")
                    enabled: !root.renamePending
                    onClicked: root.finishEditing()
                }
                PlasmaComponents3.Button {
                    text: plasmoid.configuration.desktopNameOnly ? qsTr("Rename") : qsTr("Done")
                    enabled: !root.renamePending
                    onClicked: root.submitDesktopRename(
                                   desktopNameEditor.text, false,
                                   plasmoid.configuration.desktopNameOnly ? undefined : noteEditor.text)
                }
            }
        }

        ColorPairDialog {
            id: colorDialog
            parent: editPopup
            width: Math.max(320, editPopup.width - 16)
            height: Math.max(460, editPopup.height - 16)
            x: (editPopup.width - width) / 2
            y: (editPopup.height - height) / 2
            onColorsAccepted: root.saveCurrentDesktopColorPair({
                foreground: foregroundHex, background: backgroundHex
            })
            onAutomaticRequested: root.restoreAutomaticColors()
            onClosed: {
                if ((root.renamingDesktop || root.editing) && !root.renamePending)
                    desktopNameEditor.forceActiveFocus()
            }
        }

        DesktopIconDialog {
            id: iconDialog
            parent: editPopup
            width: Math.max(320, editPopup.width - 16)
            height: Math.max(460, editPopup.height - 16)
            x: (editPopup.width - width) / 2
            y: (editPopup.height - height) / 2
            onIconAccepted: root.saveCurrentDesktopIcon(kind, value)
            onClosed: {
                if (root.renamingDesktop && !root.renamePending)
                    desktopNameEditor.forceActiveFocus()
            }
        }

        Connections {
            target: root
            function onDesktopKeyChanged() {
                colorDialog.close()
                iconDialog.close()
            }
            function onRenamingDesktopChanged() {
                if (!root.renamingDesktop) {
                    colorDialog.close()
                    iconDialog.close()
                }
            }
        }
    }
}
