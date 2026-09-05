import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_customTitle: titleField.text
    property alias cfg_targetTimestamp: targetField.text
    property alias cfg_startTimestamp: startField.text
    property alias cfg_themeMode: themeHolder.text
    property alias cfg_showMilliseconds: msCheck.checked
    property alias cfg_showProgress: progressCheck.checked
    property alias cfg_showPanelBadge: panelBadgeCheck.checked
    property alias cfg_translucency: opacitySlider.value
    property alias cfg_hourFormat24: hourFormat24Check.checked
    property alias cfg_accentColor: accentField.text
    property int cfg_activeTab: 0

    Item {
        id: internalHolders
        visible: false
        QQC2.TextField { id: targetField }
        QQC2.TextField { id: startField }
        QQC2.TextField { id: themeHolder; text: "obsidian" }
    }

    property bool internalSyncing: false

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    // Civil date only. Countdown treats this as local midnight.
    function formatDate(y, mIndex, d) {
        return y + "-" + pad2(mIndex + 1) + "-" + pad2(d);
    }

    function parseCivilDate(text, fallbackY, fallbackM, fallbackD) {
        var s = (text || "").toString().trim();
        var m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (m) {
            return {
                y: parseInt(m[1], 10),
                m: parseInt(m[2], 10) - 1,
                d: parseInt(m[3], 10)
            };
        }
        // Legacy ISO with time: keep the Y-M-D the old picker wrote (UTC components match those digits)
        var dt = new Date(s);
        if (!isNaN(dt.getTime()) && s.indexOf("T") !== -1) {
            return {
                y: dt.getUTCFullYear(),
                m: dt.getUTCMonth(),
                d: dt.getUTCDate()
            };
        }
        return { y: fallbackY, m: fallbackM, d: fallbackD };
    }

    function updateTargetIso() {
        if (internalSyncing) return;
        var y = targetYearSpin.value;
        var m = targetMonthCombo.currentIndex;
        var maxD = daysInMonth(y, m);
        if (targetDaySpin.value > maxD) targetDaySpin.value = maxD;
        targetField.text = formatDate(y, m, targetDaySpin.value);
    }

    function updateStartIso() {
        if (internalSyncing) return;
        var y = startYearSpin.value;
        var m = startMonthCombo.currentIndex;
        var maxD = daysInMonth(y, m);
        if (startDaySpin.value > maxD) startDaySpin.value = maxD;
        startField.text = formatDate(y, m, startDaySpin.value);
    }

    function syncFromIso() {
        internalSyncing = true;

        var td = parseCivilDate(targetField.text, 2026, 9, 25);
        targetYearSpin.value = td.y;
        targetMonthCombo.currentIndex = td.m;
        targetDaySpin.value = td.d;

        var sd = parseCivilDate(startField.text, 2026, 0, 1);
        startYearSpin.value = sd.y;
        startMonthCombo.currentIndex = sd.m;
        startDaySpin.value = sd.d;

        internalSyncing = false;
    }

    Component.onCompleted: syncFromIso()

    Connections {
        target: targetField
        function onTextChanged() {
            if (!internalSyncing) configPage.syncFromIso();
        }
    }

    Connections {
        target: startField
        function onTextChanged() {
            if (!internalSyncing) configPage.syncFromIso();
        }
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Milestone title:")
            placeholderText: i18nc("@title:window default milestone", "NEW HORIZON")
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Target horizon date")
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:date", "End date:")
            Layout.fillWidth: true
            spacing: 6

            QQC2.ComboBox {
                id: targetMonthCombo
                model: [
                    i18nc("@item:month", "Jan"), i18nc("@item:month", "Feb"),
                    i18nc("@item:month", "Mar"), i18nc("@item:month", "Apr"),
                    i18nc("@item:month", "May"), i18nc("@item:month", "Jun"),
                    i18nc("@item:month", "Jul"), i18nc("@item:month", "Aug"),
                    i18nc("@item:month", "Sep"), i18nc("@item:month", "Oct"),
                    i18nc("@item:month", "Nov"), i18nc("@item:month", "Dec")
                ]
                Layout.preferredWidth: 80
                onCurrentIndexChanged: configPage.updateTargetIso()
            }

            QQC2.SpinBox {
                id: targetDaySpin
                from: 1
                to: configPage.daysInMonth(targetYearSpin.value, targetMonthCombo.currentIndex)
                value: 25
                editable: true
                Layout.preferredWidth: 70
                onValueChanged: configPage.updateTargetIso()
            }

            QQC2.SpinBox {
                id: targetYearSpin
                from: 1970
                to: 2100
                value: 2026
                editable: true
                Layout.preferredWidth: 90
                onValueChanged: configPage.updateTargetIso()
            }

            Text {
                text: i18nc("@info:time", "@ local 00:00")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Journey start date")
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:date", "Start date:")
            Layout.fillWidth: true
            spacing: 6

            QQC2.ComboBox {
                id: startMonthCombo
                model: [
                    i18nc("@item:month", "Jan"), i18nc("@item:month", "Feb"),
                    i18nc("@item:month", "Mar"), i18nc("@item:month", "Apr"),
                    i18nc("@item:month", "May"), i18nc("@item:month", "Jun"),
                    i18nc("@item:month", "Jul"), i18nc("@item:month", "Aug"),
                    i18nc("@item:month", "Sep"), i18nc("@item:month", "Oct"),
                    i18nc("@item:month", "Nov"), i18nc("@item:month", "Dec")
                ]
                Layout.preferredWidth: 80
                onCurrentIndexChanged: configPage.updateStartIso()
            }

            QQC2.SpinBox {
                id: startDaySpin
                from: 1
                to: configPage.daysInMonth(startYearSpin.value, startMonthCombo.currentIndex)
                value: 1
                editable: true
                Layout.preferredWidth: 70
                onValueChanged: configPage.updateStartIso()
            }

            QQC2.SpinBox {
                id: startYearSpin
                from: 1970
                to: 2100
                value: 2026
                editable: true
                Layout.preferredWidth: 90
                onValueChanged: configPage.updateStartIso()
            }

            Text {
                text: i18nc("@info:time", "@ local 00:00")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
            }

            QQC2.Button {
                text: i18nc("@action:button", "Today")
                onClicked: {
                    var now = new Date();
                    startYearSpin.value = now.getFullYear();
                    startMonthCombo.currentIndex = now.getMonth();
                    startDaySpin.value = now.getDate();
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "Jan 1")
                onClicked: {
                    startMonthCombo.currentIndex = 0;
                    startDaySpin.value = 1;
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:summary", "Journey span:")
            spacing: 6

            Text {
                text: {
                    var sParts = configPage.parseCivilDate(startField.text, 2026, 0, 1);
                    var tParts = configPage.parseCivilDate(targetField.text, 2026, 9, 25);
                    var s = new Date(sParts.y, sParts.m, sParts.d);
                    var t = new Date(tParts.y, tParts.m, tParts.d);
                    if (isNaN(s.getTime()) || isNaN(t.getTime())) return "--";
                    var diffDays = Math.round((t.getTime() - s.getTime()) / 86400000);
                    return diffDays > 0
                        ? i18np("%1 total day", "%1 total days", diffDays)
                        : i18n("Invalid range (end before start)");
                }
                color: Kirigami.Theme.highlightColor
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
            text: i18nc("@info", "Dates are calendar days in your local timezone. The countdown hits zero at local midnight on the end date.")
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:presets", "Quick presets:")
            spacing: 6

            QQC2.Button {
                text: i18nc("@action:button", "New Year 2027")
                onClicked: {
                    startYearSpin.value = 2026;
                    startMonthCombo.currentIndex = 0;
                    startDaySpin.value = 1;
                    targetYearSpin.value = 2027;
                    targetMonthCombo.currentIndex = 0;
                    targetDaySpin.value = 1;
                    titleField.text = "NEW YEAR 2027";
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "End of 2026")
                onClicked: {
                    startYearSpin.value = 2026;
                    startMonthCombo.currentIndex = 0;
                    startDaySpin.value = 1;
                    targetYearSpin.value = 2026;
                    targetMonthCombo.currentIndex = 11;
                    targetDaySpin.value = 31;
                    titleField.text = "END OF 2026";
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "100-Day Goal")
                onClicked: {
                    var now = new Date();
                    startYearSpin.value = now.getFullYear();
                    startMonthCombo.currentIndex = now.getMonth();
                    startDaySpin.value = now.getDate();
                    var targetD = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 100);
                    targetYearSpin.value = targetD.getFullYear();
                    targetMonthCombo.currentIndex = targetD.getMonth();
                    targetDaySpin.value = targetD.getDate();
                    titleField.text = "100-DAY GOAL";
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "Oct 25, 2026")
                onClicked: {
                    startYearSpin.value = 2026;
                    startMonthCombo.currentIndex = 0;
                    startDaySpin.value = 1;
                    targetYearSpin.value = 2026;
                    targetMonthCombo.currentIndex = 9;
                    targetDaySpin.value = 25;
                    titleField.text = "OCTOBER 25, 2026 HORIZON";
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Display and aesthetic")
        }

        QQC2.ComboBox {
            id: themeCombo
            Kirigami.FormData.label: i18nc("@label:combobox", "Visual theme:")
            model: [
                { text: i18nc("@item:theme", "Vercel Obsidian Glass (Dark HUD)"), value: "obsidian" },
                { text: i18nc("@item:theme", "Plasma System Theme Adaptive"), value: "system" }
            ]
            textRole: "text"
            currentIndex: themeHolder.text === "system" ? 1 : 0
            onCurrentIndexChanged: {
                themeHolder.text = model[currentIndex].value;
            }
        }

        QQC2.ComboBox {
            id: defaultTabCombo
            Kirigami.FormData.label: i18nc("@label:combobox", "Default view:")
            model: [
                i18nc("@item:tab", "Countdown"),
                i18nc("@item:tab", "Clock"),
                i18nc("@item:tab", "Stopwatch")
            ]
            Component.onCompleted: currentIndex = Math.max(0, Math.min(2, configPage.cfg_activeTab))
            onActivated: function (index) {
                configPage.cfg_activeTab = index;
            }
            Connections {
                target: configPage
                function onCfg_activeTabChanged() {
                    var next = Math.max(0, Math.min(2, configPage.cfg_activeTab));
                    if (defaultTabCombo.currentIndex !== next) {
                        defaultTabCombo.currentIndex = next;
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:textbox", "Accent color:")
            Layout.fillWidth: true
            spacing: 6

            QQC2.TextField {
                id: accentField
                placeholderText: "#00E599"
                Layout.fillWidth: true
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                color: {
                    var raw = (accentField.text || "").trim();
                    if (/^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/.test(raw)) {
                        return raw;
                    }
                    return "#00E599";
                }
                border.width: 1
                border.color: Kirigami.Theme.textColor
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:swatches", "Vercel presets:")
            spacing: 8

            Repeater {
                model: [
                    { name: "Emerald", hex: "#00E599" },
                    { name: "Cyan", hex: "#50E3C2" },
                    { name: "Blue", hex: "#0070F3" },
                    { name: "Purple", hex: "#7928CA" },
                    { name: "Amber", hex: "#F5A623" },
                    { name: "Crimson", hex: "#FF0080" },
                    { name: "White", hex: "#FFFFFF" }
                ]

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: modelData.hex
                    border.width: accentField.text.toUpperCase() === modelData.hex ? 2 : 1
                    border.color: accentField.text.toUpperCase() === modelData.hex
                        ? Kirigami.Theme.textColor
                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)

                    QQC2.ToolTip.visible: swatchMouse.containsMouse
                    QQC2.ToolTip.text: modelData.name + " (" + modelData.hex + ")"

                    MouseArea {
                        id: swatchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: accentField.text = modelData.hex
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:slider", "Glass opacity:")
            Layout.fillWidth: true

            QQC2.Slider {
                id: opacitySlider
                from: 0.2
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }

            Text {
                text: Math.round(opacitySlider.value * 100) + "%"
                color: Kirigami.Theme.textColor
                font.family: "monospace"
                Layout.preferredWidth: 40
            }
        }

        QQC2.CheckBox {
            id: msCheck
            Kirigami.FormData.label: i18nc("@label:checkbox", "Precision:")
            text: i18n("Show sub-second milliseconds ticker")
        }

        QQC2.CheckBox {
            id: progressCheck
            Kirigami.FormData.label: i18nc("@label:checkbox", "Progress bar:")
            text: i18n("Display journey percentage progress bar")
        }

        QQC2.CheckBox {
            id: panelBadgeCheck
            Kirigami.FormData.label: i18nc("@label:checkbox", "Panel badge:")
            text: i18n("Show remaining time text on horizontal panels")
        }

        QQC2.CheckBox {
            id: hourFormat24Check
            Kirigami.FormData.label: i18nc("@label:checkbox", "Clock format:")
            text: i18n("Use 24-hour clock format")
        }
    }
}
