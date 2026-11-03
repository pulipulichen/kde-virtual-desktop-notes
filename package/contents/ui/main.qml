import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
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
                        root.renamingDesktop = false
                        root.renameError = ""
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

    function startRenamingDesktop() {
        if (desktopKey === "__unknown__" || renamePending)
            return
        editing = false
        renameError = ""
        renamingDesktop = true
    }

    function submitDesktopRename(rawName) {
        if (!renamingDesktop || renamePending)
            return
        var name = String(rawName).replace(/[\r\n]+/g, " ").trim()
        if (!name) {
            renameError = qsTr("Desktop name cannot be empty.")
            return
        }
        if (name === desktopName) {
            renamingDesktop = false
            renameError = ""
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
        renameError = ""
        loadNote()
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
            visible: compact.showDesktopTitle || root.renamingDesktop
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            height: visible ? (compact.nameOnly ? compact.height : Math.min(18, Math.max(11, compact.height * 0.32))) : 0

            text: root.desktopName
            textFormat: Text.PlainText
            color: root.titleTextColor
            opacity: compact.nameOnly ? 1 : 0.72
            font.bold: true
            font.pixelSize: compact.nameOnly ? 24 : 14
            minimumPixelSize: 8
            fontSizeMode: Text.Fit
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Editing the desktop title changes KWin's real, persistent desktop
        // name. The note editor below remains temporary and independent.
        MouseArea {
            anchors.fill: desktopTitle
            visible: desktopTitle.visible && !root.renamingDesktop
            enabled: visible
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            onClicked: root.startRenamingDesktop()
        }

        Controls.TextField {
            id: desktopNameEditor
            anchors.fill: desktopTitle
            anchors.margins: 1
            visible: root.renamingDesktop
            enabled: !root.renamePending
            maximumLength: 128
            selectByMouse: true
            text: root.desktopName
            color: root.titleTextColor
            font.pixelSize: Math.max(10, Number(desktopTitle.fontInfo.pixelSize) || 12)
            horizontalAlignment: TextInput.AlignHCenter
            background: Rectangle {
                color: root.backgroundColor
                radius: 3
                border.width: 1
                border.color: PlasmaCore.Theme.highlightColor
            }
            onVisibleChanged: {
                if (visible) {
                    text = root.desktopName
                    Qt.callLater(function() {
                        if (desktopNameEditor.visible) {
                            desktopNameEditor.forceActiveFocus()
                            desktopNameEditor.selectAll()
                        }
                    })
                }
            }
            onAccepted: root.submitDesktopRename(text)
            Keys.onEscapePressed: {
                if (!root.renamePending) {
                    root.renamingDesktop = false
                    root.renameError = ""
                }
            }
            Controls.ToolTip.visible: root.renameError.length > 0
            Controls.ToolTip.text: root.renameError
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
                opacity: root.editing ? 0 : (root.currentNote.length ? 1 : 0.55)

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
                enabled: !root.editing
                cursorShape: Qt.IBeamCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    root.editing = true
                    noteEditor.forceActiveFocus()
                }
            }

            Controls.TextArea {
                id: noteEditor
                anchors.fill: parent
                anchors.margins: 2
                visible: root.editing
                clip: true
                text: root.currentNote

                color: root.noteTextColor
                selectedTextColor: PlasmaCore.Theme.highlightedTextColor
                selectionColor: PlasmaCore.Theme.highlightColor
                font.pixelSize: Math.max(8, Number(fittedNote.fontInfo.pixelSize) || 12)

                wrapMode: TextEdit.NoWrap
                horizontalAlignment: TextEdit.AlignHCenter
                verticalAlignment: TextEdit.AlignVCenter
                selectByMouse: true
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                background: Rectangle {
                    color: "transparent"
                    radius: 3
                    border.width: 1
                    border.color: PlasmaCore.Theme.highlightColor
                }

                onTextChanged: {
                    if (root.restoring) {
                        return
                    }

                    var normalized = root.normalizeNote(text)
                    if (normalized !== text) {
                        var oldPos = cursorPosition
                        text = normalized
                        cursorPosition = Math.min(oldPos, text.length)
                        return
                    }
                    root.saveNote(text)
                }

                Keys.onPressed: {
                    if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                            && noteEditor.text.indexOf("\n") !== -1) {
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.editing = false
                        event.accepted = true
                    }
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        root.editing = false
                    }
                }
            }

            Connections {
                target: root
                function onCurrentNoteChanged() {
                    // Keep the editor in sync after a virtual-desktop switch.
                    if (noteEditor.text !== root.currentNote) {
                        root.restoring = true
                        noteEditor.text = root.currentNote
                        root.restoring = false
                    }
                }
            }
        }
    }
}
