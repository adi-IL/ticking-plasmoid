import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: navRoot

    property int currentIndex: 0
    property var themeColors: (typeof root !== "undefined" && root && root.themeColors) ? root.themeColors : ({
        subCardBg: Kirigami.Theme.backgroundColor,
        subCardHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.09),
        cardBorder: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12),
        cardBorderHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.22),
        textPrimary: Kirigami.Theme.textColor,
        textSecondary: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.75),
        textMuted: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
    })
    property bool isSystemTheme: (typeof root !== "undefined" && root) ? root.isSystemTheme : true
    signal tabSelected(int index)

    readonly property var tabs: [
        { name: i18nc("@title:tab", "COUNTDOWN"), icon: "chronometer" },
        { name: i18nc("@title:tab", "CLOCK"), icon: "clock" },
        { name: i18nc("@title:tab", "STOPWATCH"), icon: "chronometer-start" }
    ]

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    radius: 8
    color: navRoot.themeColors.subCardBg
    border.width: 1
    border.color: navRoot.themeColors.cardBorder

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
                        ? (navRoot.isSystemTheme ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22) : Qt.rgba(0.18, 0.18, 0.18, 0.95))
                        : (tabItem.isHovered ? navRoot.themeColors.subCardHover : "transparent")
                    border.width: tabItem.isSelected ? 1 : 0
                    border.color: tabItem.isSelected ? navRoot.themeColors.cardBorderHover : "transparent"

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
                        color: tabItem.isSelected ? navRoot.themeColors.textPrimary : (tabItem.isHovered ? navRoot.themeColors.textSecondary : navRoot.themeColors.textMuted)
                    }

                    Text {
                        text: modelData.name
                        color: tabItem.isSelected ? navRoot.themeColors.textPrimary : (tabItem.isHovered ? navRoot.themeColors.textSecondary : navRoot.themeColors.textMuted)
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
