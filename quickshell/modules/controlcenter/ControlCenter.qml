import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root

    property bool isOpen: Appearance.controlCenterOpen

    // Pastel palette
    readonly property color bgBase: "#1e1e2e"
    readonly property color bgCard: "#2a2a3c"
    readonly property color bgHover: "#353548"
    readonly property color textPrimary: "#cdd6f4"
    readonly property color textSecondary: "#a6adc8"
    readonly property color textMuted: "#6c7086"
    readonly property color accentPink: "#f5c2e7"
    readonly property color accentMauve: "#cba6f7"
    readonly property color accentPeach: "#fab387"
    readonly property color accentGreen: "#a6e3a1"
    readonly property color accentRed: "#f38ba8"
    readonly property color sliderBg: "#45475a"

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: Appearance.controlCenterOpen = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }

            margins.top: 40
            margins.right: 8

            implicitWidth: 340
            implicitHeight: 420

            visible: root.isOpen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // Cascade animation component
            component CascadeCard: Rectangle {
                id: card
                property int cardIndex: 0
                property bool showCard: root.isOpen

                Layout.fillWidth: true
                color: root.bgCard
                radius: 0

                opacity: 0
                transform: Translate { id: cardTranslate; y: -30 }

                states: State {
                    name: "visible"
                    when: card.showCard
                    PropertyChanges { target: card; opacity: 1 }
                    PropertyChanges { target: cardTranslate; y: 0 }
                }

                transitions: Transition {
                    to: "visible"
                    SequentialAnimation {
                        PauseAnimation { duration: card.cardIndex * 50 }
                        ParallelAnimation {
                            NumberAnimation { target: card; property: "opacity"; duration: 150; easing.type: Easing.OutCubic }
                            NumberAnimation { target: cardTranslate; property: "y"; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                        }
                    }
                }
            }

            Rectangle {
                id: mainPanel
                anchors.fill: parent
                color: root.bgBase
                radius: 0
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Header
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        opacity: root.isOpen ? 1 : 0
                        transform: Translate { id: headerTranslate; y: root.isOpen ? 0 : -20 }
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        RowLayout {
                            anchors.fill: parent
                            Text {
                                text: "Control Center"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                font.family: "Space Grotesk"
                                color: root.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 20
                                height: 20
                                color: closeBtn.containsMouse ? root.bgCard : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 10
                                    color: root.textMuted
                                }
                                MouseArea {
                                    id: closeBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Appearance.controlCenterOpen = false
                                }
                            }
                        }
                    }

                    // Audio Card
                    CascadeCard {
                        id: audioCard
                        cardIndex: 0
                        Layout.preferredHeight: 56

                        property int volume: 0
                        property bool dragging: false

                        function setVolume(val) {
                            val = Math.max(0, Math.min(100, val))
                            audioCard.volume = val
                            volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val / 100).toFixed(2)]
                            volSetProc.running = true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "🔊"; font.pixelSize: 16 }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Text {
                                        text: "Volume"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textSecondary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: audioCard.volume + "%"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textPrimary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: root.sliderBg

                                    Rectangle {
                                        width: parent.width * (audioCard.volume / 100)
                                        height: parent.height
                                        color: root.accentPink
                                        Behavior on width {
                                            enabled: !audioCard.dragging
                                            NumberAnimation { duration: 60 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: mouse => {
                                            audioCard.dragging = true
                                            audioCard.setVolume(Math.round(mouse.x / width * 100))
                                        }
                                        onPositionChanged: mouse => {
                                            if (pressed) audioCard.setVolume(Math.round(mouse.x / width * 100))
                                        }
                                        onReleased: audioCard.dragging = false
                                    }
                                }
                            }
                        }

                        Process {
                            id: volProc
                            command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"]
                            stdout: SplitParser {
                                onRead: data => {
                                    if (!audioCard.dragging) audioCard.volume = parseInt(data.trim()) || 0
                                }
                            }
                        }
                        Process { id: volSetProc; command: [] }
                    }

                    // Brightness Card
                    CascadeCard {
                        id: brightCard
                        cardIndex: 1
                        Layout.preferredHeight: 56

                        property int brightness: 0
                        property bool dragging: false

                        function setBrightness(val) {
                            val = Math.max(1, Math.min(100, val))
                            brightCard.brightness = val
                            brightSetProc.command = ["brightnessctl", "set", val + "%"]
                            brightSetProc.running = true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "☀"; font.pixelSize: 16 }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Text {
                                        text: "Brightness"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textSecondary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: brightCard.brightness + "%"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textPrimary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: root.sliderBg

                                    Rectangle {
                                        width: parent.width * (brightCard.brightness / 100)
                                        height: parent.height
                                        color: root.accentPeach
                                        Behavior on width {
                                            enabled: !brightCard.dragging
                                            NumberAnimation { duration: 60 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: mouse => {
                                            brightCard.dragging = true
                                            brightCard.setBrightness(Math.round(mouse.x / width * 100))
                                        }
                                        onPositionChanged: mouse => {
                                            if (pressed) brightCard.setBrightness(Math.round(mouse.x / width * 100))
                                        }
                                        onReleased: brightCard.dragging = false
                                    }
                                }
                            }
                        }

                        Process {
                            id: brightProc
                            command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
                            stdout: SplitParser {
                                onRead: data => {
                                    if (!brightCard.dragging) brightCard.brightness = parseInt(data.trim()) || 0
                                }
                            }
                        }
                        Process { id: brightSetProc; command: [] }
                    }

                    // Battery Card
                    CascadeCard {
                        id: batCard
                        cardIndex: 2
                        Layout.preferredHeight: 56

                        property int capacity: 0
                        property string status: ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: batCard.status === "Charging" ? "⚡" : "🔋"
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Text {
                                        text: "Battery"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textSecondary
                                    }
                                    Text {
                                        text: batCard.status
                                        font.pixelSize: 9
                                        font.family: "Space Grotesk"
                                        color: root.textMuted
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: batCard.capacity + "%"
                                        font.pixelSize: 11
                                        font.family: "Space Grotesk"
                                        color: root.textPrimary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: root.sliderBg
                                    Rectangle {
                                        width: parent.width * (batCard.capacity / 100)
                                        height: parent.height
                                        color: batCard.capacity <= 20 ? root.accentRed : batCard.capacity <= 50 ? root.accentPeach : root.accentGreen
                                        Behavior on width { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }

                        Process {
                            id: batProc
                            command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
                            stdout: SplitParser {
                                onRead: data => { batCard.capacity = parseInt(data.trim()) || 0 }
                            }
                        }
                        Process {
                            id: batStatusProc
                            command: ["cat", "/sys/class/power_supply/BAT0/status"]
                            stdout: SplitParser {
                                onRead: data => { batCard.status = data.trim() }
                            }
                        }
                    }

                    // Network Card
                    CascadeCard {
                        id: netCard
                        cardIndex: 3
                        Layout.preferredHeight: 48

                        property string ssid: "Not connected"
                        property string signal: ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "📶"; font.pixelSize: 16 }

                            Text {
                                text: "Network"
                                font.pixelSize: 11
                                font.family: "Space Grotesk"
                                color: root.textSecondary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: netCard.ssid
                                font.pixelSize: 11
                                font.family: "Space Grotesk"
                                color: root.textPrimary
                            }

                            Text {
                                text: netCard.signal
                                font.pixelSize: 10
                                font.family: "Space Grotesk"
                                color: root.accentMauve
                                visible: netCard.signal !== ""
                            }
                        }

                        Process {
                            id: wifiProc
                            command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | head -1"]
                            stdout: SplitParser {
                                onRead: data => {
                                    var parts = data.trim().split(":")
                                    if (parts.length >= 3 && parts[0] === "yes") {
                                        netCard.ssid = parts[1] || "WiFi"
                                        netCard.signal = parts[2] + "%"
                                    } else {
                                        netCard.ssid = "Not connected"
                                        netCard.signal = ""
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Quick actions - also cascade
                    CascadeCard {
                        id: actionsCard
                        cardIndex: 4
                        Layout.preferredHeight: 36
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 6

                            Repeater {
                                model: [
                                    { icon: "⏻", cmd: "systemctl poweroff", accent: root.accentRed },
                                    { icon: "↻", cmd: "systemctl reboot", accent: root.accentPeach },
                                    { icon: "⏾", cmd: "systemctl suspend", accent: root.accentMauve },
                                    { icon: "🔒", cmd: "hyprlock", accent: root.accentGreen }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: actionMa.containsMouse ? root.bgHover : root.bgCard

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 14
                                        color: actionMa.containsMouse ? modelData.accent : root.textSecondary
                                    }

                                    MouseArea {
                                        id: actionMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Appearance.controlCenterOpen = false
                                            actionProc.command = ["sh", "-c", modelData.cmd]
                                            actionProc.running = true
                                        }
                                    }
                                }
                            }

                            Process { id: actionProc; command: [] }
                        }
                    }
                }
            }

            Timer {
                interval: 500
                running: root.isOpen
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    volProc.running = true
                    brightProc.running = true
                    batProc.running = true
                    batStatusProc.running = true
                    wifiProc.running = true
                }
            }
        }
    }
}
