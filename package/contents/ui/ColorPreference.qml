import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

// Plasma 5 color selector with presets and a custom hex color field.
ColumnLayout {
    id: picker

    property string title: ""
    property string colorValue: ""
    signal colorChosen(string value)

    readonly property var palette: [
        { text: qsTr("System default"), value: "" },
        { text: qsTr("White"), value: "#FFFFFF" },
        { text: qsTr("Black"), value: "#000000" },
        { text: qsTr("Gray"), value: "#808080" },
        { text: qsTr("Red"), value: "#EF5350" },
        { text: qsTr("Orange"), value: "#FF9800" },
        { text: qsTr("Yellow"), value: "#FFEB3B" },
        { text: qsTr("Green"), value: "#66BB6A" },
        { text: qsTr("Teal"), value: "#26A69A" },
        { text: qsTr("Cyan"), value: "#26C6DA" },
        { text: qsTr("Blue"), value: "#42A5F5" },
        { text: qsTr("Purple"), value: "#AB47BC" },
        { text: qsTr("Pink"), value: "#EC407A" }
    ]

    spacing: 4
    Layout.fillWidth: true

    function syncControls() {
        var index = 0
        for (var i = 0; i < palette.length; i++) {
            if (palette[i].value.toUpperCase() === colorValue.toUpperCase()) {
                index = i
                break
            }
        }
        presetSelect.currentIndex = index
        hexInput.text = colorValue
    }

    onColorValueChanged: syncControls()
    Component.onCompleted: syncControls()

    Controls.Label {
        text: picker.title
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Controls.ComboBox {
            id: presetSelect
            Layout.preferredWidth: 175
            model: picker.palette
            textRole: "text"
            onActivated: picker.colorChosen(picker.palette[index].value)
        }

        Controls.TextField {
            id: hexInput
            Layout.fillWidth: true
            placeholderText: qsTr("Custom #RRGGBB")
            inputMethodHints: Qt.ImhNoPredictiveText
            onEditingFinished: {
                var chosen = text.trim()
                if (chosen === "") {
                    picker.colorChosen("")
                } else if (/^#[0-9a-fA-F]{6}$/.test(chosen)) {
                    picker.colorChosen(chosen.toUpperCase())
                } else {
                    text = picker.colorValue
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 4
            color: picker.colorValue === "" ? "transparent" : picker.colorValue
            border.width: 1
            border.color: "#808080"

            Controls.Label {
                anchors.centerIn: parent
                visible: picker.colorValue === ""
                text: "–"
            }
        }
    }
}
