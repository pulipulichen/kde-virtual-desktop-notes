import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.private.pager 2.0

Item {
    id: root
    // Never save user text in plasmoid.configuration / KConfig.
    // An in-memory store clears on Plasma Shell restart (including reboot).
    property var desktopNotes: ({})
    property int displayWidth: 205
    property int displayFontSize: 16

    PagerModel {
        id: desktopInfo
        enabled: true
        pagerType: PagerModel.VirtualDesktops
    }

    function currentKey() {
        return String(desktopInfo.currentPage + 1)
    }

    function currentLine(index) {
        var pair = desktopNotes[currentKey()]
        return pair ? pair[index] : ""
    }

    function updateCurrentLine(index, value) {
        var copy = {}
        for (var id in desktopNotes)
            copy[id] = desktopNotes[id]
        var old = copy[currentKey()] || ["", ""]
        var pair = [old[0], old[1]]
        pair[index] = value
        copy[currentKey()] = pair
        desktopNotes = copy
    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.toolTipMainText: "虛擬桌面臨時備忘錄"
    Plasmoid.toolTipSubText: "點擊可編輯兩行文字；重新開機清空"

    Plasmoid.compactRepresentation: Item {
        Layout.minimumWidth: root.displayWidth
        Layout.preferredWidth: root.displayWidth
        Layout.maximumWidth: root.displayWidth
        Layout.minimumHeight: 32
        Layout.preferredHeight: 42

        Column {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0
            Text {
                width: parent.width
                height: parent.height / 2
                text: root.currentLine(0)
                font.pixelSize: root.displayFontSize
                color: PlasmaCore.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                height: parent.height / 2
                text: root.currentLine(1)
                font.pixelSize: root.displayFontSize
                color: PlasmaCore.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }
    }

    Plasmoid.fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 300
        Layout.preferredWidth: 340
        Layout.minimumHeight: 128
        Layout.preferredHeight: 140
        spacing: 8
        PlasmaComponents3.Label {
            text: "桌面 " + (desktopInfo.currentPage + 1) + " · 編輯工具列文字"
            Layout.fillWidth: true
        }
        PlasmaComponents3.TextField {
            id: firstLine
            Layout.fillWidth: true
            placeholderText: "第一行"
            text: root.currentLine(0)
            onTextEdited: root.updateCurrentLine(0, text)
        }
        PlasmaComponents3.TextField {
            id: secondLine
            Layout.fillWidth: true
            placeholderText: "第二行"
            text: root.currentLine(1)
            onTextEdited: root.updateCurrentLine(1, text)
        }
        PlasmaComponents3.Label {
            text: "文字暫存於記憶體；重啟 Plasma 或開機後會清空。"
            Layout.fillWidth: true
            font.pixelSize: 11
        }
    }
}
