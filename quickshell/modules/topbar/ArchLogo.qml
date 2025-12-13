import QtQuick
import Quickshell.Io
import qs.config

Rectangle {
    id: root

    width: 40
    height: 40
    color: "transparent"

    Process {
        id: fastfetchProc
        command: ["kitty", "-e", "fish", "-c", "fastfetch; read -P 'Press any key...'"]
    }

    Image {
        anchors.centerIn: parent
        source: "../../assets/archlogo.svg"
        width: 28
        height: 28
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.color = Qt.rgba(Appearance.colors.vermillion.r, Appearance.colors.vermillion.g, Appearance.colors.vermillion.b, 0.1)
        onExited: root.color = "transparent"
        onClicked: fastfetchProc.running = true
    }
}

