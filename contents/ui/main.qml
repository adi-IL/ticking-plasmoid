import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 14

    // Custom HUD draws its own card; skip the Plasma frame
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    preferredRepresentation: {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return fullRepresentation;
        }
        return compactRepresentation;
    }

    readonly property bool isSystemTheme: Plasmoid.configuration.themeMode === "system"

    readonly property color safeAccent: {
        var raw = (Plasmoid.configuration.accentColor || "").toString().trim();
        var hex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/.test(raw) ? raw : "#00E599";
        // Prefer Qt.color when available; otherwise let QML coerce the hex string
        if (typeof Qt.color === "function") {
            return Qt.color(hex);
        }
        return hex;
    }

    // Dark ink on bright accents, light ink on dark ones (property binding, not object-literal block)
    readonly property color onAccentFg: {
        var lum = 0.2126 * safeAccent.r + 0.7152 * safeAccent.g + 0.0722 * safeAccent.b;
        return lum > 0.55 ? "#0A0A0A" : "#FFFFFF";
    }

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
        dangerBg: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.85)
            : Qt.rgba(0.8, 0.2, 0.2, 0.8),
        dangerBgHover: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.95)
            : Qt.rgba(0.9, 0.3, 0.3, 0.9),
        successBg: Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, isSystemTheme ? 0.88 : 0.8),
        successBgHover: Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.95),
        buttonBg: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
            : Qt.rgba(0.12, 0.12, 0.12, 0.8),
        buttonBgHover: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
            : Qt.rgba(0.2, 0.2, 0.2, 0.9),
        buttonFg: isSystemTheme ? Kirigami.Theme.textColor : "#FFFFFF",
        onAccentFg: root.onAccentFg,
        onDangerFg: "#FFFFFF",
        rowAlt: isSystemTheme
            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
            : Qt.rgba(0.1, 0.1, 0.1, 0.6),
        livePillBg: Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.12),
        livePillBorder: Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.3),
        accentColor: safeAccent
    })

    readonly property string milestoneTitle: {
        var t = (Plasmoid.configuration.customTitle || "").toString().trim();
        return t.length > 0 ? t : i18nc("@title:window default milestone", "NEW HORIZON");
    }

    toolTipMainText: root.milestoneTitle
    toolTipSubText: root.countdownData.isExpired
        ? i18nc("@info:tooltip", "Horizon reached - 100.000% completed")
        : i18n("%1 days, %2 hours remaining", root.countdownData.days, root.countdownData.hours)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Reset baseline to today")
            icon.name: "view-refresh"
            priority: PlasmaCore.Action.LowPriority
            onTriggered: root.resetBaselineToNow()
        },
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Reset stopwatch")
            icon.name: "edit-clear"
            priority: PlasmaCore.Action.LowPriority
            onTriggered: root.resetStopwatch()
        },
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Configure Ticking…")
            icon.name: "configure"
            priority: PlasmaCore.Action.NormalPriority
            onTriggered: {
                var configAction = Plasmoid.internalAction("configure")
                    || (typeof plasmoid !== "undefined" && plasmoid.action ? plasmoid.action("configure") : null);
                if (configAction) {
                    configAction.trigger();
                }
            }
        }
    ]

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

    // Plain bools so Timer.interval and button bindings always notify
    property bool stopwatchRunning: false
    property double stopwatchElapsedMs: 0
    property double stopwatchLastTimestamp: 0
    property double stopwatchLastLapMs: 0
    property var stopwatchLaps: []

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

    Timer {
        id: tickerTimer
        interval: {
            var isVisible = (Plasmoid.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar);
            if (!isVisible) {
                return 1000;
            }
            if (root.stopwatchRunning || Plasmoid.configuration.showMilliseconds) {
                return 40;
            }
            return 1000;
        }
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateAllMetrics()
    }

    function pad2(n) {
        var num = Math.floor(Math.abs(Number(n)) || 0);
        return num < 10 ? "0" + num : "" + num;
    }

    // Civil calendar date at local midnight.
    // Accepts YYYY-MM-DD or legacy ...T00:00:00Z (uses the UTC Y-M-D the picker wrote).
    function parseHorizonDate(value) {
        var s = (value || "").toString().trim();
        var m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (m) {
            var y = parseInt(m[1], 10);
            var mo = parseInt(m[2], 10) - 1;
            var d = parseInt(m[3], 10);
            var local = new Date(y, mo, d, 0, 0, 0, 0);
            if (!isNaN(local.getTime())) {
                return local;
            }
        }
        return null;
    }

    function formatHorizonDate(dateObj) {
        return dateObj.getFullYear() + "-" + pad2(dateObj.getMonth() + 1) + "-" + pad2(dateObj.getDate());
    }

    function defaultTargetDate() {
        return new Date(2026, 9, 25, 0, 0, 0, 0);
    }

    function defaultStartDate() {
        return new Date(2026, 0, 1, 0, 0, 0, 0);
    }

    // ISO-8601 week number (Mon-based, week 1 contains Jan 4)
    function isoWeekNumber(dateObj) {
        var d = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
        d.setHours(0, 0, 0, 0);
        // Move to Thursday of this week
        d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
        var week1 = new Date(d.getFullYear(), 0, 4);
        return 1 + Math.round(((d.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
    }

    function dayOfYearLocal(dateObj) {
        var start = new Date(dateObj.getFullYear(), 0, 1);
        return Math.floor((dateObj.getTime() - start.getTime()) / 86400000) + 1;
    }

    function resetBaselineToNow() {
        Plasmoid.configuration.startTimestamp = formatHorizonDate(new Date());
        updateAllMetrics();
    }

    function updateAllMetrics() {
        var now = new Date();
        var nowMs = now.getTime();

        var targetDate = parseHorizonDate(Plasmoid.configuration.targetTimestamp) || defaultTargetDate();
        var startDate = parseHorizonDate(Plasmoid.configuration.startTimestamp) || defaultStartDate();
        var targetMs = targetDate.getTime();
        var startMs = startDate.getTime();

        var diffMs = targetMs - nowMs;
        var isExpired = diffMs <= 0;

        var d = 0, h = 0, m = 0, s = 0, ms = 0;
        if (!isExpired) {
            d = Math.floor(diffMs / 86400000);
            h = Math.floor((diffMs % 86400000) / 3600000);
            m = Math.floor((diffMs % 3600000) / 60000);
            s = Math.floor((diffMs % 60000) / 1000);
            ms = Math.floor((diffMs % 1000) / 10);
        }

        var totalSpan = targetMs - startMs;
        var elapsedSpan = nowMs - startMs;
        var ratio = 0.0;
        if (isExpired) {
            ratio = 1.0;
        } else if (nowMs <= startMs) {
            ratio = 0.0;
        } else if (totalSpan > 0) {
            ratio = Math.max(0.0, Math.min(1.0, elapsedSpan / totalSpan));
        }

        root.countdownData = {
            days: pad2(d),
            hours: pad2(h),
            minutes: pad2(m),
            seconds: pad2(s),
            milliseconds: pad2(ms),
            progressRatio: ratio,
            progressPercent: (ratio * 100).toFixed(3) + "%",
            isExpired: isExpired
        };

        var hoursNum = now.getHours();
        var amPmStr = "";
        if (!Plasmoid.configuration.hourFormat24) {
            amPmStr = hoursNum >= 12 ? "PM" : "AM";
            hoursNum = hoursNum % 12;
            if (hoursNum === 0) {
                hoursNum = 12;
            }
        }

        // Date only under the big clock. LongFormat on a DateTime also embeds time.
        var dateFormatted = Qt.formatDate(now, Locale.LongFormat);
        if (!dateFormatted || dateFormatted.length === 0) {
            dateFormatted = now.toLocaleDateString(Qt.locale(), Locale.LongFormat);
        }

        var tzOffsetMin = -now.getTimezoneOffset();
        var tzSign = tzOffsetMin >= 0 ? "+" : "-";
        var tzHours = Math.floor(Math.abs(tzOffsetMin) / 60);
        var tzMins = Math.abs(tzOffsetMin) % 60;
        var tzString = "UTC" + tzSign + pad2(tzHours) + ":" + pad2(tzMins);

        root.clockData = {
            hours: pad2(hoursNum),
            minutes: pad2(now.getMinutes()),
            seconds: pad2(now.getSeconds()),
            amPm: amPmStr,
            dateString: dateFormatted,
            timeZone: tzString,
            dayOfYear: dayOfYearLocal(now),
            weekOfYear: isoWeekNumber(now)
        };

        if (root.stopwatchRunning) {
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

        // Whole-object replace so ListView / buttons always see a new value
        root.stopwatchData = {
            formattedTime: formatted,
            hours: pad2(hrs),
            minutes: pad2(min),
            seconds: pad2(sec),
            hundredths: pad2(hundredths),
            hasHours: hrs > 0,
            running: root.stopwatchRunning,
            laps: root.stopwatchLaps.slice()
        };
    }

    function startStopwatch() {
        root.stopwatchLastTimestamp = Date.now();
        root.stopwatchRunning = true;
        updateStopwatchDisplay();
    }

    function pauseStopwatch() {
        root.stopwatchRunning = false;
        updateStopwatchDisplay();
    }

    function resetStopwatch() {
        root.stopwatchRunning = false;
        root.stopwatchElapsedMs = 0;
        root.stopwatchLastLapMs = 0;
        root.stopwatchLaps = [];
        updateStopwatchDisplay();
    }

    function lapStopwatch() {
        if (!root.stopwatchRunning) {
            return;
        }

        var currentTotal = root.stopwatchElapsedMs;
        var split = currentTotal - root.stopwatchLastLapMs;
        root.stopwatchLastLapMs = currentTotal;

        var formatMs = function (t) {
            var s = Math.floor(t / 1000);
            var hrs = Math.floor(s / 3600);
            var m = Math.floor((s % 3600) / 60);
            var sc = s % 60;
            var hd = Math.floor((t % 1000) / 10);
            return (hrs > 0 ? (pad2(hrs) + ":") : "") + pad2(m) + ":" + pad2(sc) + "." + pad2(hd);
        };

        var newLap = {
            lapNumber: root.stopwatchLaps.length + 1,
            splitTime: formatMs(split),
            totalTime: formatMs(currentTotal)
        };

        root.stopwatchLaps = [newLap].concat(root.stopwatchLaps);
        updateStopwatchDisplay();
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
