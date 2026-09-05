import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: clockRoot

    property var clockData: ({
        hours: "00",
        minutes: "00",
        seconds: "00",
        amPm: "",
        dateString: "",
        timeZone: "UTC",
        dayOfYear: 1,
        weekOfYear: 1
    })

    property color accentColor: "#00E599"

    spacing: Kirigami.Units.largeSpacing

    // Big Digital Time Card
    Kirigami.ShadowedRectangle {
        id: clockCard
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5.5
        radius: 8
        color: root.themeColors.subCardBg
        border.width: 1
        border.color: root.themeColors.cardBorder

        // Top edge specular line
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

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            // Time Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                readonly property int responsiveFontSize: Math.min(42, Math.max(26, clockCard.width * 0.11))

                Text {
                    text: clockRoot.clockData.hours
                    color: root.themeColors.textPrimary
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: parent.responsiveFontSize
                    font.features: { "tnum": 1 }
                }

                Text {
                    text: ":"
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: parent.responsiveFontSize
                }

                Text {
                    text: clockRoot.clockData.minutes
                    color: root.themeColors.textPrimary
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: parent.responsiveFontSize
                    font.features: { "tnum": 1 }
                }

                Text {
                    text: ":"
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: parent.responsiveFontSize
                }

                Text {
                    text: clockRoot.clockData.seconds
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: parent.responsiveFontSize
                    font.features: { "tnum": 1 }
                }

                Text {
                    visible: clockRoot.clockData.amPm !== ""
                    text: clockRoot.clockData.amPm
                    color: root.themeColors.textSecondary
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6
                }
            }

            // Full Date String
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: clockRoot.clockData.dateString
                color: root.themeColors.textSecondary
                font.family: "sans-serif"
                font.weight: Font.DemiBold
                font.pixelSize: 11
                font.letterSpacing: 1.2
                font.capitalization: Font.AllUppercase
            }
        }
    }

    // Secondary Info Pills
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        // Timezone Pill
        Kirigami.ShadowedRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: root.themeColors.subCardBg
            border.width: 1
            border.color: root.themeColors.cardBorder

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: i18nc("@label:time", "ZONE:"); color: root.themeColors.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                Text { text: clockRoot.clockData.timeZone; color: root.themeColors.textPrimary; font.pixelSize: 10; font.family: "monospace"; font.weight: Font.Bold }
            }
        }

        // Day of Year Pill
        Kirigami.ShadowedRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: root.themeColors.subCardBg
            border.width: 1
            border.color: root.themeColors.cardBorder

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: i18nc("@label:time", "DAY:"); color: root.themeColors.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                Text { text: "" + clockRoot.clockData.dayOfYear; color: root.themeColors.textPrimary; font.pixelSize: 10; font.family: "monospace"; font.weight: Font.Bold }
            }
        }

        // Week of Year Pill
        Kirigami.ShadowedRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: root.themeColors.subCardBg
            border.width: 1
            border.color: root.themeColors.cardBorder

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: i18nc("@label:time", "ISO WK:"); color: root.themeColors.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                Text { text: "#" + clockRoot.clockData.weekOfYear; color: root.themeColors.textPrimary; font.pixelSize: 10; font.family: "monospace"; font.weight: Font.Bold }
            }
        }
    }
}
