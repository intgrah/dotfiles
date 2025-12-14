import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool visible_: false
    property string query: ""
    property int selectedIndex: 0
    property var allItems: []
    property var filteredItems: []
    property string lastToggle: ""

    function show() {
        visible_ = true
        query = ""
        selectedIndex = 0
        loadClipboard()
    }

    function hide() {
        visible_ = false
        query = ""
    }

    function loadClipboard() {
        allItems = []
        cliphistProc.running = true
    }

    // Fuzzy match: "abc" matches "1a1b1c1"
    function fuzzyMatch(text, pattern) {
        if (!pattern) return true
        text = text.toLowerCase()
        pattern = pattern.toLowerCase()
        var ti = 0
        for (var pi = 0; pi < pattern.length; pi++) {
            var found = false
            while (ti < text.length) {
                if (text[ti] === pattern[pi]) {
                    found = true
                    ti++
                    break
                }
                ti++
            }
            if (!found) return false
        }
        return true
    }

    function filterItems() {
        if (query === "") {
            filteredItems = allItems.slice(0, 50)
        } else {
            filteredItems = allItems.filter(item => fuzzyMatch(item.text, query)).slice(0, 50)
        }
        selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1))
    }

    function selectItem(item) {
        hide()
        // Decode and copy to clipboard
        selectProc.command = ["sh", "-c", "printf '%s' '" + item.id + "' | cliphist decode | wl-copy"]
        selectProc.running = true
    }

    Process { id: selectProc; command: [] }

    // Load clipboard history
    Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line) {
                    // Format: "id\ttext"
                    var tabIdx = line.indexOf("\t")
                    if (tabIdx > 0) {
                        root.allItems = root.allItems.concat([{
                            id: line.substring(0, tabIdx),
                            text: line.substring(tabIdx + 1)
                        }])
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.filterItems()
            }
        }
    }

    // File-based toggle
    Timer {
        interval: 30
        running: true
        repeat: true
        onTriggered: toggleCheckProc.running = true
    }

    Process {
        id: toggleCheckProc
        command: ["cat", "/tmp/quickshell-clipboard-toggle"]
        stdout: SplitParser {
            onRead: data => {
                var content = data.trim()
                if (content && content !== root.lastToggle) {
                    if (root.lastToggle !== "") {
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
            id: clipboardWindow
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

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Rectangle {
                anchors.centerIn: parent
                width: 600
                height: 400
                color: "#1e1e2e"

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: parent.width
                        height: 44
                        color: "#2a2a3c"

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

                            Text {
                                anchors.fill: parent
                                text: "Search clipboard..."
                                color: "#6c7086"
                                font: searchInput.font
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            onTextChanged: {
                                root.query = text
                                root.filterItems()
                            }

                            Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                            Keys.onDownPressed: root.selectedIndex = Math.min(root.filteredItems.length - 1, root.selectedIndex + 1)
                            Keys.onReturnPressed: {
                                if (root.filteredItems.length > 0) {
                                    root.selectItem(root.filteredItems[root.selectedIndex])
                                }
                            }
                            Keys.onEscapePressed: root.hide()
                        }
                    }

                    ListView {
                        id: resultsList
                        width: parent.width
                        height: parent.height - 56
                        clip: true
                        model: root.filteredItems
                        currentIndex: root.selectedIndex

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: resultsList.width
                            height: 40
                            color: index === root.selectedIndex ? "#353548" : "transparent"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.text
                                font.family: "Space Grotesk"
                                font.pixelSize: 13
                                color: "#cdd6f4"
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                        }

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }
            }
        }
    }
}
