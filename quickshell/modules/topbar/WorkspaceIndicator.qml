import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: root

    required property string monitorName

    // Pastel palette (matching control center)
    readonly property color bgCard: "#2a2a3c"
    readonly property color textPrimary: "#cdd6f4"
    readonly property color textMuted: "#6c7086"
    readonly property color accentMauve: "#cba6f7"

    width: pill.width
    height: pill.height

    property var monitorWorkspaces: {
        var list = [];
        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
            var ws = Hyprland.workspaces.values[i];
            if (ws.monitor && ws.monitor.name === monitorName) {
                list.push(ws);
            }
        }
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    property int activeIndex: {
        if (!Hyprland.focusedWorkspace) return 0;
        for (var i = 0; i < monitorWorkspaces.length; i++) {
            if (monitorWorkspaces[i].id === Hyprland.focusedWorkspace.id) {
                return i;
            }
        }
        return 0;
    }

    Rectangle {
        id: pill
        width: row.width + 6
        height: 28
        radius: 0
        color: root.bgCard

        MouseArea {
            anchors.fill: parent
            property real scrollAccum: 0
            
            Timer {
                id: scrollCooldown
                interval: 150
            }
            
            onWheel: wheel => {
                if (scrollCooldown.running) return
                
                scrollAccum += wheel.angleDelta.y
                
                if (scrollAccum > 60) {
                    Hyprland.dispatch("workspace m-1")
                    scrollAccum = 0
                    scrollCooldown.start()
                } else if (scrollAccum < -60) {
                    Hyprland.dispatch("workspace m+1")
                    scrollAccum = 0
                    scrollCooldown.start()
                }
            }
        }

        Rectangle {
            id: activeIndicator
            width: 24
            height: 24
            radius: 0
            color: root.accentMauve
            y: 2
            x: 3 + (root.activeIndex * 26)

            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.monitorWorkspaces

                Item {
                    required property var modelData
                    required property int index

                    width: 24
                    height: 24

                    property bool isActive: root.activeIndex === index

                    Text {
                        anchors.centerIn: parent
                        text: (((modelData.id - 1) % 10) + 1).toString()
                        font {
                            family: "Space Grotesk"
                            pixelSize: 11
                            weight: Font.Medium
                        }
                        color: parent.isActive ? "#1e1e2e" : root.textMuted

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }
    }
}
