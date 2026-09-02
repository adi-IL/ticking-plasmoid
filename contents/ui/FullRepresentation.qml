import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "./components" as Components

Item {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 14
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: Kirigami.Units.gridUnit * 16

    // Glass HUD Container
    Kirigami.ShadowedRectangle {
        id: hudCard
        anchors.fill: parent
        anchors.margins: 4
        radius: 12

        color: Qt.rgba(0.04, 0.04, 0.04, Plasmoid.configuration.translucency || 0.88)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        shadow.size: 16
        shadow.color: Qt.rgba(0, 0, 0, 0.7)
        shadow.yOffset: 4

        // Top specular line (Vercel physical edge glow)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Qt.rgba(1, 1, 1, 0.25)
            radius: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Live status indicator pill
                Kirigami.ShadowedRectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: liveRow.implicitWidth + 14
                    radius: 11
                    color: Qt.rgba(0.0, 0.9, 0.6, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(0.0, 0.9, 0.6, 0.3)

                    RowLayout {
                        id: liveRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Pulsing Green Dot
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Plasmoid.configuration.accentColor || "#00E599"

                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            text: i18nc("@label:status", "LIVE")
                            color: Plasmoid.configuration.accentColor || "#00E599"
                            font.family: "sans-serif"
                            font.weight: Font.Bold
                            font.pixelSize: 9
                            font.letterSpacing: 1.1
                        }
                    }
                }

                // Milestone Headline
                Text {
                    text: Plasmoid.configuration.customTitle || "OCTOBER 25, 2026 HORIZON"
                    color: "#D4D4D8"
                    font.family: "sans-serif"
                    font.weight: Font.DemiBold
                    font.pixelSize: 11
                    font.letterSpacing: 1.2
                    font.capitalization: Font.AllUppercase
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Settings icon button
                Kirigami.Icon {
                    source: "configure"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: settingsMouse.containsMouse ? "#FFFFFF" : "#71717A"

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: plasmoid.action("configure").trigger()
                    }
                }
            }

            // Main View Area (Dynamic Tab switching)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.CountdownView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 0
                    timeData: root.countdownData
                    showMilliseconds: Plasmoid.configuration.showMilliseconds
                    showProgress: Plasmoid.configuration.showProgress
                    accentColor: Plasmoid.configuration.accentColor || "#00E599"
                }

                Components.ClockView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 1
                    clockData: root.clockData
                    accentColor: Plasmoid.configuration.accentColor || "#00E599"
                }

                Components.StopwatchView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 2
                    stopwatchData: root.stopwatchData
                    accentColor: Plasmoid.configuration.accentColor || "#00E599"
                    onStartRequested: root.startStopwatch()
                    onPauseRequested: root.pauseStopwatch()
                    onResetRequested: root.resetStopwatch()
                    onLapRequested: root.lapStopwatch()
                }
            }

            // Bottom Segmented Tab Navigation
            Components.SegmentedNav {
                Layout.fillWidth: true
                currentIndex: fullRoot.activeTabIndex
                onTabSelected: index => {
                    fullRoot.activeTabIndex = index;
                    Plasmoid.configuration.activeTab = index;
                }
            }
        }
    }

    property int activeTabIndex: Plasmoid.configuration.activeTab || 0
}
