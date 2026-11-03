import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import "DesktopPalette.js" as DesktopPalette

// A true modal dialog in Plasma's anchored editor window. Nothing persists
// until Apply (or explicit Restore). Escape/Cancel discard the color draft.
Controls.Dialog {
    id: dialog
    modal: true
    focus: true
    padding: 12
    closePolicy: Controls.Popup.CloseOnEscape

    signal colorsAccepted(string foregroundHex, string backgroundHex)
    signal automaticRequested()

    readonly property string draftForeground: foregroundField.text.trim().toUpperCase()
    readonly property string draftBackground: backgroundField.text.trim().toUpperCase()
    readonly property bool validHex: DesktopPalette.isHexColor(draftForeground)
                                     && DesktopPalette.isHexColor(draftBackground)
    readonly property real ratio: validHex
                                   ? DesktopPalette.contrastRatio(draftForeground, draftBackground) : 0
    readonly property bool canApply: validHex && ratio >= 4.5
    readonly property int chosenPreset: DesktopPalette.indexOfPair(draftForeground, draftBackground)

    property string originalForeground: "#0B2545"
    property string originalBackground: "#D3E3FD"

    function openColors(foreground, background) {
        originalForeground = DesktopPalette.isHexColor(foreground) ? foreground : "#0B2545"
        originalBackground = DesktopPalette.isHexColor(background) ? background : "#D3E3FD"
        foregroundField.text = originalForeground.toUpperCase()
        backgroundField.text = originalBackground.toUpperCase()
        open()
    }

    function choosePreset(index) {
        if (index < 0 || index >= DesktopPalette.presets.length)
            return
        var preset = DesktopPalette.forIndex(index)
        foregroundField.text = preset.foreground
        backgroundField.text = preset.background
    }

    background: Rectangle {
        radius: 8
        color: PlasmaCore.Theme.backgroundColor
        border.color: PlasmaCore.Theme.highlightColor
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 7

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: qsTr("Choose desktop colors")
            font.bold: true
            color: PlasmaCore.Theme.textColor
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: qsTr("Select a preset or enter custom foreground and background colors.")
            wrapMode: Text.WordWrap
            color: PlasmaCore.Theme.textColor
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 5
            columnSpacing: 5

            Repeater {
                model: DesktopPalette.presets.length
                delegate: PlasmaComponents3.Button {
                    id: presetButton
                    readonly property var preset: DesktopPalette.forIndex(index)
                    Layout.fillWidth: true
                    Layout.minimumWidth: 66
                    Layout.preferredHeight: 42
                    padding: 3
                    text: qsTr("Color combination %1: %2").arg(index + 1).arg(preset.name)
                    contentItem: Rectangle {
                        implicitWidth: 64
                        implicitHeight: 32
                        radius: 4
                        color: presetButton.preset.background
                        border.width: dialog.chosenPreset === index ? 3 : 1
                        border.color: dialog.chosenPreset === index
                                      ? PlasmaCore.Theme.highlightColor : "#808080"

                        Text {
                            anchors.centerIn: parent
                            text: "Aa " + String(index + 1)
                            textFormat: Text.PlainText
                            color: presetButton.preset.foreground
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }
                    onClicked: dialog.choosePreset(index)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                PlasmaComponents3.Label {
                    text: qsTr("Text color")
                    color: PlasmaCore.Theme.textColor
                }
                PlasmaComponents3.TextField {
                    id: foregroundField
                    Layout.fillWidth: true
                    maximumLength: 7
                    selectByMouse: true
                    placeholderText: "#RRGGBB"
                    inputMethodHints: Qt.ImhNoPredictiveText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                PlasmaComponents3.Label {
                    text: qsTr("Background color")
                    color: PlasmaCore.Theme.textColor
                }
                PlasmaComponents3.TextField {
                    id: backgroundField
                    Layout.fillWidth: true
                    maximumLength: 7
                    selectByMouse: true
                    placeholderText: "#RRGGBB"
                    inputMethodHints: Qt.ImhNoPredictiveText
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 5
            color: DesktopPalette.isHexColor(dialog.draftBackground)
                   ? dialog.draftBackground : dialog.originalBackground
            border.color: "#808080"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: qsTr("Desktop color preview")
                textFormat: Text.PlainText
                font.bold: true
                color: DesktopPalette.isHexColor(dialog.draftForeground)
                       ? dialog.draftForeground : dialog.originalForeground
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: !dialog.validHex
                  ? qsTr("Enter two valid #RRGGBB values.")
                  : dialog.canApply
                    ? qsTr("Text contrast: %1:1").arg(dialog.ratio.toFixed(1))
                    : qsTr("Low contrast (%1:1). At least 4.5:1 is required.").arg(dialog.ratio.toFixed(1))
            color: dialog.canApply ? PlasmaCore.Theme.textColor
                                   : PlasmaCore.Theme.negativeTextColor
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Button {
                text: qsTr("Automatic colors")
                onClicked: {
                    dialog.automaticRequested()
                    dialog.close()
                }
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Button {
                text: qsTr("Cancel")
                onClicked: dialog.close()
            }
            PlasmaComponents3.Button {
                text: qsTr("Apply")
                enabled: dialog.canApply
                onClicked: {
                    dialog.colorsAccepted(dialog.draftForeground, dialog.draftBackground)
                    dialog.close()
                }
            }
        }
    }
}
