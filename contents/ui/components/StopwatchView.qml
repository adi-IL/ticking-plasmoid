import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: stopwatchRoot

    property var stopwatchData: ({
        formattedTime: "00:00:00.00",
        hours: "00",
        minutes: "00",
        seconds: "00",
        hundredths: "00",
        hasHours: false,
        running: false,
        laps: []
    })

    signal startRequested()
    signal pauseRequested()
    signal resetRequested()
    signal lapRequested()

    property color accentColor: "#00E599"
    property var themeColors: (typeof root !== "undefined" && root && root.themeColors) ? root.themeColors : ({
        subCardBg: Kirigami.Theme.backgroundColor,
        cardBorder: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12),
        specularGlint: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35),
        textPrimary: Kirigami.Theme.textColor,
        textSecondary: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72),
        textMuted: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45),
        dangerBg: Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.85),
        dangerBgHover: Kirigami.Theme.negativeTextColor,
        successBg: Kirigami.Theme.highlightColor,
        successBgHover: Qt.lighter(Kirigami.Theme.highlightColor, 1.15),
        onDangerFg: "#FFFFFF",
        onAccentFg: Kirigami.Theme.highlightedTextColor,
        buttonBg: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08),
        buttonBgHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14),
        buttonFg: Kirigami.Theme.textColor,
        rowAlt: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
    })

    spacing: Kirigami.Units.smallSpacing

    Kirigami.ShadowedRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
        radius: 8
        color: stopwatchRoot.themeColors.subCardBg
        border.width: 1
        border.color: stopwatchRoot.themeColors.cardBorder

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
                GradientStop { position: 0.5; color: stopwatchRoot.themeColors.specularGlint }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Text {
                text: (stopwatchRoot.stopwatchData.hasHours ? (stopwatchRoot.stopwatchData.hours + ":") : "")
                    + stopwatchRoot.stopwatchData.minutes + ":" + stopwatchRoot.stopwatchData.seconds
                color: stopwatchRoot.themeColors.textPrimary
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.ShadowedRectangle {
            id: startBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: stopwatchRoot.stopwatchData.running
                ? (startMouse.containsMouse ? stopwatchRoot.themeColors.dangerBgHover : stopwatchRoot.themeColors.dangerBg)
                : (startMouse.containsMouse ? stopwatchRoot.themeColors.successBgHover : stopwatchRoot.themeColors.successBg)

            Accessible.name: stopwatchRoot.stopwatchData.running
                ? i18nc("@action:button", "PAUSE")
                : i18nc("@action:button", "START")
            Accessible.role: Accessible.Button

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: stopwatchRoot.stopwatchData.running ? "chronometer-pause" : "chronometer-start"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: stopwatchRoot.stopwatchData.running
                        ? stopwatchRoot.themeColors.onDangerFg
                        : stopwatchRoot.themeColors.onAccentFg
                }
                Text {
                    text: stopwatchRoot.stopwatchData.running
                        ? i18nc("@action:button", "PAUSE")
                        : i18nc("@action:button", "START")
                    color: stopwatchRoot.stopwatchData.running
                        ? stopwatchRoot.themeColors.onDangerFg
                        : stopwatchRoot.themeColors.onAccentFg
                    font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                    font.weight: Font.Bold
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

        Kirigami.ShadowedRectangle {
            id: lapBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: lapMouse.containsMouse ? stopwatchRoot.themeColors.buttonBgHover : stopwatchRoot.themeColors.buttonBg
            border.width: 1
            border.color: stopwatchRoot.themeColors.cardBorder
            opacity: stopwatchRoot.stopwatchData.running ? 1.0 : 0.5

            Accessible.name: i18nc("@action:button", "LAP")
            Accessible.role: Accessible.Button

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: "chronometer-lap"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: stopwatchRoot.themeColors.buttonFg
                }
                Text {
                    text: i18nc("@action:button", "LAP")
                    color: stopwatchRoot.themeColors.buttonFg
                    font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                    font.weight: Font.Bold
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

        Kirigami.ShadowedRectangle {
            id: resetBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: resetMouse.containsMouse ? stopwatchRoot.themeColors.buttonBgHover : stopwatchRoot.themeColors.buttonBg
            border.width: 1
            border.color: stopwatchRoot.themeColors.cardBorder

            Accessible.name: i18nc("@action:button", "RESET")
            Accessible.role: Accessible.Button

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon {
                    source: "chronometer-reset"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    color: stopwatchRoot.themeColors.textSecondary
                }
                Text {
                    text: i18nc("@action:button", "RESET")
                    color: stopwatchRoot.themeColors.textSecondary
                    font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                    font.weight: Font.Bold
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

    Kirigami.ShadowedRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 3.5
        visible: !stopwatchRoot.stopwatchData.laps || stopwatchRoot.stopwatchData.laps.length === 0
        radius: 6
        color: stopwatchRoot.themeColors.subCardBg
        border.width: 1
        border.color: stopwatchRoot.themeColors.cardBorder

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            Kirigami.Icon {
                source: "chronometer-lap"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                color: stopwatchRoot.themeColors.textMuted
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18nc("@info:placeholder", "Press LAP while running to record split times")
                color: stopwatchRoot.themeColors.textMuted
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                font.weight: Font.Medium
            }
        }
    }

    PlasmaComponents.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        visible: stopwatchRoot.stopwatchData.laps && stopwatchRoot.stopwatchData.laps.length > 0

        ListView {
            id: lapListView
            model: stopwatchRoot.stopwatchData.laps
            spacing: 2
            clip: true

            delegate: Kirigami.ShadowedRectangle {
                width: lapListView.width
                height: 24
                radius: 4
                color: index % 2 === 0 ? stopwatchRoot.themeColors.rowAlt : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Text {
                        text: i18n("Lap %1", modelData.lapNumber)
                        color: stopwatchRoot.themeColors.textMuted
                        font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                        font.family: "monospace"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "+" + modelData.splitTime
                        color: stopwatchRoot.themeColors.textSecondary
                        font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                        font.family: "monospace"
                    }

                    Item { Layout.preferredWidth: 16 }

                    Text {
                        text: modelData.totalTime
                        color: stopwatchRoot.themeColors.textPrimary
                        font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                        font.family: "monospace"
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
