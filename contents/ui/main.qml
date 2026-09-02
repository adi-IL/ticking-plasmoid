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

    // Eliminate outer container frame so custom HUD floats seamlessly
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    preferredRepresentation: {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return fullRepresentation;
        }
        return compactRepresentation;
    }

    // Theme Palette Adaptation (Obsidian Glass vs Plasma System Adaptive)
    readonly property bool isSystemTheme: Plasmoid.configuration.themeMode === "system"

    readonly property var themeColors: ({
        cardBg: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, Plasmoid.configuration.translucency || 0.88)
            : Qt.rgba(0.03, 0.03, 0.03, Plasmoid.configuration.translucency || 0.88),
        cardBorder: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            : Qt.rgba(1, 1, 1, 0.09),
        cardBorderHover: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
            : Qt.rgba(1, 1, 1, 0.18),
        specularGlint: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)
            : Qt.rgba(1, 1, 1, 0.45),
        textPrimary: isSystemTheme ? Kirigami.Theme.textColor : "#EDEDED",
        textSecondary: isSystemTheme ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72) : "#A1A1AA",
        textMuted: isSystemTheme ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45) : "#71717A",
        subCardBg: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.95)
            : Qt.rgba(0.06, 0.06, 0.06, 0.88),
        subCardHover: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
            : Qt.rgba(0.12, 0.12, 0.12, 0.96),
        accentColor: Plasmoid.configuration.accentColor || "#00E599"
    })

    // Tooltip Integration
    toolTipMainText: Plasmoid.configuration.customTitle || "NEW HORIZON"
    toolTipSubText: root.countdownData.isExpired
        ? i18nc("@info:tooltip", "Horizon reached - 100.000% completed")
        : i18n("%1 Days, %2 Hours remaining", root.countdownData.days, root.countdownData.hours)

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
        },
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Configure Ticking…")
            icon.name: "configure"
            priority: PlasmaCore.Action.DefaultPriorityAction
            onTriggered: {
                var configAction = Plasmoid.internalAction("configure") || (typeof plasmoid !== "undefined" && plasmoid.action ? plasmoid.action("configure") : null);
                if (configAction) configAction.trigger();
            }
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
        hours: "00",
        minutes: "00",
        seconds: "00",
        hundredths: "00",
        hasHours: false,
        running: false,
        laps: []
    })

    property double stopwatchElapsedMs: 0
    property double stopwatchLastTimestamp: 0
    property double stopwatchLastLapMs: 0

    // Adaptive Precision live ticker timer (throttled to preserve battery when idle)
    Timer {
        id: tickerTimer
        interval: {
            var isVisible = (Plasmoid.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar);
            if (!isVisible) {
                return 1000;
            }
            if (root.stopwatchData.running || Plasmoid.configuration.showMilliseconds) {
                return 40; // ~25 FPS high precision
            }
            return 1000;
        }
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

        // 1. Target Date parsing (Default: 2026-10-25T00:00:00Z)
        var targetIso = Plasmoid.configuration.targetTimestamp || "2026-10-25T00:00:00Z";
        var targetDate = new Date(targetIso);
        var targetMs = targetDate.getTime();
        if (isNaN(targetMs)) {
            targetDate = new Date("2026-10-25T00:00:00Z");
            targetMs = targetDate.getTime();
        }

        // 2. Baseline Date Calculation (Universal start of year, custom, or installation)
        var baseMode = Plasmoid.configuration.baselineMode || "year_start";
        var startMs = 0;
        if (baseMode === "year_start") {
            var targetYear = targetDate.getFullYear();
            var baseYear = (targetYear <= now.getFullYear()) ? now.getFullYear() : (now.getFullYear());
            startMs = new Date(baseYear, 0, 1, 0, 0, 0).getTime();
            if (startMs >= targetMs) {
                startMs = nowMs - (1000 * 60 * 60 * 24 * 30); // 30 days baseline if target is Jan 1
            }
        } else if (baseMode === "custom") {
            var customStart = Plasmoid.configuration.startTimestamp;
            startMs = customStart ? new Date(customStart).getTime() : 0;
            if (isNaN(startMs) || startMs <= 0 || startMs >= targetMs) {
                startMs = nowMs - (1000 * 60 * 60 * 24);
            }
        } else { // "install"
            var startIso = Plasmoid.configuration.startTimestamp;
            if (!startIso || startIso === "") {
                startIso = now.toISOString();
                Plasmoid.configuration.startTimestamp = startIso;
            }
            startMs = new Date(startIso).getTime();
            if (isNaN(startMs)) {
                startMs = nowMs;
            }
        }

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
        var ratio = isExpired ? 1.0 : 0.0;
        if (!isExpired && totalSpan > 0) {
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
        var hrs = Math.floor(totalSec / 3600);
        var min = Math.floor((totalSec % 3600) / 60);
        var sec = totalSec % 60;
        var hundredths = Math.floor((root.stopwatchElapsedMs % 1000) / 10);
        var formatted = (hrs > 0 ? (pad2(hrs) + ":") : "") + pad2(min) + ":" + pad2(sec) + "." + pad2(hundredths);

        root.stopwatchData = {
            formattedTime: formatted,
            hours: pad2(hrs),
            minutes: pad2(min),
            seconds: pad2(sec),
            hundredths: pad2(hundredths),
            hasHours: hrs > 0,
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
            var hrs = Math.floor(s / 3600);
            var m = Math.floor((s % 3600) / 60);
            var sc = s % 60;
            var hd = Math.floor((t % 1000) / 10);
            return (hrs > 0 ? (pad2(hrs) + ":") : "") + pad2(m) + ":" + pad2(sc) + "." + pad2(hd);
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
