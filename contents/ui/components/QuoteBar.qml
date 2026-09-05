import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: quoteBarRoot

    property string quoteText: ""
    property string quoteAuthor: ""
    property bool isLoading: false
    property color accentColor: "#00E599"

    signal refreshRequested()

    property bool isCopied: false

    Timer {
        id: copiedResetTimer
        interval: 1600
        repeat: false
        onTriggered: quoteBarRoot.isCopied = false
    }

    TextInput {
        id: clipboardHelper
        visible: false
    }

    Layout.fillWidth: true
    Layout.preferredHeight: authorLabel.visible ? (quoteLabel.lineCount > 1 ? Kirigami.Units.gridUnit * 3.6 : Kirigami.Units.gridUnit * 3.0) : Kirigami.Units.gridUnit * 2.4
    Layout.minimumHeight: Kirigami.Units.gridUnit * 2.2
    radius: 10
    color: capsuleMouse.containsMouse ? root.themeColors.subCardHover : root.themeColors.subCardBg
    border.width: 1
    border.color: capsuleMouse.containsMouse ? root.themeColors.cardBorderHover : root.themeColors.cardBorder

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: capsuleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: quoteBarRoot.refreshRequested()
    }

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
            GradientStop { position: 0.5; color: capsuleMouse.containsMouse ? root.themeColors.specularGlint : Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing * 1.2
        anchors.bottomMargin: Kirigami.Units.smallSpacing * 1.2
        spacing: Kirigami.Units.smallSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: quoteLabel
                Layout.fillWidth: true
                text: quoteBarRoot.quoteText.length > 0
                    ? ("\"" + quoteBarRoot.quoteText + "\"")
                    : i18nc("@info:placeholder", "Focus on the horizon ahead.")
                color: root.themeColors.textPrimary
                font.family: "sans-serif"
                font.pixelSize: Math.max(13, Kirigami.Theme.defaultFont.pixelSize)
                font.italic: true
                lineHeight: 1.2
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                id: authorLabel
                visible: quoteBarRoot.quoteAuthor.length > 0
                Layout.fillWidth: true
                text: quoteBarRoot.quoteAuthor.length > 0 ? ("- " + quoteBarRoot.quoteAuthor) : ""
                color: quoteBarRoot.accentColor
                font.family: "sans-serif"
                font.pixelSize: Math.max(11, Kirigami.Theme.smallFont.pixelSize + 1)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Kirigami.Icon {
            id: copyIcon
            source: quoteBarRoot.isCopied ? "emblem-checked" : "edit-copy"
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            color: quoteBarRoot.isCopied
                ? quoteBarRoot.accentColor
                : (copyMouse.containsMouse ? root.themeColors.textPrimary : root.themeColors.textMuted)
            opacity: copyMouse.containsMouse || quoteBarRoot.isCopied ? 1.0 : (capsuleMouse.containsMouse ? 0.85 : 0.45)
            Accessible.name: quoteBarRoot.isCopied
                ? i18nc("@info:tooltip", "Copied to clipboard")
                : i18nc("@action:button", "Copy quote")

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var full = quoteBarRoot.quoteText;
                    if (quoteBarRoot.quoteAuthor.length > 0) {
                        full = full + " - " + quoteBarRoot.quoteAuthor;
                    }
                    clipboardHelper.text = full;
                    clipboardHelper.selectAll();
                    clipboardHelper.copy();
                    quoteBarRoot.isCopied = true;
                    copiedResetTimer.restart();
                }
            }

            QQC2.ToolTip.visible: copyMouse.containsMouse
            QQC2.ToolTip.text: quoteBarRoot.isCopied
                ? i18nc("@info:tooltip", "Copied to clipboard")
                : i18nc("@action:button", "Copy quote")
        }

        Kirigami.Icon {
            id: refreshIcon
            source: "view-refresh"
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            color: refreshMouse.containsMouse ? root.themeColors.textPrimary : root.themeColors.textMuted
            opacity: refreshMouse.containsMouse || quoteBarRoot.isLoading ? 1.0 : (capsuleMouse.containsMouse ? 0.85 : 0.45)
            Accessible.name: i18nc("@action:button", "New quote")

            RotationAnimation on rotation {
                running: quoteBarRoot.isLoading
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: quoteBarRoot.refreshRequested()
            }

            QQC2.ToolTip.visible: refreshMouse.containsMouse
            QQC2.ToolTip.text: i18nc("@action:button", "New quote")
        }
    }
}
