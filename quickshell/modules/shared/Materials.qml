pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Void - the background, pure black
    readonly property color void_: "#000000"

    // Accent - vermillion red for active states
    readonly property color accent: "#c74545"

    // Text colors
    readonly property color textPrimary: "#e8e8e8"
    readonly property color textSecondary: "#888888"
    readonly property color textMuted: "#555555"

    // OBSIDIAN GLASS - dark, polished, reflective hint
    readonly property QtObject obsidian: QtObject {
        readonly property color base: "#0c0c0e"
        readonly property color highlight: "#1a1a1f"
        readonly property color edge: "#ffffff"
        readonly property real edgeOpacity: 0.08
    }

    // WEATHERED BRONZE - aged, warm, patina
    readonly property QtObject bronze: QtObject {
        readonly property color base: "#1f1815"
        readonly property color patina: "#1a1f1c"
        readonly property color highlight: "#2a221d"
        readonly property color edge: "#3d3530"
        readonly property real edgeOpacity: 0.3
    }

    // BRUSHED STEEL - industrial, cold, horizontal grain
    readonly property QtObject steel: QtObject {
        readonly property color base: "#22262a"
        readonly property color grain: "#282c32"
        readonly property color edge: "#3a4048"
        readonly property real edgeOpacity: 0.4
    }

    // RAW CONCRETE - brutalist, heavy, grainy
    readonly property QtObject concrete: QtObject {
        readonly property color base: "#2d2d2d"
        readonly property color variation: "#333333"
        readonly property color edge: "#404040"
        readonly property real edgeOpacity: 0.2
    }

    // Animation durations
    readonly property int animFast: 100
    readonly property int animNormal: 200
    readonly property int animSlow: 350
}


