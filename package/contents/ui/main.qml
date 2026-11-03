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

    onDesktopKeyChanged: loadNote()
    Component.onCompleted: loadNote()

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
