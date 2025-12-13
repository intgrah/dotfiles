import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: dateTimeRoot
    Layout.preferredWidth: 100
    Layout.fillHeight: true

    readonly property color textPrimary: "#cdd6f4"
    readonly property color textMuted: "#6c7086"

    property string dateStr: ""
    property string timeStr: ""

    Column {
        id: dateColumn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            anchors.right: parent.right
            text: dateTimeRoot.dateStr
            font {
                family: "Space Grotesk"
                pixelSize: 10
            }
            color: dateTimeRoot.textMuted
        }

        Text {
            anchors.right: parent.right
            text: dateTimeRoot.timeStr
            font {
                family: "Space Grotesk"
                pixelSize: 14
                weight: Font.Medium
            }
            color: dateTimeRoot.textPrimary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Appearance.controlCenterOpen = !Appearance.controlCenterOpen
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            var year = now.getFullYear();
            var month = String(now.getMonth() + 1).padStart(2, '0');
            var day = String(now.getDate()).padStart(2, '0');
            var hours = String(now.getHours()).padStart(2, '0');
            var minutes = String(now.getMinutes()).padStart(2, '0');
            var seconds = String(now.getSeconds()).padStart(2, '0');
            dateStr = year + "-" + month + "-" + day;
            timeStr = hours + ":" + minutes + ":" + seconds;
        }
    }
}
