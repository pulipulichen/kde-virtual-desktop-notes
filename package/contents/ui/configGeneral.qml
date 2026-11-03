import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

ColumnLayout {
    id: settings
    property alias cfg_noteWidth: widthSpin.value
    property alias cfg_showDesktopName: showName.checked

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
        value: 240
        Layout.preferredWidth: 180
    }

    Controls.CheckBox {
        id: showName
        text: qsTr("Show the current virtual desktop name")
        checked: true
    }

    Controls.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("The title follows KDE's virtual desktop name. The note editor accepts one or two lines; the text automatically fits the panel's available space.")
    }
}
