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
    property alias cfg_showMilliseconds: msCheck.checked
    property alias cfg_showProgress: progressCheck.checked
    property alias cfg_translucency: opacitySlider.value
    property alias cfg_hourFormat24: hourFormat24Check.checked
    property alias cfg_accentColor: accentField.text

    Kirigami.FormLayout {
        // Milestone Title
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Milestone title:")
            placeholderText: "OCTOBER 25, 2026 HORIZON"
            Layout.fillWidth: true
        }

        // Target Date
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:textbox", "Target timestamp:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: targetField
                placeholderText: "2026-10-25T00:00:00Z"
                Layout.fillWidth: true
            }

            QQC2.Button {
                text: i18nc("@action:button", "Oct 25, 2026")
                onClicked: targetField.text = "2026-10-25T00:00:00Z"
            }
        }

        // Baseline Start Date
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:textbox", "Baseline timestamp:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: startField
                placeholderText: "Auto (Installation Date)"
                Layout.fillWidth: true
            }

            QQC2.Button {
                text: i18nc("@action:button", "Set to Now")
                onClicked: startField.text = new Date().toISOString()
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Display & Aesthetic")
        }

        // Accent Color
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:textbox", "Accent color:")
            Layout.fillWidth: true

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
