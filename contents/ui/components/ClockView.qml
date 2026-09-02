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
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 6
        radius: 8
        color: Qt.rgba(0.06, 0.06, 0.06, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            // Time Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Text {
                    text: clockRoot.clockData.hours
                    color: "#FFFFFF"
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: 42
                    font.features: { "tnum": 1 }
                }

                Text {
                    text: ":"
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: 42
                }

                Text {
                    text: clockRoot.clockData.minutes
                    color: "#FFFFFF"
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: 42
                    font.features: { "tnum": 1 }
                }

                Text {
                    text: ":"
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: 42
                }

                Text {
                    text: clockRoot.clockData.seconds
                    color: clockRoot.accentColor
                    font.family: "monospace"
                    font.weight: Font.Bold
                    font.pixelSize: 42
                    font.features: { "tnum": 1 }
                }

                Text {
                    visible: clockRoot.clockData.amPm !== ""
                    text: clockRoot.clockData.amPm
                    color: "#A1A1AA"
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 8
                }
            }

            // Full Date String
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: clockRoot.clockData.dateString
                color: "#A1A1AA"
                font.family: "sans-serif"
                font.weight: Font.DemiBold
                font.pixelSize: 12
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
            color: Qt.rgba(0.1, 0.1, 0.1, 0.8)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: i18nc("@label:time", "ZONE:"); color: "#71717A"; font.pixelSize: 10; font.weight: Font.Bold }
                Text { text: clockRoot.clockData.timeZone; color: "#D4D4D8"; font.pixelSize: 10; font.family: "monospace"; font.weight: Font.Bold }
            }
        }

        // Day of Year Pill
        Kirigami.ShadowedRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: Qt.rgba(0.1, 0.1, 0.1, 0.8)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: i18nc("@label:time", "DAY OF YEAR:"); color: "#71717A"; font.pixelSize: 10; font.weight: Font.Bold }
                Text { text: "" + clockRoot.clockData.dayOfYear; color: "#D4D4D8"; font.pixelSize: 10; font.family: "monospace"; font.weight: Font.Bold }
            }
        }
    }
}
