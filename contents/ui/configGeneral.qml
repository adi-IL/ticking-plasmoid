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
    }

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    // Both start and end dates automatically assume 00:00:00 UTC
    function updateTargetIso() {
        if (internalSyncing) return;
        var y = targetYearSpin.value;
        var m = targetMonthCombo.currentIndex;
        var maxD = daysInMonth(y, m);
        if (targetDaySpin.value > maxD) targetDaySpin.value = maxD;
        var d = targetDaySpin.value;

        targetField.text = y + "-" + pad2(m + 1) + "-" + pad2(d) + "T00:00:00Z";
    }

    function updateStartIso() {
        if (internalSyncing) return;
        var y = startYearSpin.value;
        var m = startMonthCombo.currentIndex;
        var maxD = daysInMonth(y, m);
        if (startDaySpin.value > maxD) startDaySpin.value = maxD;
        var d = startDaySpin.value;

        startField.text = y + "-" + pad2(m + 1) + "-" + pad2(d) + "T00:00:00Z";
    }

    function syncFromIso() {
        internalSyncing = true;

        // Parse Target Date
        var targetText = targetField.text || "2026-10-25T00:00:00Z";
        var td = new Date(targetText);
        if (!isNaN(td.getTime())) {
            targetYearSpin.value = td.getUTCFullYear();
            targetMonthCombo.currentIndex = td.getUTCMonth();
            targetDaySpin.value = td.getUTCDate();
        }

        // Parse Start Date
        var startText = startField.text || "2026-01-01T00:00:00Z";
        var sd = new Date(startText);
        if (!isNaN(sd.getTime())) {
            startYearSpin.value = sd.getUTCFullYear();
            startMonthCombo.currentIndex = sd.getUTCMonth();
            startDaySpin.value = sd.getUTCDate();
        }

        internalSyncing = false;
    }

    property bool internalSyncing: false

    Component.onCompleted: {
        syncFromIso();
    }

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
        // Milestone Title
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Milestone title:")
            placeholderText: "NEW HORIZON"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Target Horizon Date (00:00 End)")
        }

        // Target Date Selector: Month, Day, Year (00:00 assumed automatically)
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
                from: 2024
                to: 2099
                value: 2026
                editable: true
                Layout.preferredWidth: 90
                onValueChanged: configPage.updateTargetIso()
            }

            Text {
                text: i18nc("@info:time", "@ 00:00")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 11
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Journey Start Date (00:00 Start)")
        }

        // Start Date Selector: Month, Day, Year (00:00 assumed automatically)
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
                from: 2020
                to: 2099
                value: 2026
                editable: true
                Layout.preferredWidth: 90
                onValueChanged: configPage.updateStartIso()
            }

            Text {
                text: i18nc("@info:time", "@ 00:00")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 11
            }

            QQC2.Button {
                text: i18nc("@action:button", "Today")
                onClicked: {
                    var now = new Date();
                    startYearSpin.value = now.getUTCFullYear();
                    startMonthCombo.currentIndex = now.getUTCMonth();
                    startDaySpin.value = now.getUTCDate();
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

        // Live Total Days Calculator Indicator
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:summary", "Journey span:")
            spacing: 6

            Text {
                text: {
                    var s = new Date(startField.text);
                    var t = new Date(targetField.text);
                    if (isNaN(s.getTime()) || isNaN(t.getTime())) return "--";
                    var diffDays = Math.round((t.getTime() - s.getTime()) / (1000 * 60 * 60 * 24));
                    return diffDays > 0 ? (diffDays + " " + i18n("total days")) : i18n("Invalid range (end before start)");
                }
                color: Kirigami.Theme.highlightColor
                font.weight: Font.DemiBold
                font.pixelSize: 11
            }
        }

        // Quick Universal Presets
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
                    startYearSpin.value = now.getUTCFullYear();
                    startMonthCombo.currentIndex = now.getUTCMonth();
                    startDaySpin.value = now.getUTCDate();

                    var targetD = new Date(now.getTime() + (100 * 24 * 60 * 60 * 1000));
                    targetYearSpin.value = targetD.getUTCFullYear();
                    targetMonthCombo.currentIndex = targetD.getUTCMonth();
                    targetDaySpin.value = targetD.getUTCDate();

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
