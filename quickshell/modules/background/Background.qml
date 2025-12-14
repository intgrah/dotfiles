import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: "#1e1e2e"

        Image {
            anchors.fill: parent
            source: "../../assets/bg.png"
            fillMode: Image.PreserveAspectCrop
        }
    }
}
