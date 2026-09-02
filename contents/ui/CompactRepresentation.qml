import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                 || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: inPanel ? compactLayout.implicitWidth + Kirigami.Units.smallSpacing * 2 : Kirigami.Units.gridUnit * 4
    Layout.minimumHeight: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.gridUnit * 4
    Layout.preferredWidth: inPanel ? compactLayout.implicitWidth + Kirigami.Units.smallSpacing * 2 : Kirigami.Units.gridUnit * 5
    Layout.preferredHeight: inPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 5

    Kirigami.ShadowedRectangle {
        anchors.fill: parent
        anchors.margins: inPanel ? 1 : 2
        radius: 6
        color: mouseArea.containsMouse ? Qt.rgba(0.2, 0.2, 0.2, 0.8) : Qt.rgba(0.08, 0.08, 0.08, 0.6)
        border.width: 1
        border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
            id: compactLayout
            anchors.centerIn: parent
            spacing: 6

            Kirigami.Icon {
                source: "chronometer"
                Layout.preferredWidth: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                color: Plasmoid.configuration.accentColor || "#00E599"
            }

            Text {
                text: root.countdownData.days + "d " + root.countdownData.hours + "h"
                color: "#FFFFFF"
                font.family: "monospace"
                font.weight: Font.Bold
                font.pixelSize: inPanel ? 11 : 13
                font.features: { "tnum": 1 }
                visible: inPanel
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Plasmoid.expanded = !Plasmoid.expanded
        }
    }
}
