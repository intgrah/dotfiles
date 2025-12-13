import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

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

        color: Appearance.colors.background

        Image {
            id: backgroundImage
            anchors.fill: parent
            source: "../../assets/bg.png"
            fillMode: Image.PreserveAspectCrop
        }
    }
}
