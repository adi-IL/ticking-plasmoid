import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: countdownRoot

    property var timeData: ({
        days: "00",
        hours: "00",
        minutes: "00",
        seconds: "00",
        milliseconds: "00",
        progressRatio: 0.0,
        progressPercent: "0.000%",
        isExpired: false
    })

    property bool showMilliseconds: true
    property bool showProgress: true
    property color accentColor: "#00E599"

    spacing: Kirigami.Units.largeSpacing

    // Metric Cards Grid
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Kirigami.Units.smallSpacing

        MetricCard {
            value: countdownRoot.timeData.days
            unit: i18nc("@label:timeunit", "Days")
            accentColor: countdownRoot.accentColor
        }

        MetricCard {
            value: countdownRoot.timeData.hours
            unit: i18nc("@label:timeunit", "Hours")
            accentColor: countdownRoot.accentColor
        }

        MetricCard {
            value: countdownRoot.timeData.minutes
            unit: i18nc("@label:timeunit", "Mins")
            accentColor: countdownRoot.accentColor
        }

        MetricCard {
            value: countdownRoot.timeData.seconds
            unit: i18nc("@label:timeunit", "Secs")
            accentColor: countdownRoot.accentColor
            isHighlighted: true
        }

        MetricCard {
            visible: countdownRoot.showMilliseconds
            value: countdownRoot.timeData.milliseconds
            unit: i18nc("@label:timeunit", "Msec")
            accentColor: countdownRoot.accentColor
        }
    }

    // Progress Bar Track
    ProgressTrack {
        visible: countdownRoot.showProgress
        Layout.fillWidth: true
        progressRatio: countdownRoot.timeData.progressRatio
        percentageText: countdownRoot.timeData.progressPercent
        accentColor: countdownRoot.accentColor
    }
}
