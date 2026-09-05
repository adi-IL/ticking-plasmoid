import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isHorizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool isVerticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inPanel: isHorizontalPanel || isVerticalPanel
    readonly property bool showBadge: isHorizontalPanel && Plasmoid.configuration.showPanelBadge !== false

    Layout.minimumWidth: isHorizontalPanel
        ? compactLayout.implicitWidth + Kirigami.Units.smallSpacing * 2
        : (isVerticalPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.gridUnit * 4)
    Layout.minimumHeight: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.gridUnit * 4
    Layout.preferredWidth: isHorizontalPanel
        ? compactLayout.implicitWidth + Kirigami.Units.smallSpacing * 2
        : (isVerticalPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 5)
    Layout.preferredHeight: inPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 5

    Accessible.name: root.milestoneTitle
    Accessible.description: root.toolTipSubText
    Accessible.role: Accessible.Button

    Kirigami.ShadowedRectangle {
        anchors.fill: parent
        anchors.margins: inPanel ? 1 : 2
        radius: 6
        color: inPanel
            ? (mouseArea.containsMouse
                ? (root.isSystemTheme
                    ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
                    : Qt.rgba(0.18, 0.18, 0.18, 0.7))
                : "transparent")
            : (mouseArea.containsMouse ? root.themeColors.subCardHover : root.themeColors.subCardBg)
        border.width: inPanel ? 0 : 1
        border.color: mouseArea.containsMouse ? root.themeColors.cardBorderHover : root.themeColors.cardBorder

        RowLayout {
            id: compactLayout
            anchors.centerIn: parent
            spacing: 6

            Kirigami.Icon {
                source: "org.adi_il.ticking"
                fallback: "chronometer"
                Layout.preferredWidth: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                color: root.themeColors.accentColor
            }

            Text {
                text: root.countdownData.isExpired
                    ? i18nc("@info:status compact panel", "done")
                    : (root.countdownData.days + "d " + root.countdownData.hours + "h")
                color: root.themeColors.textPrimary
                font.family: "monospace"
                font.weight: Font.Bold
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                font.features: { "tnum": 1 }
                visible: compactRoot.showBadge
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
