import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore

// Per-desktop work icon chooser. The chosen symbol is only an appearance
// preference; the actual KWin desktop name is never changed by this dialog.
Controls.Dialog {
    id: dialog
    modal: true
    focus: true
    padding: 12
    closePolicy: Controls.Popup.CloseOnEscape

    signal iconAccepted(string kind, string value)

    property string draftKind: ""
    property string draftValue: ""
    readonly property var emojiChoices: [
        {value: "💼", label: qsTr("Work")},
        {value: "📁", label: qsTr("Projects")},
        {value: "✅", label: qsTr("To-do")},
        {value: "📝", label: qsTr("Notes")},
        {value: "💻", label: qsTr("Development")},
        {value: "👨‍💻", label: qsTr("Programming")},
        {value: "🖥️", label: qsTr("Computer")},
        {value: "🐛", label: qsTr("Debugging")},
        {value: "🧪", label: qsTr("Testing")},
        {value: "🚀", label: qsTr("Deployment")},
        {value: "⚙️", label: qsTr("Settings")},
        {value: "📅", label: qsTr("Meetings")},
        {value: "🗓️", label: qsTr("Schedule")},
        {value: "💬", label: qsTr("Chat")},
        {value: "📧", label: qsTr("Email")},
        {value: "📞", label: qsTr("Calls")},
        {value: "🔬", label: qsTr("Research")},
        {value: "📚", label: qsTr("Reading")},
        {value: "✍️", label: qsTr("Writing")},
        {value: "📄", label: qsTr("Documents")},
        {value: "🎓", label: qsTr("Learning")},
        {value: "🎨", label: qsTr("Design")},
        {value: "📊", label: qsTr("Presentations")},
        {value: "🗄️", label: qsTr("Database")},
        {value: "☁️", label: qsTr("Cloud")},
        {value: "🔒", label: qsTr("Security")},
        {value: "⏰", label: qsTr("Time")},
        {value: "🌐", label: qsTr("Web")},
        {value: "🛒", label: qsTr("Shopping")},
        {value: "💰", label: qsTr("Finance")},
        {value: "👥", label: qsTr("Team")},
        {value: "🎵", label: qsTr("Music")},
        {value: "🎬", label: qsTr("Video")},
        {value: "☕", label: qsTr("Break")},
        {value: "🏠", label: qsTr("Home")},
        {value: "❤️", label: qsTr("Health")}
    ]
    readonly property var kdeIconChoices: [
        {value: "folder", label: qsTr("Folder")},
        {value: "document-edit", label: qsTr("Edit document")},
        {value: "view-calendar", label: qsTr("Calendar")},
        {value: "mail-message-new", label: qsTr("Mail")},
        {value: "dialog-messages", label: qsTr("Messages")},
        {value: "utilities-terminal", label: qsTr("Terminal")},
        {value: "applications-development", label: qsTr("Development tools")},
        {value: "applications-graphics", label: qsTr("Graphics")},
        {value: "applications-education", label: qsTr("Education")},
        {value: "view-list-text", label: qsTr("Task list")},
        {value: "preferences-system", label: qsTr("System")},
        {value: "system-search", label: qsTr("Search")},
        {value: "internet-web-browser", label: qsTr("Browser")},
        {value: "emblem-ok", label: qsTr("Completed")},
        {value: "user-home", label: qsTr("Home folder")},
        {value: "preferences-desktop", label: qsTr("Desktop")}
    ]

    function openIcons(kind, value) {
        draftKind = kind === "emoji" || kind === "icon" ? kind : ""
        draftValue = draftKind ? String(value || "") : ""
        searchField.text = ""
        open()
    }

    function matches(label, value) {
        var query = searchField.text.trim().toLocaleLowerCase()
        return !query || String(label).toLocaleLowerCase().indexOf(query) !== -1
                || String(value).toLocaleLowerCase().indexOf(query) !== -1
    }

    function selectIcon(kind, value) {
        draftKind = kind
        draftValue = value
    }

    background: Rectangle {
        radius: 8
        color: PlasmaCore.Theme.backgroundColor
        border.width: 1
        border.color: PlasmaCore.Theme.highlightColor
    }

    contentItem: ColumnLayout {
        spacing: 9

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: qsTr("Choose an icon or emoji")
            font.bold: true
            color: PlasmaCore.Theme.textColor
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Pick a symbol for this virtual desktop, or show its name as text.")
            color: PlasmaCore.Theme.textColor
        }

        PlasmaComponents3.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Search icons and activities")
            selectByMouse: true
        }

        PlasmaComponents3.Button {
            Layout.fillWidth: true
            text: qsTr("No icon — show desktop name")
            background: Rectangle {
                radius: 6
                color: PlasmaCore.Theme.backgroundColor
                border.width: !dialog.draftKind ? 3 : 1
                border.color: !dialog.draftKind
                              ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.textColor
            }
            onClicked: dialog.selectIcon("", "")
        }

        Controls.ScrollView {
            id: iconScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Column {
                width: iconScroll.availableWidth - 4
                spacing: 8

                PlasmaComponents3.Label {
                    text: qsTr("Emoji")
                    font.bold: true
                    color: PlasmaCore.Theme.textColor
                }

                Flow {
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: dialog.emojiChoices
                        delegate: PlasmaComponents3.Button {
                            id: emojiButton
                            readonly property var option: modelData
                            width: 46
                            height: 44
                            padding: 3
                            visible: dialog.matches(option.label, option.value)
                            text: option.label
                            contentItem: Text {
                                text: emojiButton.option.value
                                textFormat: Text.PlainText
                                font.pixelSize: 25
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: PlasmaCore.Theme.backgroundColor
                                border.width: dialog.draftKind === "emoji"
                                    && dialog.draftValue === emojiButton.option.value ? 3 : 1
                                border.color: dialog.draftKind === "emoji"
                                    && dialog.draftValue === emojiButton.option.value
                                    ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.textColor
                            }
                            Controls.ToolTip.visible: hovered
                            Controls.ToolTip.text: option.label
                            onClicked: dialog.selectIcon("emoji", option.value)
                        }
                    }
                }

                PlasmaComponents3.Label {
                    text: qsTr("KDE icons")
                    font.bold: true
                    color: PlasmaCore.Theme.textColor
                }

                Flow {
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: dialog.kdeIconChoices
                        delegate: PlasmaComponents3.Button {
                            id: kdeButton
                            readonly property var option: modelData
                            width: 46
                            height: 44
                            padding: 3
                            visible: dialog.matches(option.label, option.value)
                            text: option.label
                            contentItem: Item {
                                PlasmaCore.IconItem {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 26
                                    source: kdeButton.option.value
                                }
                            }
                            background: Rectangle {
                                radius: 6
                                color: PlasmaCore.Theme.backgroundColor
                                border.width: dialog.draftKind === "icon"
                                    && dialog.draftValue === kdeButton.option.value ? 3 : 1
                                border.color: dialog.draftKind === "icon"
                                    && dialog.draftValue === kdeButton.option.value
                                    ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.textColor
                            }
                            Controls.ToolTip.visible: hovered
                            Controls.ToolTip.text: option.label
                            onClicked: dialog.selectIcon("icon", option.value)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Button {
                text: qsTr("Cancel")
                onClicked: dialog.close()
            }
            PlasmaComponents3.Button {
                text: qsTr("Apply")
                onClicked: {
                    dialog.iconAccepted(dialog.draftKind, dialog.draftValue)
                    dialog.close()
                }
            }
        }
    }
}
