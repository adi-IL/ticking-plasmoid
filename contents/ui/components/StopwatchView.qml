import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: stopwatchRoot

    property var stopwatchData: ({
        formattedTime: "00:00:00.00",
        minutes: "00",
        seconds: "00",
        hundredths: "00",
        running: false,
        laps: []
    })

    signal startRequested()
    signal pauseRequested()
    signal resetRequested()
    signal lapRequested()

    property color accentColor: "#00E599"

    spacing: Kirigami.Units.smallSpacing

    // Stopwatch Digits Display
    Kirigami.ShadowedRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
        radius: 8
        color: root.themeColors.subCardBg
        border.width: 1
        border.color: root.themeColors.cardBorder

        // Top specular line
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
                GradientStop { position: 0.5; color: root.themeColors.specularGlint }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Text {
                text: (stopwatchRoot.stopwatchData.hasHours ? (stopwatchRoot.stopwatchData.hours + ":") : "")
                    + stopwatchRoot.stopwatchData.minutes + ":" + stopwatchRoot.stopwatchData.seconds
                color: root.themeColors.textPrimary
                font.family: "monospace"
                font.weight: Font.Bold
                font.pixelSize: stopwatchRoot.stopwatchData.hasHours ? 28 : 36
                font.features: { "tnum": 1 }
            }

            Text {
                text: "." + stopwatchRoot.stopwatchData.hundredths
                color: stopwatchRoot.accentColor
                font.family: "monospace"
                font.weight: Font.Bold
                font.pixelSize: stopwatchRoot.stopwatchData.hasHours ? 22 : 28
                font.features: { "tnum": 1 }
                Layout.alignment: Qt.AlignBaseline
            }
        }
    }

    // Controls Row
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        // Start / Pause Button
        Kirigami.ShadowedRectangle {
            id: startBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: stopwatchRoot.stopwatchData.running
                ? (startMouse.containsMouse ? Qt.rgba(0.9, 0.3, 0.3, 0.9) : Qt.rgba(0.8, 0.2, 0.2, 0.8))
                : (startMouse.containsMouse ? Qt.rgba(0.0, 0.9, 0.6, 0.9) : Qt.rgba(0.0, 0.8, 0.5, 0.8))

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: stopwatchRoot.stopwatchData.running ? "chronometer-pause" : "chronometer-start"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: "#000000"
                }
                Text {
                    text: stopwatchRoot.stopwatchData.running ? i18nc("@action:button", "PAUSE") : i18nc("@action:button", "START")
                    color: "#000000"
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    font.letterSpacing: 1.1
                }
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (stopwatchRoot.stopwatchData.running) {
                        stopwatchRoot.pauseRequested();
                    } else {
                        stopwatchRoot.startRequested();
                    }
                }
            }
        }

        // Lap Button
        Kirigami.ShadowedRectangle {
            id: lapBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: lapMouse.containsMouse ? Qt.rgba(0.2, 0.2, 0.2, 0.9) : Qt.rgba(0.12, 0.12, 0.12, 0.8)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            opacity: stopwatchRoot.stopwatchData.running ? 1.0 : 0.5

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: "chronometer-lap"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: "#FFFFFF"
                }
                Text {
                    text: i18nc("@action:button", "LAP")
                    color: "#FFFFFF"
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    font.letterSpacing: 1.1
                }
            }

            MouseArea {
                id: lapMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: stopwatchRoot.stopwatchData.running
                cursorShape: Qt.PointingHandCursor
                onClicked: stopwatchRoot.lapRequested()
            }
        }

        // Reset Button
        Kirigami.ShadowedRectangle {
            id: resetBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: resetMouse.containsMouse ? Qt.rgba(0.2, 0.2, 0.2, 0.9) : Qt.rgba(0.12, 0.12, 0.12, 0.8)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: "chronometer-reset"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: "#D4D4D8"
                }
                Text {
                    text: i18nc("@action:button", "RESET")
                    color: "#D4D4D8"
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    font.letterSpacing: 1.1
                }
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stopwatchRoot.resetRequested()
            }
        }
    }

    // Empty state placeholder when no laps have been recorded
    Kirigami.ShadowedRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 3.5
        visible: stopwatchRoot.stopwatchData.laps.length === 0
        radius: 6
        color: Qt.rgba(0.04, 0.04, 0.04, 0.5)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.04)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            Kirigami.Icon {
                source: "chronometer-lap"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                color: "#52525B"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18nc("@info:placeholder", "Press LAP while running to record split times")
                color: "#52525B"
                font.family: "sans-serif"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    // Lap List Container
    PlasmaComponents.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        visible: stopwatchRoot.stopwatchData.laps.length > 0

        ListView {
            id: lapListView
            model: stopwatchRoot.stopwatchData.laps
            spacing: 2
            clip: true

            delegate: Kirigami.ShadowedRectangle {
                width: lapListView.width
                height: 24
                radius: 4
                color: index % 2 === 0 ? Qt.rgba(0.1, 0.1, 0.1, 0.6) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Text {
                        text: i18n("Lap %1", modelData.lapNumber)
                        color: "#71717A"
                        font.pixelSize: 10
                        font.family: "monospace"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "+" + modelData.splitTime
                        color: "#A1A1AA"
                        font.pixelSize: 10
                        font.family: "monospace"
                    }

                    Item { Layout.preferredWidth: 16 }

                    Text {
                        text: modelData.totalTime
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
