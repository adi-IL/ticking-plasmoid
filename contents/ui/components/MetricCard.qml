import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: cardRoot

    property string value: "00"
    property string unit: "UNIT"
    property color accentColor: "#00E599"
    property bool isHighlighted: false
    property bool isCompact: false

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: isCompact ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.gridUnit * 4
    Layout.minimumHeight: isCompact ? Kirigami.Units.gridUnit * 3.5 : Kirigami.Units.gridUnit * 5

    radius: 8
    color: mouseArea.containsMouse ? Qt.rgba(0.12, 0.12, 0.12, 0.95) : Qt.rgba(0.06, 0.06, 0.06, 0.85)

    border.width: 1
    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

    shadow.size: mouseArea.containsMouse ? 12 : 4
    shadow.color: mouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0, 0, 0, 0.3)
    shadow.yOffset: 2

    // Top edge sub-pixel highlight (Vercel style specular line)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.15)
        radius: 1
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: isCompact ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing
        spacing: 2

        // Value text
        Text {
            id: valueText
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: cardRoot.value
            color: cardRoot.isHighlighted ? cardRoot.accentColor : "#EDEDED"
            font.family: "monospace"
            font.weight: Font.Bold
            font.pixelSize: isCompact ? Math.max(14, cardRoot.height * 0.42) : Math.max(18, cardRoot.height * 0.48)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.features: { "tnum": 1 }
            fontSizeMode: Text.Fit
            minimumPixelSize: 10
        }

        // Unit label
        Text {
            Layout.fillWidth: true
            text: cardRoot.unit
            color: mouseArea.containsMouse ? "#A1A1AA" : "#71717A"
            font.family: "sans-serif"
            font.weight: Font.DemiBold
            font.pixelSize: isCompact ? 8 : 10
            font.letterSpacing: 1.2
            font.capitalization: Font.AllUppercase
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
