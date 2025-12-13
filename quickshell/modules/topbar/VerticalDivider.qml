import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    property bool fillHeight: true
    property int fixedHeight: 16

    Layout.preferredWidth: 1
    Layout.fillHeight: fillHeight
    Layout.preferredHeight: fillHeight ? -1 : fixedHeight
    Layout.alignment: fillHeight ? Qt.AlignTop : Qt.AlignVCenter
    Layout.topMargin: fillHeight ? 12 : 0
    Layout.bottomMargin: fillHeight ? 12 : 0
    Layout.leftMargin: 12
    Layout.rightMargin: 12

    color: Appearance.colors.border
    opacity: 0.5
}

