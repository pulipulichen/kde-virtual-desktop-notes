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
                root.renamePending = false
                root.pendingRenameCommand = ""
                root.pendingRenameKey = ""
                if (targetUnchanged) {
                    if (succeeded) {
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

    function submitDesktopRename(rawName, forceUpdate) {
        if (!renamingDesktop || renamePending)
            return
        var name = String(rawName).replace(/[\r\n]+/g, " ").trim()
        var useDefault = !name
        if (useDefault)
            name = defaultDesktopName
        // The UI can already *display* Desktop N as a fallback for a blank
        // KWin name. Persist the actual name when blank or resetting.
        if (name === desktopName && !useDefault && !forceUpdate) {
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
        renamePending = true
        renameError = ""
        helperSource.connectSource(command)
    }

    function resetDesktopName() {
        submitDesktopRename(defaultDesktopName, true)
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

            text: root.desktopName
            textFormat: Text.PlainText
            color: root.titleTextColor
            opacity: 1
            font.bold: true
            font.pixelSize: compact.nameOnly ? 24 : 14
            minimumPixelSize: 8
            fontSizeMode: Text.Fit
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
        Layout.minimumWidth: 300
        Layout.preferredWidth: 340
        Layout.maximumWidth: 500
        Layout.minimumHeight: root.editing ? 172 : 130
        Layout.preferredHeight: root.editing ? 190 : 145

        function focusEditor() {
            if (!visible || !plasmoid.expanded)
                return
            if (root.renamingDesktop) {
                desktopNameEditor.text = root.desktopName
                desktopNameEditor.forceActiveFocus()
                desktopNameEditor.selectAll()
            } else if (root.editing) {
                noteEditor.text = root.currentNote
                noteEditor.forceActiveFocus()
                noteEditor.cursorPosition = noteEditor.length
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
                text: root.renamingDesktop ? qsTr("Rename virtual desktop")
                                           : qsTr("Edit temporary desktop note")
                font.bold: true
                // Follow the active Plasma popup palette in light and dark modes.
                color: PlasmaCore.Theme.textColor
            }

            PlasmaComponents3.TextField {
                id: desktopNameEditor
                visible: root.renamingDesktop
                enabled: !root.renamePending
                Layout.fillWidth: true
                maximumLength: 128
                selectByMouse: true
                font.pixelSize: 17
                text: root.desktopName
                placeholderText: root.defaultDesktopName
                onAccepted: root.submitDesktopRename(text)
                Keys.onEscapePressed: root.finishEditing()
            }

            PlasmaComponents3.TextArea {
                id: noteEditor
                visible: root.editing
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                selectByMouse: true
                font.pixelSize: 17
                wrapMode: TextEdit.NoWrap
                text: root.currentNote

                // A draft is committed only by Done, never by IME preedit.
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
                visible: root.renameError.length > 0 && root.renamingDesktop
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: PlasmaCore.Theme.negativeTextColor
                text: root.renameError
            }

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents3.Button {
                    visible: root.renamingDesktop
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
                    text: root.renamingDesktop ? qsTr("Rename") : qsTr("Done")
                    enabled: !root.renamePending
                    onClicked: {
                        if (root.renamingDesktop)
                            root.submitDesktopRename(desktopNameEditor.text)
                        else {
                            root.saveNote(noteEditor.text)
                            root.finishEditing()
                        }
                    }
                }
            }
        }
    }
}
