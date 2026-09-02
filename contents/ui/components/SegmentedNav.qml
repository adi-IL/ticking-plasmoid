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
    Layout.preferredHeight: 36
    radius: 8
    color: Qt.rgba(0.06, 0.06, 0.06, 0.8)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)

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
                        ? Qt.rgba(0.18, 0.18, 0.18, 0.95)
                        : (tabItem.isHovered ? Qt.rgba(0.12, 0.12, 0.12, 0.6) : "transparent")
                    border.width: tabItem.isSelected ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.12)

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
                        color: tabItem.isSelected ? "#FFFFFF" : (tabItem.isHovered ? "#D4D4D8" : "#71717A")
                    }

                    Text {
                        text: modelData.name
                        color: tabItem.isSelected ? "#FFFFFF" : (tabItem.isHovered ? "#D4D4D8" : "#71717A")
                        font.family: "sans-serif"
                        font.weight: tabItem.isSelected ? Font.Bold : Font.DemiBold
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                        font.capitalization: Font.AllUppercase
                    }
                }

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
