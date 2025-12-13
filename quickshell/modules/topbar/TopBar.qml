import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool controlPanelVisible: false
    property bool centerPanelVisible: false
    property int sysVolume: 0
    property int sysBrightness: 0
    property int sysBattery: 100
    property bool sysCharging: false
    property string sysBatteryStatus: ""
    property string sysSsid: "WiFi"

    function setVolume(val) {
        val = Math.max(0, Math.min(100, val))
        sysVolume = val
        volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val/100).toFixed(2)]
        volSetProc.running = true
    }

    function setBrightness(val) {
        val = Math.max(1, Math.min(100, val))
        sysBrightness = val
        brightSetProc.command = ["brightnessctl", "set", val + "%"]
        brightSetProc.running = true
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"]
        stdout: SplitParser { onRead: data => { root.sysVolume = parseInt(data.trim()) || 0 } }
    }
    Process { id: volSetProc; command: [] }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
        stdout: SplitParser { onRead: data => { root.sysBrightness = parseInt(data.trim()) || 0 } }
    }
    Process { id: brightSetProc; command: [] }

    Process {
        id: batProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        stdout: SplitParser { onRead: data => { root.sysBattery = parseInt(data.trim()) || 100 } }
    }

    Process {
        id: batStatusProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        stdout: SplitParser { onRead: data => {
            root.sysBatteryStatus = data.trim()
            root.sysCharging = data.trim() === "Charging"
        }}
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | head -1"]
        stdout: SplitParser { onRead: data => {
            var parts = data.trim().split(":")
            if (parts.length >= 3 && parts[0] === "yes") {
                root.sysSsid = parts[1] || "WiFi"
            } else {
                root.sysSsid = "Offline"
            }
        }}
    }

    Timer {
        interval: 1000
        running: true
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: topBar
            required property var modelData

            anchors {
                top: true
                left: true
                right: true
            }

            screen: modelData
            implicitHeight: 36
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 36
            focusable: false

            Rectangle {
                anchors.fill: parent
                color: "#1e1e2e"

                Image {
                    id: archLogo
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    source: "../../assets/archlogo.svg"
                    sourceSize: Qt.size(20, 20)
                }

                WorkspaceIndicator {
                    monitorName: topBar.modelData.name
                    anchors.left: archLogo.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: dateTimeItem
                    anchors.centerIn: parent
                    width: 180
                    height: parent.height
                    visible: !root.centerPanelVisible

                    property string dateStr: ""
                    property string timeStr: ""

                    Text {
                        anchors.right: parent.horizontalCenter
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: dateTimeItem.dateStr
                        font.family: "Space Grotesk"
                        font.pixelSize: 11
                        color: "#6c7086"
                    }

                    Text {
                        anchors.left: parent.horizontalCenter
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: dateTimeItem.timeStr
                        font.family: "Space Grotesk"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#cdd6f4"
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            var now = new Date()
                            dateTimeItem.dateStr = now.getFullYear() + "-" + String(now.getMonth()+1).padStart(2,'0') + "-" + String(now.getDate()).padStart(2,'0')
                            dateTimeItem.timeStr = String(now.getHours()).padStart(2,'0') + ":" + String(now.getMinutes()).padStart(2,'0') + ":" + String(now.getSeconds()).padStart(2,'0')
                        }
                    }
                }

                MouseArea {
                    anchors.centerIn: parent
                    width: 200
                    height: parent.height
                    hoverEnabled: true
                    onEntered: root.centerPanelVisible = true
                }

                Row {
                    id: widgetRow
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    visible: !root.controlPanelVisible

                    Row {
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰕾"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: "#cdd6f4"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            text: root.sysVolume + "%"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: "#cdd6f4"
                        }
                    }

                    Row {
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sysCharging ? "󰂄" : (root.sysBattery > 80 ? "󰁹" : root.sysBattery > 60 ? "󰂀" : root.sysBattery > 40 ? "󰁾" : root.sysBattery > 20 ? "󰁼" : "󰁺")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: root.sysBattery <= 20 ? "#f38ba8" : "#cdd6f4"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            text: root.sysBattery + "%"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: root.sysBattery <= 20 ? "#f38ba8" : "#cdd6f4"
                        }
                    }

                    Row {
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰤨"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: "#cdd6f4"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            text: root.sysSsid
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 220
                    hoverEnabled: true
                    onEntered: root.controlPanelVisible = true
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: controlPanel
            required property var modelData
            screen: modelData

            anchors.top: true
            anchors.right: true

            implicitWidth: 280
            implicitHeight: 170
            color: "#1e1e2e"
            exclusionMode: ExclusionMode.Ignore
            visible: root.controlPanelVisible

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onExited: root.controlPanelVisible = false

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰕾"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: "#f5c2e7"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            height: 6
                            color: "#45475a"

                            Rectangle {
                                width: parent.width * (root.sysVolume / 100)
                                height: parent.height
                                color: "#f5c2e7"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => root.setVolume(Math.round(mouse.x / width * 100))
                                onPositionChanged: mouse => { if (pressed) root.setVolume(Math.round(mouse.x / width * 100)) }
                                onWheel: wheel => root.setVolume(root.sysVolume + (wheel.angleDelta.y > 0 ? 5 : -5))
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            text: root.sysVolume + "%"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: "#cdd6f4"
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰃟"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: "#fab387"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            height: 6
                            color: "#45475a"

                            Rectangle {
                                width: parent.width * (root.sysBrightness / 100)
                                height: parent.height
                                color: "#fab387"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => root.setBrightness(Math.round(mouse.x / width * 100))
                                onPositionChanged: mouse => { if (pressed) root.setBrightness(Math.round(mouse.x / width * 100)) }
                                onWheel: wheel => root.setBrightness(root.sysBrightness + (wheel.angleDelta.y > 0 ? 5 : -5))
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            text: root.sysBrightness + "%"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: "#cdd6f4"
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 8

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: parent.height
                            color: "#2a2a3c"

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: root.sysCharging ? "󰂄" : (root.sysBattery > 80 ? "󰁹" : root.sysBattery > 60 ? "󰂀" : root.sysBattery > 40 ? "󰁾" : root.sysBattery > 20 ? "󰁼" : "󰁺")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: root.sysBattery <= 20 ? "#f38ba8" : "#a6e3a1"
                                }

                                Text {
                                    text: root.sysBattery + "%"
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 11
                                    color: "#cdd6f4"
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: parent.height
                            color: "#2a2a3c"

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "󰤨"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: "#89b4fa"
                                }

                                Text {
                                    text: root.sysSsid
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 11
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    width: 60
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 36
                        spacing: 8

                        Repeater {
                            model: [
                                { icon: "󰐥", cmd: "systemctl poweroff", accent: "#f38ba8" },
                                { icon: "󰜉", cmd: "systemctl reboot", accent: "#fab387" },
                                { icon: "󰤄", cmd: "systemctl suspend", accent: "#cba6f7" },
                                { icon: "󰌾", cmd: "hyprlock", accent: "#a6e3a1" }
                            ]

                            Rectangle {
                                id: actionBtn
                                required property var modelData
                                width: (parent.width - 24) / 4
                                height: parent.height
                                color: actionHover.hovered ? "#353548" : "#2a2a3c"

                                Text {
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: actionHover.hovered ? actionBtn.modelData.accent : "#a6adc8"
                                }

                                HoverHandler {
                                    id: actionHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        root.controlPanelVisible = false
                                        actionProc.command = ["sh", "-c", actionBtn.modelData.cmd]
                                        actionProc.running = true
                                    }
                                }

                                Process { id: actionProc; command: [] }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: centerPanel
            required property var modelData
            screen: modelData

            readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            readonly property var daysShort: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            readonly property var daysLong: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

            property string bigTime: ""
            property string bigDate: ""
            property string dayName: ""
            property int currentYear: 2025
            property int currentMonth: 0
            property int currentDay: 1
            property int calendarYear: 2025
            property int calendarMonth: 0

            function daysInMonth(year, month) { return new Date(year, month + 1, 0).getDate() }
            function firstDayOfMonth(year, month) { return new Date(year, month, 1).getDay() }
            function prevMonth() { if (calendarMonth === 0) { calendarMonth = 11; calendarYear-- } else { calendarMonth-- } }
            function nextMonth() { if (calendarMonth === 11) { calendarMonth = 0; calendarYear++ } else { calendarMonth++ } }
            function goToToday() { calendarMonth = currentMonth; calendarYear = currentYear }

            anchors.top: true
            anchors.left: true
            anchors.right: true
            margins.left: modelData.width * 0.3
            margins.right: modelData.width * 0.3

            implicitHeight: 400
            color: "#1e1e2e"
            exclusionMode: ExclusionMode.Ignore
            visible: root.centerPanelVisible

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var now = new Date()
                    centerPanel.bigTime = String(now.getHours()).padStart(2,'0') + " : " + String(now.getMinutes()).padStart(2,'0') + " : " + String(now.getSeconds()).padStart(2,'0')
                    centerPanel.bigDate = now.getDate() + " " + centerPanel.months[now.getMonth()] + " " + now.getFullYear()
                    centerPanel.dayName = centerPanel.daysLong[now.getDay()]
                    centerPanel.currentYear = now.getFullYear()
                    centerPanel.currentMonth = now.getMonth()
                    centerPanel.currentDay = now.getDate()
                    if (centerPanel.calendarYear === 2025 && centerPanel.calendarMonth === 0) {
                        centerPanel.calendarYear = now.getFullYear()
                        centerPanel.calendarMonth = now.getMonth()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onExited: root.centerPanelVisible = false

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: centerPanel.bigTime
                            font.family: "Space Grotesk"
                            font.pixelSize: 48
                            font.weight: Font.Bold
                            font.letterSpacing: 3
                            color: "#cdd6f4"
                        }

                        Text {
                            text: centerPanel.dayName + ", " + centerPanel.bigDate
                            font.family: "Space Grotesk"
                            font.pixelSize: 16
                            color: "#a6adc8"
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                color: prevHover.hovered ? "#353548" : "#2a2a3c"
                                radius: 4

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅁"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: "#cdd6f4"
                                }

                                HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: centerPanel.prevMonth() }
                            }

                            Text {
                                width: 140
                                height: 28
                                text: centerPanel.months[centerPanel.calendarMonth] + " " + centerPanel.calendarYear
                                font.family: "Space Grotesk"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#cdd6f4"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: centerPanel.goToToday() }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                color: nextHover.hovered ? "#353548" : "#2a2a3c"
                                radius: 4

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅂"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: "#cdd6f4"
                                }

                                HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: centerPanel.nextMonth() }
                            }
                        }

                        Row {
                            spacing: 0
                            Repeater {
                                model: centerPanel.daysShort
                                Text {
                                    width: 32
                                    height: 24
                                    text: modelData
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 11
                                    color: "#6c7086"
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        Grid {
                            columns: 7
                            spacing: 0

                            Repeater {
                                model: 42

                                Rectangle {
                                    property int dayNum: {
                                        var firstDay = centerPanel.firstDayOfMonth(centerPanel.calendarYear, centerPanel.calendarMonth)
                                        var daysInM = centerPanel.daysInMonth(centerPanel.calendarYear, centerPanel.calendarMonth)
                                        var day = index - firstDay + 1
                                        return (day > 0 && day <= daysInM) ? day : 0
                                    }
                                    property bool isToday: dayNum === centerPanel.currentDay && 
                                                           centerPanel.calendarMonth === centerPanel.currentMonth && 
                                                           centerPanel.calendarYear === centerPanel.currentYear

                                    width: 32
                                    height: 32
                                    color: isToday ? "#cba6f7" : "transparent"
                                    radius: isToday ? 16 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.dayNum > 0 ? parent.dayNum : ""
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 12
                                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                                        color: parent.isToday ? "#1e1e2e" : "#cdd6f4"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
