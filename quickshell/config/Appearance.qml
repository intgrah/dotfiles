pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Global UI state
    property bool controlCenterOpen: false

    readonly property Colors colors: Colors {}
    readonly property Rounding rounding: Rounding {}
    readonly property Spacing spacing: Spacing {}
    readonly property Padding padding: Padding {}
    readonly property FontStuff font: FontStuff {}
    readonly property Anim anim: Anim {}

    component Colors: QtObject {
        readonly property color background: "#0A0A0B"
        readonly property color surface: "#1A1A1C"
        readonly property color surfaceHover: Qt.lighter(surface, 1.1)
        readonly property color accent: "#C74545"
        readonly property color secondary: "#5A8A7B"
        readonly property color textPrimary: "#F5F2E8"
        readonly property color textSecondary: "#B8B5A6"
        readonly property color border: "#33B8B5A6"
        readonly property color shadow: Qt.rgba(0, 0, 0, 0.3)
        readonly property color vermillion: "#C74545"
        readonly property color jadeGreen: "#5A8A7B"
        readonly property color ricePaper: "#F5F2E8"
    }

    component Rounding: QtObject {
        // No rounding for flush edges
        readonly property int small: 0
        readonly property int normal: 0
        readonly property int large: 0
        readonly property int full: 0
    }

    component Spacing: QtObject {
        // Generous spacing following Chinese painting principles
        readonly property int tiny: 4
        readonly property int small: 8
        readonly property int normal: 16
        readonly property int large: 24
        readonly property int huge: 32
    }

    component Padding: QtObject {
        readonly property int tiny: 6
        readonly property int small: 10
        readonly property int normal: 14
        readonly property int large: 20
        readonly property int huge: 28
    }

    component FontFamily: QtObject {
        readonly property string primary: "Fira Code"
    }

    component FontSize: QtObject {
        readonly property int tiny: 11
        readonly property int small: 13
        readonly property int normal: 15
        readonly property int large: 18
        readonly property int huge: 24
        readonly property int display: 32
    }

    component FontWeight: QtObject {
        readonly property int light: Font.Light
        readonly property int normal: Font.Normal
        readonly property int medium: Font.Medium
        readonly property int bold: Font.Bold
    }

    component FontStuff: QtObject {
        readonly property FontFamily family: FontFamily {}
        readonly property FontSize size: FontSize {}
        readonly property FontWeight weight: FontWeight {}
    }

    component AnimCurves: QtObject {
        // Animation curves
        readonly property list<real> linear: [0, 0, 1, 1]  // Snappy, no easing
        readonly property list<real> gentle: [0.4, 0, 0.2, 1, 1, 1]
        readonly property list<real> swift: [0.25, 0.1, 0.25, 1, 1, 1]
        readonly property list<real> spring: [0.175, 0.885, 0.32, 1.275, 1, 1]
    }

    component AnimDurations: QtObject {
        readonly property int instant: 100
        readonly property int quick: 150
        readonly property int normal: 200
        readonly property int slow: 350
        readonly property int gentle: 500
    }

    component Anim: QtObject {
        readonly property AnimCurves curves: AnimCurves {}
        readonly property AnimDurations durations: AnimDurations {}
    }
}
