import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

ColumnLayout {
    id: settings
    property alias cfg_noteWidth: widthSpin.value
    property alias cfg_showDesktopName: showName.checked
    property alias cfg_desktopNameOnly: nameOnly.checked

    spacing: 12

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
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("Name-only mode fills the panel with the active desktop name, without showing the note editor. Turning it off restores your session notes. In normal mode, notes accept one or two lines and automatically fit the available space.")
    }
}
