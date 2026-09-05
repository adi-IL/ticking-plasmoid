import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "./components" as Components

Item {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20

    property int activeTabIndex: typeof root !== "undefined" ? root.currentViewIndex : 0

    Connections {
        target: typeof root !== "undefined" ? root : null
        function onCurrentViewIndexChanged() {
            if (fullRoot.activeTabIndex !== root.currentViewIndex) {
                fullRoot.activeTabIndex = root.currentViewIndex;
            }
        }
    }

    Kirigami.ShadowedRectangle {
        id: hudCard
        anchors.fill: parent
        anchors.margins: 4
        radius: 12

        color: root.themeColors.cardBg
        border.width: 1
        border.color: mouseTracker.containsMouse ? root.themeColors.cardBorderHover : root.themeColors.cardBorder

        shadow.size: 20
        shadow.color: root.isSystemTheme ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.75)
        shadow.yOffset: 6

        MouseArea {
            id: mouseTracker
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Rectangle {
            id: specularBeam
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                GradientStop {
                    position: Math.max(0.05, Math.min(0.95, mouseTracker.mouseX / Math.max(1, hudCard.width)))
                    color: mouseTracker.containsMouse ? root.themeColors.specularGlint : Qt.rgba(1, 1, 1, 0.20)
                }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.topMargin: Kirigami.Units.smallSpacing * 1.5
            anchors.bottomMargin: Kirigami.Units.smallSpacing * 1.5
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

    signal quoteRefreshRequested()

    Kirigami.ShadowedRectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: liveRow.implicitWidth + 14
                    radius: 11
                    color: root.themeColors.livePillBg
                    border.width: 1
                    border.color: root.themeColors.livePillBorder

                    RowLayout {
                        id: liveRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: root.themeColors.accentColor

                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            text: i18nc("@label:status", "LIVE")
                            color: root.themeColors.accentColor
                            font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                            font.weight: Font.Bold
                            font.letterSpacing: 1.1
                        }
                    }
                }

                Text {
                    text: root.milestoneTitle
                    color: root.themeColors.textPrimary
                    font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    font.capitalization: Font.AllUppercase
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Kirigami.Icon {
                    source: "configure"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: settingsMouse.containsMouse ? root.themeColors.textPrimary : root.themeColors.textMuted
                    Accessible.name: i18nc("@action:button", "Configure Ticking")

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var configAction = Plasmoid.internalAction("configure")
                                || (typeof plasmoid !== "undefined" && plasmoid.action ? plasmoid.action("configure") : null);
                            if (configAction) {
                                configAction.trigger();
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.CountdownView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 0
                    timeData: root.countdownData
                    showMilliseconds: Plasmoid.configuration.showMilliseconds
                    showProgress: Plasmoid.configuration.showProgress
                    accentColor: root.themeColors.accentColor
                }

                Components.ClockView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 1
                    clockData: root.clockData
                    accentColor: root.themeColors.accentColor
                }

                Components.StopwatchView {
                    anchors.fill: parent
                    visible: fullRoot.activeTabIndex === 2
                    stopwatchData: root.stopwatchData
                    accentColor: root.themeColors.accentColor
                    onStartRequested: root.startStopwatch()
                    onPauseRequested: root.pauseStopwatch()
                    onResetRequested: root.resetStopwatch()
                    onLapRequested: root.lapStopwatch()
                }
            }

            Components.SegmentedNav {
                Layout.fillWidth: true
                currentIndex: fullRoot.activeTabIndex
                onTabSelected: index => {
                    fullRoot.activeTabIndex = index;
                    if (typeof root !== "undefined") {
                        root.currentViewIndex = index;
                    }
                }
            }

            Components.QuoteBar {
                Layout.fillWidth: true
                visible: Plasmoid.configuration.showQuoteBar !== false
                quoteText: root.currentQuoteText
                quoteAuthor: root.currentQuoteAuthor
                isLoading: root.isQuoteLoading
                accentColor: root.themeColors.accentColor
                onRefreshRequested: {
                    if (typeof root !== "undefined" && root.fetchNextQuote) {
                        root.fetchNextQuote(false);
                    }
                    fullRoot.quoteRefreshRequested();
                }
            }
        }
    }
}
