import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: cardRoot

    property string value: "00"
    property string unit: "UNIT"
    property color accentColor: "#00E599"
    property bool isHighlighted: false
    property bool isCompact: cardRoot.width < Kirigami.Units.gridUnit * 4.2

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: isCompact ? Kirigami.Units.gridUnit * 2.5 : Kirigami.Units.gridUnit * 3.2
    Layout.minimumHeight: isCompact ? Kirigami.Units.gridUnit * 3.2 : Kirigami.Units.gridUnit * 4.5

    radius: 8
    color: mouseArea.containsMouse ? root.themeColors.subCardHover : root.themeColors.subCardBg

    Behavior on color { ColorAnimation { duration: 150 } }

    border.width: 1
    border.color: mouseArea.containsMouse ? root.themeColors.cardBorderHover : root.themeColors.cardBorder

    Behavior on border.color { ColorAnimation { duration: 150 } }

    shadow.size: mouseArea.containsMouse ? 12 : 4
    shadow.color: root.isSystemTheme ? Qt.rgba(0, 0, 0, 0.15) : (mouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0, 0, 0, 0.3))
    shadow.yOffset: 2

    // Top edge sub-pixel highlight (Vercel style specular line)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 0.5; color: mouseArea.containsMouse ? root.themeColors.specularGlint : Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
        }
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
            color: cardRoot.isHighlighted ? cardRoot.accentColor : root.themeColors.textPrimary
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
            color: mouseArea.containsMouse ? root.themeColors.textSecondary : root.themeColors.textMuted
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
