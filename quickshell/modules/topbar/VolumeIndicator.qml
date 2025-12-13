import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config

Row {
    spacing: 4

    readonly property color textPrimary: "#cdd6f4"
    readonly property color textMuted: "#6c7086"
    readonly property color accentPink: "#f5c2e7"

    property int volume: 0
    property bool muted: false

    Text {
        text: parent.muted ? "🔇" : "🔊"
        font.pixelSize: 12
        color: parent.textPrimary
    }

    Text {
        text: parent.volume + "%"
        font {
            family: "Space Grotesk"
            pixelSize: 11
        }
        color: parent.textPrimary
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length >= 2) {
                    var vol = parseFloat(parts[1]) * 100;
                    volume = Math.round(vol);
                    muted = data.includes("[MUTED]");
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: volumeProc.running = true
    }
}
