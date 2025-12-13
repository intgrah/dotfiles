import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color fillColor: "#1a1a1c"
    property real angle: 0          // rotation angle
    property real cutSize: 15       // corner cut size
    property string cutCorner: "topRight"  // which corner to cut

    default property alias content: contentContainer.data

    Shape {
        id: shape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            id: shapePath
            fillColor: root.fillColor
            strokeColor: "transparent"

            property real w: root.width
            property real h: root.height
            property real c: root.cutSize

            startX: root.cutCorner === "topLeft" ? c : 0
            startY: 0

            PathLine { 
                x: root.cutCorner === "topRight" ? shapePath.w - shapePath.c : shapePath.w
                y: 0 
            }
            PathLine { 
                x: shapePath.w
                y: root.cutCorner === "topRight" ? shapePath.c : 0
            }
            PathLine { 
                x: shapePath.w
                y: root.cutCorner === "bottomRight" ? shapePath.h - shapePath.c : shapePath.h
            }
            PathLine { 
                x: root.cutCorner === "bottomRight" ? shapePath.w - shapePath.c : shapePath.w
                y: shapePath.h
            }
            PathLine { 
                x: root.cutCorner === "bottomLeft" ? shapePath.c : 0
                y: shapePath.h
            }
            PathLine { 
                x: 0
                y: root.cutCorner === "bottomLeft" ? shapePath.h - shapePath.c : shapePath.h
            }
            PathLine { 
                x: 0
                y: root.cutCorner === "topLeft" ? shapePath.c : 0
            }
            PathLine { 
                x: root.cutCorner === "topLeft" ? shapePath.c : 0
                y: 0
            }
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: 12
    }

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height / 2
        angle: root.angle
    }
}
