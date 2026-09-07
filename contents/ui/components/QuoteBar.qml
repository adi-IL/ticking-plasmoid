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
    property var themeColors: (typeof root !== "undefined" && root && root.themeColors) ? root.themeColors : ({
        subCardBg: Kirigami.Theme.backgroundColor,
        subCardHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.09),
        cardBorder: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12),
        cardBorderHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.22),
        specularGlint: Qt.rgba(1, 1, 1, 0.25),
        textPrimary: Kirigami.Theme.textColor,
        textMuted: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
    })

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

    readonly property int charCount: (quoteText || "").trim().length
    readonly property int wordCount: quoteText.trim().length > 0 ? quoteText.trim().split(/\s+/).length : 0

    // Adaptive typography: scale font size according to length
    readonly property real adaptiveQuoteFontSize: {
        var base = Math.max(11.5, Kirigami.Theme.defaultFont.pixelSize || 12);
        if (charCount > 115 || wordCount > 22) {
            return Math.max(10, base - 2);
        } else if (charCount > 75 || wordCount > 14) {
            return Math.max(10.5, base - 1);
        } else if (charCount < 36 && wordCount <= 6) {
            return base + 1;
        }
        return base;
    }

    // Adaptive line limits: allow longer quotes to expand rather than truncating
    readonly property int adaptiveMaxLines: {
        if (charCount > 110) return 4;
        if (charCount > 60) return 3;
        return 2;
    }

    // Adaptive vertical padding: tighter for 1-liners, generous for long quotes
    readonly property real adaptiveVSpacing: {
        if (charCount > 90) return Kirigami.Units.smallSpacing * 1.3;
        if (charCount < 40) return Kirigami.Units.smallSpacing * 0.8;
        return Kirigami.Units.smallSpacing * 1.0;
    }

    // Estimated height before paintedHeight is available
    readonly property real fallbackHeight: {
        var lines = (charCount > 110) ? 4 : ((charCount > 60) ? 3 : ((charCount > 30) ? 2 : 1));
        var fontH = Math.round(adaptiveQuoteFontSize * 1.32);
        var textH = lines * fontH;
        var authH = quoteAuthor.length > 0 ? 15 : 0;
        return textH + authH;
    }

    // Pixel-perfect adaptive height derived from exact layout metrics
    readonly property real contentCalculatedHeight: {
        var textH = Math.ceil(quoteLabel.paintedHeight);
        var authH = authorLabel.visible ? Math.ceil(authorLabel.paintedHeight + textColumn.spacing) : 0;
        var iconsH = 18;
        var innerH = (textH > 0) ? Math.max(textH + authH, iconsH) : fallbackHeight;
        return innerH + Math.round(adaptiveVSpacing * 2);
    }

    Layout.fillWidth: true
    Layout.minimumHeight: Kirigami.Units.gridUnit * 2.0
    Layout.maximumHeight: Kirigami.Units.gridUnit * 6.0
    Layout.preferredHeight: Math.max(Layout.minimumHeight, Math.min(Layout.maximumHeight, contentCalculatedHeight))

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    radius: 10
    color: capsuleMouse.containsMouse ? quoteBarRoot.themeColors.subCardHover : quoteBarRoot.themeColors.subCardBg
    border.width: 1
    border.color: capsuleMouse.containsMouse ? quoteBarRoot.themeColors.cardBorderHover : quoteBarRoot.themeColors.cardBorder

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
            GradientStop { position: 0.5; color: capsuleMouse.containsMouse ? quoteBarRoot.themeColors.specularGlint : Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Math.round(quoteBarRoot.adaptiveVSpacing)
        anchors.bottomMargin: Math.round(quoteBarRoot.adaptiveVSpacing)
        spacing: Kirigami.Units.smallSpacing

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: authorLabel.visible ? 2 : 0

            Text {
                id: quoteLabel
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: quoteBarRoot.quoteText.length > 0
                    ? ("\"" + quoteBarRoot.quoteText + "\"")
                    : i18nc("@info:placeholder", "Focus on the horizon ahead.")
                color: quoteBarRoot.themeColors.textPrimary
                font.family: "sans-serif"
                font.pixelSize: quoteBarRoot.adaptiveQuoteFontSize
                font.italic: true
                lineHeight: 1.22
                wrapMode: Text.WordWrap
                maximumLineCount: quoteBarRoot.adaptiveMaxLines
                elide: Text.ElideRight

                Behavior on font.pixelSize {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                id: authorLabel
                visible: quoteBarRoot.quoteAuthor.length > 0
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: quoteBarRoot.quoteAuthor.length > 0 ? ("- " + quoteBarRoot.quoteAuthor) : ""
                color: quoteBarRoot.accentColor
                font.family: "sans-serif"
                font.pixelSize: Math.max(10, Kirigami.Theme.smallFont.pixelSize)
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
            Layout.alignment: Qt.AlignVCenter
            color: quoteBarRoot.isCopied
                ? quoteBarRoot.accentColor
                : (copyMouse.containsMouse ? quoteBarRoot.themeColors.textPrimary : quoteBarRoot.themeColors.textMuted)
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
            Layout.alignment: Qt.AlignVCenter
            color: refreshMouse.containsMouse ? quoteBarRoot.themeColors.textPrimary : quoteBarRoot.themeColors.textMuted
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
