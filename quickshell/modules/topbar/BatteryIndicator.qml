import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config

Row {
    spacing: 4

    readonly property color textPrimary: "#cdd6f4"
    readonly property color accentGreen: "#a6e3a1"
    readonly property color accentPeach: "#fab387"
    readonly property color accentRed: "#f38ba8"

    property int level: 100
    property bool charging: false

    Text {
        text: parent.charging ? "⚡" : "🔋"
        font.pixelSize: 12
    }

    Text {
        text: parent.level + "%"
        font {
            family: "Space Grotesk"
            pixelSize: 11
        }
        color: {
            if (parent.level <= 20) return parent.accentRed
            if (parent.level <= 50) return parent.accentPeach
            return parent.textPrimary
        }
    }

    Process {
        id: batteryProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                level = parseInt(data.trim()) || 100;
            }
        }
    }

    Process {
        id: statusProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                charging = data.trim() === "Charging";
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true;
            statusProc.running = true;
        }
    }
}
