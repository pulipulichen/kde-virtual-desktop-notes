import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import "DesktopPalette.js" as DesktopPalette

// Shared preset/custom-hex picker. Empty overrides use the desktop's palette,
// not a transparent background or Plasma theme-dependent text.
ColumnLayout {
    id: picker
    Layout.fillWidth: true
    spacing: 4

    property string title: ""
    property bool isBackground: false
    property string overrideValue: ""
    property string fallbackColor: "#D3E3FD"
    readonly property string effectiveColor: DesktopPalette.isHexColor(overrideValue)
            ? overrideValue : fallbackColor
    signal colorChosen(string value)

    readonly property var palette: {
        var choices = [{ text: qsTr("Use desktop preset"), value: "" }]
        for (var i = 0; i < DesktopPalette.presets.length; i++) {
            var pair = DesktopPalette.forIndex(i)
            choices.push({
                text: pair.name,
                value: isBackground ? pair.background : pair.foreground
            })
        }
        return choices
    }

    function syncControls() {
        var found = -1
        for (var i = 0; i < palette.length; i++) {
            if (palette[i].value.toUpperCase() === overrideValue.toUpperCase()) {
                found = i
                break
            }
        }
        presetSelect.currentIndex = found
        hexInput.text = effectiveColor
    }

    onOverrideValueChanged: syncControls()
    onFallbackColorChanged: syncControls()
    onIsBackgroundChanged: syncControls()
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
            Layout.preferredWidth: 176
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
                if (DesktopPalette.isHexColor(chosen))
                    picker.colorChosen(chosen.toUpperCase())
                else if (chosen === "")
                    picker.colorChosen("")
                else
                    text = picker.effectiveColor
                Qt.callLater(picker.syncControls)
            }
        }

        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 4
            color: picker.effectiveColor
            border.width: 1
            border.color: "#808080"
        }
    }
}
