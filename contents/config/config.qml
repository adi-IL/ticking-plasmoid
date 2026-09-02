import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title:tab", "General")
        icon: "preferences-system"
        source: "configGeneral.qml"
    }
}
