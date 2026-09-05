import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: navRoot

    property int currentIndex: 0
    signal tabSelected(int index)

    readonly property var tabs: [
        { name: i18nc("@title:tab", "COUNTDOWN"), icon: "chronometer" },
        { name: i18nc("@title:tab", "CLOCK"), icon: "clock" },
        { name: i18nc("@title:tab", "STOPWATCH"), icon: "chronometer-start" }
    ]

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    radius: 8
    color: root.themeColors.subCardBg
    border.width: 1
    border.color: root.themeColors.cardBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 2

        Repeater {
            model: navRoot.tabs

            Item {
                id: tabItem
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property bool isSelected: navRoot.currentIndex === index
                readonly property bool isHovered: tabMouse.containsMouse

                // Active pill background
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: tabItem.isSelected
                        ? (root.isSystemTheme ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22) : Qt.rgba(0.18, 0.18, 0.18, 0.95))
                        : (tabItem.isHovered ? root.themeColors.subCardHover : "transparent")
                    border.width: tabItem.isSelected ? 1 : 0
                    border.color: tabItem.isSelected ? root.themeColors.cardBorderHover : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        source: modelData.icon
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        color: tabItem.isSelected ? root.themeColors.textPrimary : (tabItem.isHovered ? root.themeColors.textSecondary : root.themeColors.textMuted)
                    }

                    Text {
                        text: modelData.name
                        color: tabItem.isSelected ? root.themeColors.textPrimary : (tabItem.isHovered ? root.themeColors.textSecondary : root.themeColors.textMuted)
                        font.family: "sans-serif"
                        font.weight: tabItem.isSelected ? Font.Bold : Font.DemiBold
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                        font.capitalization: Font.AllUppercase
                    }
                }

                Accessible.name: modelData.name
                Accessible.role: Accessible.Button
                Accessible.checkable: true
                Accessible.checked: tabItem.isSelected

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        navRoot.currentIndex = index;
                        navRoot.tabSelected(index);
                    }
                }
            }
        }
    }
}
