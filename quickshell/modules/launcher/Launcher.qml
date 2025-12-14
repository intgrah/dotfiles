import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool visible_: false
    property string query: ""
    property int selectedIndex: 0
    property var allApps: []
    property var filteredApps: []
    property string iconTheme: "hicolor"  // fallback theme

    function show() {
        visible_ = true
        query = ""
        selectedIndex = 0
        filterApps()
    }

    function hide() {
        visible_ = false
        query = ""
    }

    function filterApps() {
        if (query === "") {
            filteredApps = allApps.slice(0, 50)
        } else {
            var q = query.toLowerCase()
            filteredApps = allApps.filter(app => 
                app.name.toLowerCase().startsWith(q)
            ).sort((a, b) => a.name.localeCompare(b.name)).slice(0, 50)
        }
        selectedIndex = Math.min(selectedIndex, Math.max(0, filteredApps.length - 1))
    }

    function launch(app) {
        hide()
        launchProc.command = ["hyprctl", "dispatch", "exec", app.exec]
        launchProc.running = true
    }

    Process { id: launchProc }

    // Get current icon theme
    Process {
        id: getThemeProc
        command: ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"]
        stdout: SplitParser {
            onRead: data => {
                var theme = data.trim().replace(/'/g, "")
                if (theme) root.iconTheme = theme
            }
        }
        running: true
    }

    // Load apps on startup
    Process {
        id: loadAppsProc
        command: ["sh", "-c", `
            find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | while read f; do
                type=$(grep -m1 '^Type=' "$f" | cut -d= -f2-)
                [ "$type" != "Application" ] && continue
                nodisplay=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
                [ "$nodisplay" = "true" ] && continue
                onlyshow=$(grep -m1 '^OnlyShowIn=' "$f")
                [ -n "$onlyshow" ] && continue
                name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
                # Skip runtime entries like "Electron 34", "Java 25"
                echo "$name" | grep -qE '^(Electron|Java|OpenJDK) [0-9]+' && continue
                exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g')
                [ -z "$name" ] || [ -z "$exec" ] && continue
                icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
                generic=$(grep -m1 '^GenericName=' "$f" | cut -d= -f2-)
                terminal=$(grep -m1 '^Terminal=' "$f" | cut -d= -f2-)
                echo "$name|||$exec|||$icon|||$generic|||$terminal"
            done | sort -u
        `]
        stdout: SplitParser {
            onRead: data => {
                // SplitParser calls onRead for each line
                var parts = data.trim().split("|||")
                if (parts.length >= 3 && parts[0] && parts[1]) {
                    var app = {
                        name: parts[0],
                        exec: parts[4] === "true" ? "kitty " + parts[1] : parts[1],
                        icon: parts[2] || "",
                        generic: parts[3] || ""
                    }
                    root.allApps = root.allApps.concat([app])
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.filterApps()
            }
        }
        running: true
    }

    // File-based toggle - checks for unique timestamp written by keybind
    property string lastToggle: ""
    
    Timer {
        interval: 30
        running: true
        repeat: true
        onTriggered: toggleCheckProc.running = true
    }
    
    Process {
        id: toggleCheckProc
        command: ["cat", "/tmp/quickshell-launcher-toggle"]
        stdout: SplitParser {
            onRead: data => {
                var content = data.trim()
                if (content && content !== root.lastToggle) {
                    if (root.lastToggle !== "") {  // Skip first read
                        if (root.visible_) root.hide()
                        else root.show()
                    }
                    root.lastToggle = content
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launcherWindow
            required property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            visible: root.visible_
            focusable: true

            onVisibleChanged: {
                if (visible) {
                    searchInput.text = ""
                    searchInput.forceActiveFocus()
                }
            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            // Centered launcher box
            Rectangle {
                anchors.centerIn: parent
                width: 600
                height: 400
                color: "#1e1e2e"
                radius: 0

                // Prevent clicks from closing
                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Search input
                    Rectangle {
                        width: parent.width
                        height: 44
                        color: "#2a2a3c"
                        radius: 0

                        HoverHandler {
                            cursorShape: Qt.IBeamCursor
                        }
                        
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.margins: 12
                            color: "#cdd6f4"
                            font.family: "Space Grotesk"
                            font.pixelSize: 16
                            clip: true
                            cursorVisible: activeFocus

                            property string placeholderText: "Search applications..."

                            Text {
                                anchors.fill: parent
                                text: searchInput.placeholderText
                                color: "#6c7086"
                                font: searchInput.font
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            onTextChanged: {
                                root.query = text
                                root.filterApps()
                            }

                            Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                            Keys.onDownPressed: root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + 1)
                            Keys.onReturnPressed: {
                                if (root.filteredApps.length > 0) {
                                    root.launch(root.filteredApps[root.selectedIndex])
                                }
                            }
                            Keys.onEscapePressed: root.hide()
                        }
                    }

                    // Results list
                    ListView {
                        id: resultsList
                        width: parent.width
                        height: parent.height - 56
                        clip: true
                        model: root.filteredApps
                        currentIndex: root.selectedIndex

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: resultsList.width
                            height: 48
                            color: index === root.selectedIndex ? "#353548" : "transparent"
                            radius: 0

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // App icon
                                Item {
                                    width: 32
                                    height: 32
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        source: {
                                            var icon = modelData.icon
                                            if (!icon) return ""
                                            if (icon.startsWith("/")) return "file://" + icon
                                            // Try hicolor first (where app icons live)
                                            return "file:///usr/share/icons/hicolor/48x48/apps/" + icon + ".png"
                                        }
                                        sourceSize: Qt.size(32, 32)
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        cache: true

                                        onStatusChanged: {
                                            if (status === Image.Error) tryFallback()
                                        }

                                        property int fallbackIndex: 0
                                        property var fallbackPaths: {
                                            var icon = modelData.icon
                                            if (!icon || icon.startsWith("/")) return []
                                            return [
                                                "/usr/share/icons/hicolor/scalable/apps/" + icon + ".svg",
                                                "/usr/share/icons/hicolor/64x64/apps/" + icon + ".png",
                                                "/usr/share/icons/hicolor/128x128/apps/" + icon + ".png",
                                                "/usr/share/icons/hicolor/32x32/apps/" + icon + ".png",
                                                "/usr/share/icons/hicolor/256x256/apps/" + icon + ".png",
                                                "/usr/share/pixmaps/" + icon + ".png",
                                                "/usr/share/pixmaps/" + icon + ".svg",
                                                "/usr/share/pixmaps/" + icon
                                            ]
                                        }

                                        function tryFallback() {
                                            if (fallbackIndex < fallbackPaths.length) {
                                                source = "file://" + fallbackPaths[fallbackIndex]
                                                fallbackIndex++
                                            }
                                        }
                                    }

                                    // Fallback letter
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#45475a"
                                        radius: 4
                                        visible: appIcon.status === Image.Error || appIcon.status === Image.Null

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name.charAt(0).toUpperCase()
                                            font.family: "Space Grotesk"
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            color: "#cba6f7"
                                        }
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 14
                                        font.weight: index === root.selectedIndex ? Font.Bold : Font.Normal
                                        color: "#cdd6f4"
                                    }

                                    Text {
                                        text: modelData.generic || ""
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 11
                                        color: "#6c7086"
                                        visible: modelData.generic
                                    }
                                }
                            }

                        }

                        // Scroll to selected
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }
            }
        }
    }
}
