import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    // Bindings must match main.xml entry names prefixed with cfg_
    property alias cfg_customTitle: titleField.text
    property alias cfg_targetTimestamp: targetField.text
    property alias cfg_startTimestamp: startField.text
    property alias cfg_themeMode: themeHolder.text
    property alias cfg_baselineMode: baselineHolder.text
    property alias cfg_showMilliseconds: msCheck.checked
    property alias cfg_showProgress: progressCheck.checked
    property alias cfg_translucency: opacitySlider.value
    property alias cfg_hourFormat24: hourFormat24Check.checked
    property alias cfg_accentColor: accentField.text

    // Internal holders for KCM auto-binding
    Item {
        id: internalHolders
        visible: false
        QQC2.TextField { id: targetField }
        QQC2.TextField { id: startField }
        QQC2.TextField { id: themeHolder; text: "obsidian" }
        QQC2.TextField { id: baselineHolder; text: "year_start" }
    }

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    function updateTargetIso() {
        if (internalSyncing) return;
        var y = targetYearSpin.value;
        var m = targetMonthCombo.currentIndex;
        var maxD = daysInMonth(y, m);
        if (targetDaySpin.value > maxD) targetDaySpin.value = maxD;
        var d = targetDaySpin.value;
        var hh = targetHourSpin.value;
        var mm = targetMinSpin.value;

        var iso = y + "-" + pad2(m + 1) + "-" + pad2(d) + "T" + pad2(hh) + ":" + pad2(mm) + ":00Z";
        targetField.text = iso;
    }

    function syncFromTargetIso() {
        if (!targetField.text || targetField.text === "") return;
        var d = new Date(targetField.text);
        if (isNaN(d.getTime())) return;
        internalSyncing = true;
        targetYearSpin.value = d.getUTCFullYear();
        targetMonthCombo.currentIndex = d.getUTCMonth();
        targetDaySpin.value = d.getUTCDate();
        targetHourSpin.value = d.getUTCHours();
        targetMinSpin.value = d.getUTCMinutes();
        internalSyncing = false;
    }

    property bool internalSyncing: false

    Component.onCompleted: {
        syncFromTargetIso();
    }

    Connections {
        target: targetField
        function onTextChanged() {
            if (!internalSyncing) {
                configPage.syncFromTargetIso();
            }
        }
    }

    Kirigami.FormLayout {
        // Milestone Title
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Milestone title:")
            placeholderText: "NEW HORIZON"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Target Horizon Date & Time")
        }

        // GUI Date Selector: Month, Day, Year
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:date", "Target date:")
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
                from: 2024
                to: 2099
                value: 2026
                editable: true
                Layout.preferredWidth: 90
                onValueChanged: configPage.updateTargetIso()
            }
        }

        // GUI Time Selector: Hour, Minute
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:time", "Target time (UTC):")
            Layout.fillWidth: true
            spacing: 6

            QQC2.SpinBox {
                id: targetHourSpin
                from: 0
                to: 23
                value: 0
                editable: true
                Layout.preferredWidth: 70
                onValueChanged: configPage.updateTargetIso()
            }

            Text {
                text: ":"
                color: Kirigami.Theme.textColor
                font.weight: Font.Bold
            }

            QQC2.SpinBox {
                id: targetMinSpin
                from: 0
                to: 59
                value: 0
                editable: true
                Layout.preferredWidth: 70
                onValueChanged: configPage.updateTargetIso()
            }

            Text {
                text: "UTC"
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 10
            }
        }

        // Quick Universal Presets
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:presets", "Quick presets:")
            spacing: 6

            QQC2.Button {
                text: i18nc("@action:button", "New Year 2027")
                onClicked: {
                    targetYearSpin.value = 2027;
                    targetMonthCombo.currentIndex = 0;
                    targetDaySpin.value = 1;
                    targetHourSpin.value = 0;
                    targetMinSpin.value = 0;
                    titleField.text = "NEW YEAR 2027";
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "End of 2026")
                onClicked: {
                    targetYearSpin.value = 2026;
                    targetMonthCombo.currentIndex = 11;
                    targetDaySpin.value = 31;
                    targetHourSpin.value = 23;
                    targetMinSpin.value = 59;
                    titleField.text = "END OF 2026";
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "Oct 25, 2026")
                onClicked: {
                    targetYearSpin.value = 2026;
                    targetMonthCombo.currentIndex = 9;
                    targetDaySpin.value = 25;
                    targetHourSpin.value = 0;
                    targetMinSpin.value = 0;
                    titleField.text = "OCTOBER 25, 2026 HORIZON";
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Journey Progress & Baseline")
        }

        // Baseline Calculation Mode
        QQC2.ComboBox {
            id: baselineCombo
            Kirigami.FormData.label: i18nc("@label:combobox", "Journey baseline:")
            model: [
                { text: i18nc("@item:baseline", "Start of current year (Standard)"), value: "year_start" },
                { text: i18nc("@item:baseline", "Widget installation time"), value: "install" },
                { text: i18nc("@item:baseline", "Custom start date"), value: "custom" }
            ]
            textRole: "text"
            currentIndex: baselineHolder.text === "install" ? 1 : (baselineHolder.text === "custom" ? 2 : 0)
            onCurrentIndexChanged: {
                baselineHolder.text = model[currentIndex].value;
            }
        }

        // Custom start timestamp (if custom selected)
        RowLayout {
            visible: baselineCombo.currentIndex === 2
            Kirigami.FormData.label: i18nc("@label:textbox", "Custom start:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: customStartField
                text: startField.text
                placeholderText: "YYYY-MM-DDTHH:MM:SSZ"
                Layout.fillWidth: true
                onTextChanged: startField.text = text
            }

            QQC2.Button {
                text: i18nc("@action:button", "Set to Now")
                onClicked: {
                    var nowIso = new Date().toISOString();
                    customStartField.text = nowIso;
                    startField.text = nowIso;
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Display & Aesthetic")
        }

        // Visual Theme Mode Selector
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

        // Accent Color
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
                color: accentField.text || "#00E599"
                border.width: 1
                border.color: "#FFFFFF"
            }
        }

        // Vercel Color Palette Presets
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
                    border.color: accentField.text.toUpperCase() === modelData.hex ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.3)

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

        // Translucency Slider
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

        // Toggles
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
            id: hourFormat24Check
            Kirigami.FormData.label: i18nc("@label:checkbox", "Clock format:")
            text: i18n("Use 24-hour clock format")
        }
    }
}
