import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property int barHeight: 36
    readonly property int dropdownWidth: 480
    readonly property int dropdownHeight: 360
    readonly property int closeDelay: 50

    property int activePanel: -1
    property bool dropdownHovered: false
    property bool topbarHovered: false
    property bool controlPanelVisible: false
    property bool controlTriggerHovered: false
    property bool controlPanelHovered: false

    function tryCloseControlPanel() {
        if (!controlTriggerHovered && !controlPanelHovered) controlPanelVisible = false
    }

    property int sysVolume: 0
    property bool sysMuted: false
    property int sysBrightness: 0
    property int sysBattery: 100
    property bool sysCharging: false
    property string sysSsid: "WiFi"
    property bool vpnConnected: false
    property string vpnCountry: ""
    property string musicFile: ""
    property string musicPlayer: ""
    property bool musicPlaying: false
    property int musicPosition: 0
    property int musicLength: 0

    function setVolume(v) {
        sysVolume = Math.max(0, Math.min(100, v))
        volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (sysVolume / 100).toFixed(2)]
        volSetProc.running = true
    }

    function setBrightness(v) {
        sysBrightness = Math.max(1, Math.min(100, v))
        brightSetProc.command = ["brightnessctl", "set", sysBrightness + "%"]
        brightSetProc.running = true
    }

    function tryCloseDropdown() {
        if (!topbarHovered && !dropdownHovered) activePanel = -1
    }

    function batteryIcon(level, charging) {
        if (charging) return "󰂄"
        if (level > 80) return "󰁹"
        if (level > 60) return "󰂀"
        if (level > 40) return "󰁾"
        if (level > 20) return "󰁼"
        return "󰁺"
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser { onRead: d => {
            root.sysMuted = d.includes("[MUTED]")
            let match = d.match(/Volume: ([0-9.]+)/)
            root.sysVolume = match ? Math.round(parseFloat(match[1]) * 100) : 0
        }}
    }

    Process {
        id: volWatch
        running: true
        command: ["sh", "-c", "pactl subscribe | grep --line-buffered 'sink'"]
        stdout: SplitParser { onRead: d => volProc.running = true }
    }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
        stdout: SplitParser { onRead: d => root.sysBrightness = parseInt(d.trim()) || 0 }
    }

    Process {
        id: batProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        stdout: SplitParser { onRead: d => root.sysBattery = parseInt(d.trim()) || 100 }
    }

    Process {
        id: batStatusProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        stdout: SplitParser { onRead: d => root.sysCharging = d.trim() === "Charging" }
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2 | head -1"]
        stdout: SplitParser { onRead: d => root.sysSsid = d.trim() || "Offline" }
    }

    Process {
        id: vpnProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE connection show --active | grep wireguard | cut -d: -f1"]
        stdout: SplitParser { onRead: d => {
            let name = d.trim()
            root.vpnConnected = name !== ""
            if (name.includes("UK")) root.vpnCountry = "UK"
            else if (name.includes("CH") || name.includes("Switzerland")) root.vpnCountry = "CH"
            else if (name.includes("AL") || name.includes("Albania")) root.vpnCountry = "AL"
            else if (name.includes("NL") || name.includes("Netherlands")) root.vpnCountry = "NL"
            else if (name) root.vpnCountry = name.split("#")[0].replace("ProtonVPN ", "")
            else root.vpnCountry = ""
        }}
    }

    Process { id: vpnConnectProc; command: [] }
    Process { id: vpnDisconnectProc; command: ["protonvpn", "disconnect"] }

    Process {
        id: musicProc
        running: true
        command: ["sh", "-c", "playerctl --player=playerctld --follow metadata --format '{{status}}|||{{playerName}}|||{{title}}' 2>/dev/null"]
        stdout: SplitParser { onRead: d => {
            let parts = d.trim().split("|||")
            root.musicPlaying = parts[0] === "Playing"
            root.musicPlayer = parts[1] || ""
            root.musicFile = parts[2] || ""
            positionProc.running = true
        }}
    }

    Process { id: volSetProc; command: [] }
    Process { id: brightSetProc; command: [] }
    Process { id: musicPrevProc; command: ["playerctl", "--player=playerctld", "previous"] }
    Process { id: musicPlayProc; command: ["playerctl", "--player=playerctld", "play-pause"] }
    Process { id: musicNextProc; command: ["playerctl", "--player=playerctld", "next"] }
    Process { id: musicSeekProc; command: [] }
    Process { id: ncmpcppProc; command: ["kitty", "--class", "floating-terminal", "-e", "ncmpcpp"] }
    Process {
        id: positionProc
        command: ["sh", "-c", "mpc status | grep -oP '\\d+:\\d+/\\d+:\\d+' || echo '0:00/0:00'"]
        stdout: SplitParser { onRead: d => {
            let match = d.trim().match(/(\d+:\d+)\/(\d+:\d+)/)
            if (match) {
                root.musicPosition = parseTime(match[1])
                root.musicLength = parseTime(match[2])
            }
        }}
    }

    function parseTime(str) {
        let parts = str.split(":").map(s => parseInt(s) || 0)
        if (parts.length === 2) return parts[0] * 60 + parts[1]
        if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2]
        return 0
    }

    function seekTo(seconds) {
        musicSeekProc.command = ["mpc", "seek", String(seconds)]
        musicSeekProc.running = true
        seekRefreshTimer.restart()
    }

    function seekRelative(delta) {
        musicSeekProc.command = ["mpc", "seek", (delta >= 0 ? "+" : "") + String(delta)]
        musicSeekProc.running = true
        seekRefreshTimer.restart()
    }

    Timer {
        id: seekRefreshTimer
        interval: 100
        onTriggered: positionProc.running = true
    }

    Timer {
        id: positionTimer
        interval: 1000
        running: root.musicPlaying
        repeat: true
        onTriggered: positionProc.running = true
    }

    function formatTime(seconds) {
        let m = Math.floor(seconds / 60)
        let s = seconds % 60
        return m + ":" + String(s).padStart(2, '0')
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            brightProc.running = true
            batProc.running = true
            batStatusProc.running = true
            wifiProc.running = true
            vpnProc.running = true
        }
    }

    Component.onCompleted: volProc.running = true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: topBar
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: root.barHeight
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.barHeight
            focusable: false

            Timer {
                id: closeTimer
                interval: root.closeDelay
                onTriggered: root.tryCloseDropdown()
            }

            Rectangle {
                anchors.fill: parent
                color: "#1e1e2e"

                Image {
                    id: logo
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    source: "../../assets/archlogo.svg"
                    sourceSize: Qt.size(20, 20)
                }

                WorkspaceIndicator {
                    id: workspaces
                    monitorName: topBar.modelData.name
                    anchors.left: logo.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: centerArea
                    anchors.centerIn: parent
                    width: root.dropdownWidth
                    height: parent.height

                    property string dateStr: ""
                    property string timeStr: ""

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            var now = new Date()
                            centerArea.dateStr = now.getFullYear() + "-" + String(now.getMonth()+1).padStart(2,'0') + "-" + String(now.getDate()).padStart(2,'0')
                            centerArea.timeStr = String(now.getHours()).padStart(2,'0') + ":" + String(now.getMinutes()).padStart(2,'0') + ":" + String(now.getSeconds()).padStart(2,'0')
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.topbarHovered = true
                        onExited: { root.topbarHovered = false; closeTimer.restart() }
                        onPositionChanged: mouse => {
                            var section = Math.floor(mouse.x / (root.dropdownWidth / 3))
                            root.activePanel = Math.max(0, Math.min(2, section))
                        }
                    }

                    Row {
                        anchors.fill: parent

                        Item {
                            width: root.dropdownWidth / 3
                            height: parent.height
                        }

                        Item {
                            width: root.dropdownWidth / 3
                            height: parent.height

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                            Text {
                                text: centerArea.dateStr
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: "#6c7086"
                            }

                            Text {
                                text: centerArea.timeStr
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: "#cdd6f4"
                            }
                            }
                        }

                        Item {
                            width: root.dropdownWidth / 3
                            height: parent.height

                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                visible: root.musicFile !== ""

                                Text {
                                    text: "󰎆"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: "#cba6f7"
                                }

                                Text {
                                    text: root.musicFile
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 11
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth, 100)
                                }

                                Text {
                                    text: root.musicPlaying ? "󰏤" : "󰐊"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: miniPlayHover.hovered ? "#cba6f7" : "#6c7086"

                                    HoverHandler { id: miniPlayHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: musicPlayProc.running = true }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.musicFile === ""
                                text: "󰎆"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: "#6c7086"
                            }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Row {
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sysMuted ? "󰖁" : "󰕾"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: root.sysMuted ? "#f38ba8" : "#cdd6f4"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            text: root.sysVolume + "%"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            color: root.sysMuted ? "#f38ba8" : "#cdd6f4"
                        }
                    }

                    Row {
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.batteryIcon(root.sysBattery, root.sysCharging)
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
                    width: 180
                    hoverEnabled: true
                    onEntered: { root.controlTriggerHovered = true; root.controlPanelVisible = true }
                    onExited: { root.controlTriggerHovered = false; controlCloseTimer.restart() }
                }

                Timer {
                    id: controlCloseTimer
                    interval: 50
                    onTriggered: root.tryCloseControlPanel()
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dropdown
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.left: true
            anchors.right: true
            margins.top: root.barHeight
            margins.left: (modelData.width - root.dropdownWidth) / 2
            margins.right: (modelData.width - root.dropdownWidth) / 2
            implicitHeight: root.dropdownHeight
            color: "#1e1e2e"
            exclusionMode: ExclusionMode.Ignore
            visible: root.activePanel >= 0
            focusable: true

            readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            readonly property var days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            property int viewYear: new Date().getFullYear()
            property int viewMonth: new Date().getMonth()

            property string bigTime: ""
            property string bigDate: ""

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var now = new Date()
                    dropdown.bigTime = String(now.getHours()).padStart(2,'0') + " : " + String(now.getMinutes()).padStart(2,'0') + " : " + String(now.getSeconds()).padStart(2,'0')
                    dropdown.bigDate = dropdown.days[now.getDay()] + ", " + now.getDate() + " " + dropdown.months[now.getMonth()] + " " + now.getFullYear()
                }
            }

            Timer {
                id: dropdownCloseTimer
                interval: root.closeDelay
                onTriggered: root.tryCloseDropdown()
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.dropdownHovered = true
                onExited: { root.dropdownHovered = false; dropdownCloseTimer.restart() }

                Item {
                    id: slider
                    anchors.fill: parent
                    clip: true
                    property int lastPanel: -1

                    onVisibleChanged: if (!visible) lastPanel = -1

                    Connections {
                        target: root
                        function onActivePanelChanged() {
                            if (root.activePanel >= 0) slider.lastPanel = root.activePanel
                        }
                    }

                    Row {
                        height: parent.height
                        x: -root.activePanel * root.dropdownWidth

                        Behavior on x {
                            enabled: slider.lastPanel >= 0
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Item {
                            width: root.dropdownWidth
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "Space Grotesk"
                                font.pixelSize: 24
                                color: "#6c7086"
                            }
                        }

                        Item {
                            width: root.dropdownWidth
                            height: parent.height

                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: dropdown.bigTime
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 48
                                        font.weight: Font.Bold
                                        font.letterSpacing: 3
                                        color: "#cdd6f4"
                                    }

                                    Text {
                                        text: dropdown.bigDate
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 16
                                        color: "#a6adc8"
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 8

                                    Row {
                                        spacing: 8

                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 4
                                            color: prevHover.hovered ? "#353548" : "#2a2a3c"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅁"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 14
                                                color: "#cdd6f4"
                                            }

                                            HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                                            TapHandler {
                                                onTapped: {
                                                    if (dropdown.viewMonth === 0) {
                                                        dropdown.viewMonth = 11
                                                        dropdown.viewYear--
                                                    } else {
                                                        dropdown.viewMonth--
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            width: 140
                                            height: 28
                                            text: dropdown.months[dropdown.viewMonth] + " " + dropdown.viewYear
                                            font.family: "Space Grotesk"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: "#cdd6f4"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter

                                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                                            TapHandler {
                                                onTapped: {
                                                    dropdown.viewYear = new Date().getFullYear()
                                                    dropdown.viewMonth = new Date().getMonth()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 4
                                            color: nextHover.hovered ? "#353548" : "#2a2a3c"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅂"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 14
                                                color: "#cdd6f4"
                                            }

                                            HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                                            TapHandler {
                                                onTapped: {
                                                    if (dropdown.viewMonth === 11) {
                                                        dropdown.viewMonth = 0
                                                        dropdown.viewYear++
                                                    } else {
                                                        dropdown.viewMonth++
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        Repeater {
                                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
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

                                        Repeater {
                                            model: 42

                                            Rectangle {
                                                property int dayNum: {
                                                    var firstDay = new Date(dropdown.viewYear, dropdown.viewMonth, 1).getDay()
                                                    var daysInMonth = new Date(dropdown.viewYear, dropdown.viewMonth + 1, 0).getDate()
                                                    var day = index - firstDay + 1
                                                    return (day > 0 && day <= daysInMonth) ? day : 0
                                                }
                                                property bool isToday: {
                                                    var now = new Date()
                                                    return dayNum === now.getDate() && dropdown.viewMonth === now.getMonth() && dropdown.viewYear === now.getFullYear()
                                                }

                                                width: 32
                                                height: 32
                                                radius: isToday ? 16 : 0
                                                color: isToday ? "#cba6f7" : "transparent"

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

                        Item {
                            id: musicPage
                            width: root.dropdownWidth
                            height: parent.height
                            focus: root.activePanel === 2

                            onFocusChanged: if (focus) forceActiveFocus()

                            Keys.onSpacePressed: { musicPlayProc.running = true; event.accepted = true }
                            Keys.onLeftPressed: { root.seekRelative(-10); event.accepted = true }
                            Keys.onRightPressed: { root.seekRelative(10); event.accepted = true }
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_J) {
                                    root.seekRelative(-10)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_K) {
                                    root.seekRelative(10)
                                    event.accepted = true
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 20

                                Column {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: "Now Playing"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: "#6c7086"
                                    }

                                    Text {
                                        text: root.musicFile || "Nothing playing"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                        color: "#cdd6f4"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        visible: root.musicPlayer !== ""
                                        text: root.musicPlayer
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 12
                                        color: "#6c7086"
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    property bool dragging: false
                                    property int previewPosition: 0

                                    Rectangle {
                                        id: progressBar
                                        width: parent.width
                                        height: 6
                                        color: "#45475a"
                                        radius: 3

                                        Rectangle {
                                            width: root.musicLength > 0 ? parent.width * ((parent.parent.dragging ? parent.parent.previewPosition : root.musicPosition) / root.musicLength) : 0
                                            height: parent.height
                                            color: "#cba6f7"
                                            radius: 3
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: mouse => {
                                                if (root.musicLength > 0) {
                                                    parent.parent.dragging = true
                                                    parent.parent.previewPosition = Math.round(mouse.x / width * root.musicLength)
                                                }
                                            }
                                            onPositionChanged: mouse => {
                                                if (pressed && root.musicLength > 0) {
                                                    parent.parent.previewPosition = Math.max(0, Math.min(root.musicLength, Math.round(mouse.x / width * root.musicLength)))
                                                }
                                            }
                                            onReleased: {
                                                if (parent.parent.dragging && root.musicLength > 0) {
                                                    root.musicPosition = parent.parent.previewPosition
                                                    root.seekTo(parent.parent.previewPosition)
                                                }
                                                parent.parent.dragging = false
                                            }
                                        }
                                    }

                                    Item {
                                        width: parent.width
                                        height: 16

                                        Text {
                                            anchors.left: parent.left
                                            text: root.formatTime(parent.parent.dragging ? parent.parent.previewPosition : root.musicPosition)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            color: "#6c7086"
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            text: root.formatTime(root.musicLength)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            color: "#6c7086"
                                        }
                                    }
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 24
                                    height: 56

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰒮"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 28
                                        color: prevMusicHover.hovered ? "#cba6f7" : "#a6adc8"
                                        HoverHandler { id: prevMusicHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: musicPrevProc.running = true }
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 56
                                        height: 56
                                        radius: 28
                                        color: playMusicHover.hovered ? "#cba6f7" : "#45475a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.musicPlaying ? "󰏤" : "󰐊"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 28
                                            color: playMusicHover.hovered ? "#1e1e2e" : "#cdd6f4"
                                        }

                                        HoverHandler { id: playMusicHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: musicPlayProc.running = true }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰒭"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 28
                                        color: nextMusicHover.hovered ? "#cba6f7" : "#a6adc8"
                                        HoverHandler { id: nextMusicHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: musicNextProc.running = true }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 40
                                    radius: 4
                                    color: browseHover.hovered ? "#353548" : "#2a2a3c"

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: "󰝚"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 16
                                            color: "#cdd6f4"
                                        }

                                        Text {
                                            text: "Browse Library"
                                            font.family: "Space Grotesk"
                                            font.pixelSize: 12
                                            color: "#cdd6f4"
                                        }
                                    }

                                    HoverHandler { id: browseHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: ncmpcppProc.running = true }
                                }

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
            id: controlPanel
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.right: true
            margins.top: root.barHeight
            implicitWidth: 280
            implicitHeight: 220
            color: "#1e1e2e"
            exclusionMode: ExclusionMode.Ignore
            visible: root.controlPanelVisible

            Timer {
                id: controlPanelCloseTimer
                interval: 50
                onTriggered: root.tryCloseControlPanel()
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.controlPanelHovered = true
                onExited: { root.controlPanelHovered = false; controlPanelCloseTimer.restart() }

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
                            text: root.sysMuted ? "󰖁" : "󰕾"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: root.sysMuted ? "#f38ba8" : "#f5c2e7"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            height: 6
                            color: "#45475a"

                            Rectangle {
                                width: parent.width * (root.sysVolume / 100)
                                height: parent.height
                                color: root.sysMuted ? "#f38ba8" : "#f5c2e7"
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
                                    text: root.batteryIcon(root.sysBattery, root.sysCharging)
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
                        spacing: 6

                        Rectangle {
                            width: 36
                            height: parent.height
                            radius: 4
                            color: root.vpnConnected ? "#a6e3a1" : "#45475a"

                            Text {
                                anchors.centerIn: parent
                                text: root.vpnConnected ? "󰌆" : "󰌊"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: root.vpnConnected ? "#1e1e2e" : "#6c7086"
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (root.vpnConnected) {
                                        vpnDisconnectProc.running = true
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: [
                                { code: "GB", label: "UK" },
                                { code: "CH", label: "CH" },
                                { code: "AL", label: "AL" },
                                { code: "NL", label: "NL" }
                            ]

                            Rectangle {
                                id: vpnBtn
                                required property var modelData
                                width: (parent.width - 36 - 24) / 4
                                height: parent.height
                                radius: 4
                                color: (root.vpnConnected && root.vpnCountry === modelData.label) ? "#89b4fa" : (vpnBtnHover.hovered ? "#353548" : "#2a2a3c")

                                Text {
                                    anchors.centerIn: parent
                                    text: vpnBtn.modelData.label
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: (root.vpnConnected && root.vpnCountry === vpnBtn.modelData.label) ? "#1e1e2e" : "#cdd6f4"
                                }

                                HoverHandler { id: vpnBtnHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        vpnConnectProc.command = ["protonvpn", "connect", "--country", vpnBtn.modelData.code]
                                        vpnConnectProc.running = true
                                    }
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
                                property bool confirming: false
                                width: (parent.width - 24) / 4
                                height: parent.height
                                color: confirming ? actionBtn.modelData.accent : (actionHover.hovered ? "#353548" : "#2a2a3c")

                                Text {
                                    anchors.centerIn: parent
                                    text: actionBtn.confirming ? "?" : actionBtn.modelData.icon
                                    font.family: actionBtn.confirming ? "Space Grotesk" : "JetBrainsMono Nerd Font"
                                    font.pixelSize: actionBtn.confirming ? 14 : 16
                                    font.weight: actionBtn.confirming ? Font.Bold : Font.Normal
                                    color: actionBtn.confirming ? "#1e1e2e" : (actionHover.hovered ? actionBtn.modelData.accent : "#a6adc8")
                                }

                                Timer {
                                    id: confirmTimer
                                    interval: 2000
                                    onTriggered: actionBtn.confirming = false
                                }

                                HoverHandler {
                                    id: actionHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        if (actionBtn.confirming) {
                                            root.controlPanelVisible = false
                                            actionProc.command = ["sh", "-c", actionBtn.modelData.cmd]
                                            actionProc.running = true
                                            actionBtn.confirming = false
                                        } else {
                                            actionBtn.confirming = true
                                            confirmTimer.restart()
                                        }
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
}
