import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Sizing & Representation Thresholds
    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 14

    preferredRepresentation: {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return fullRepresentation;
        }
        return compactRepresentation;
    }

    // Tooltip Integration
    toolTipMainText: Plasmoid.configuration.customTitle || "OCTOBER 25, 2026 HORIZON"
    toolTipSubText: i18n("%1 Days, %2 Hours remaining", root.countdownData.days, root.countdownData.hours)

    // Context Menu Actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Reset Baseline to Today")
            icon.name: "view-refresh"
            priority: PlasmaCore.Action.LowPriorityAction
            onTriggered: root.resetBaselineToNow()
        },
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Reset Stopwatch")
            icon.name: "edit-clear"
            priority: PlasmaCore.Action.LowPriorityAction
            onTriggered: root.resetStopwatch()
        }
    ]

    // Time Data Stores
    property var countdownData: ({
        days: "00",
        hours: "00",
        minutes: "00",
        seconds: "00",
        milliseconds: "00",
        progressRatio: 0.0,
        progressPercent: "0.000%",
        isExpired: false
    })

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

    property var stopwatchData: ({
        formattedTime: "00:00.00",
        minutes: "00",
        seconds: "00",
        hundredths: "00",
        running: false,
        laps: []
    })

    property double stopwatchElapsedMs: 0
    property double stopwatchLastTimestamp: 0
    property double stopwatchLastLapMs: 0

    // High precision live ticker timer
    Timer {
        id: tickerTimer
        interval: (Plasmoid.configuration.showMilliseconds && (Plasmoid.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar)) ? 50 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateAllMetrics()
    }

    function pad2(n) {
        var num = Math.floor(n);
        return num < 10 ? "0" + num : "" + num;
    }

    function resetBaselineToNow() {
        Plasmoid.configuration.startTimestamp = new Date().toISOString();
        updateAllMetrics();
    }

    function updateAllMetrics() {
        var now = new Date();
        var nowMs = now.getTime();

        // 1. Initial Start Timestamp Setup (First Run baseline)
        var startIso = Plasmoid.configuration.startTimestamp;
        if (!startIso || startIso === "") {
            startIso = now.toISOString();
            Plasmoid.configuration.startTimestamp = startIso;
        }

        var startDate = new Date(startIso);
        var startMs = startDate.getTime();

        // Target Date parsing (Default: 2026-10-25T00:00:00Z)
        var targetIso = Plasmoid.configuration.targetTimestamp || "2026-10-25T00:00:00Z";
        var targetDate = new Date(targetIso);
        var targetMs = targetDate.getTime();

        // 2. Countdown Calculations
        var diffMs = targetMs - nowMs;
        var isExpired = diffMs <= 0;

        var d = 0, h = 0, m = 0, s = 0, ms = 0;
        if (!isExpired) {
            d = Math.floor(diffMs / (1000 * 60 * 60 * 24));
            h = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            m = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
            s = Math.floor((diffMs % (1000 * 60)) / 1000);
            ms = Math.floor((diffMs % 1000) / 10);
        }

        // Total Journey Progress Calculation (Start -> Target)
        var totalSpan = targetMs - startMs;
        var elapsedSpan = nowMs - startMs;
        var ratio = 0.0;
        if (totalSpan > 0) {
            ratio = Math.max(0.0, Math.min(1.0, elapsedSpan / totalSpan));
        }

        var percentFormatted = (ratio * 100).toFixed(3) + "%";

        root.countdownData = {
            days: pad2(d),
            hours: pad2(h),
            minutes: pad2(m),
            seconds: pad2(s),
            milliseconds: pad2(ms),
            progressRatio: ratio,
            progressPercent: percentFormatted,
            isExpired: isExpired
        };

        // 3. Live Clock Calculations
        var hoursNum = now.getHours();
        var amPmStr = "";
        if (!Plasmoid.configuration.hourFormat24) {
            amPmStr = hoursNum >= 12 ? "PM" : "AM";
            hoursNum = hoursNum % 12;
            if (hoursNum === 0) hoursNum = 12;
        }

        var monthNames = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"];
        var dayNames = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];

        var dateFormatted = dayNames[now.getDay()] + ", " + monthNames[now.getMonth()] + " " + now.getDate() + ", " + now.getFullYear();

        // Timezone calculation
        var tzOffsetMin = -now.getTimezoneOffset();
        var tzSign = tzOffsetMin >= 0 ? "+" : "-";
        var tzHours = Math.floor(Math.abs(tzOffsetMin) / 60);
        var tzMins = Math.abs(tzOffsetMin) % 60;
        var tzString = "UTC" + tzSign + pad2(tzHours) + ":" + pad2(tzMins);

        // Day of Year calculation
        var startOfYear = new Date(now.getFullYear(), 0, 1);
        var dayOfYear = Math.floor((now - startOfYear) / (1000 * 60 * 60 * 24)) + 1;

        root.clockData = {
            hours: pad2(hoursNum),
            minutes: pad2(now.getMinutes()),
            seconds: pad2(now.getSeconds()),
            amPm: amPmStr,
            dateString: dateFormatted,
            timeZone: tzString,
            dayOfYear: dayOfYear,
            weekOfYear: Math.ceil(dayOfYear / 7)
        };

        // 4. Stopwatch Live Update
        if (root.stopwatchData.running) {
            var currentClock = Date.now();
            var delta = currentClock - root.stopwatchLastTimestamp;
            root.stopwatchLastTimestamp = currentClock;
            root.stopwatchElapsedMs += delta;
            updateStopwatchDisplay();
        }
    }

    function updateStopwatchDisplay() {
        var totalSec = Math.floor(root.stopwatchElapsedMs / 1000);
        var min = Math.floor(totalSec / 60);
        var sec = totalSec % 60;
        var hundredths = Math.floor((root.stopwatchElapsedMs % 1000) / 10);

        root.stopwatchData = {
            formattedTime: pad2(min) + ":" + pad2(sec) + "." + pad2(hundredths),
            minutes: pad2(min),
            seconds: pad2(sec),
            hundredths: pad2(hundredths),
            running: root.stopwatchData.running,
            laps: root.stopwatchData.laps
        };
    }

    function startStopwatch() {
        root.stopwatchLastTimestamp = Date.now();
        root.stopwatchData.running = true;
        updateStopwatchDisplay();
    }

    function pauseStopwatch() {
        root.stopwatchData.running = false;
        updateStopwatchDisplay();
    }

    function resetStopwatch() {
        root.stopwatchData.running = false;
        root.stopwatchElapsedMs = 0;
        root.stopwatchLastLapMs = 0;
        root.stopwatchData.laps = [];
        updateStopwatchDisplay();
    }

    function lapStopwatch() {
        if (!root.stopwatchData.running) return;

        var currentTotal = root.stopwatchElapsedMs;
        var split = currentTotal - root.stopwatchLastLapMs;
        root.stopwatchLastLapMs = currentTotal;

        var formatMs = function(t) {
            var s = Math.floor(t / 1000);
            var m = Math.floor(s / 60);
            var sc = s % 60;
            var hd = Math.floor((t % 1000) / 10);
            return pad2(m) + ":" + pad2(sc) + "." + pad2(hd);
        };

        var newLap = {
            lapNumber: root.stopwatchData.laps.length + 1,
            splitTime: formatMs(split),
            totalTime: formatMs(currentTotal)
        };

        var updatedLaps = [newLap].concat(root.stopwatchData.laps);
        root.stopwatchData.laps = updatedLaps;
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
