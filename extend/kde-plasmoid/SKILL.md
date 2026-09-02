---
name: kde-plasmoid
description: "Develop, debug, test, package, port, and publish KDE Plasma 6 widgets (Plasmoids) using modern Qt 6, KDE Frameworks 6, Kirigami, and C++/QML architecture on Linux/Fedora."
metadata:
  author: kde-plasma-maintainers
  version: "2.0.0"
  tags:
    - kde
    - plasma6
    - plasmoid
    - widget
    - qml
    - qt6
    - kf6
    - kirigami
    - c++
    - linux
    - fedora
---

# Modern KDE Plasma 6 Plasmoid Development Playbook

A production-grade technical specification and operational manual for developing, debugging, testing, packaging, porting, and publishing KDE Plasma 6 desktop and panel widgets (Plasmoids).

---

## 1. Technical Baseline & Core Architecture

### Platform Targets

| Component | Minimum Version | Reference Target (Fedora KDE) | Notes |
| :--- | :--- | :--- | :--- |
| **KDE Plasma** | `6.0.0` | `6.2+` / `6.7+` | Plasma 5 APIs and legacy compatibility shims are removed. |
| **KDE Frameworks (KF)** | `6.0.0` | `6.5+` / `6.29+` | Unversioned QML imports; `plasma-framework` split into `libplasma`, `ksvg`, `plasma5support`. |
| **Qt Framework** | `6.6.0` | `6.7+` / `6.11+` | Pure Qt 6 QML and C++20 standard library. |
| **Operating System** | Modern Linux | Fedora KDE 40+ | Native Wayland session with systemd user services. |

### Architecture Selection Framework

```
                       ┌─────────────────────────────────────┐
                       │  What is the widget's requirement?  │
                       └──────────────────┬──────────────────┘
                                          │
       ┌──────────────────────────────────┼──────────────────────────────────┐
       ▼                                  ▼                                  ▼
┌──────────────┐                  ┌──────────────┐                  ┌──────────────┐
│  UI / Logic  │                  │  Heavy Math  │                  │ System/CLI/  │
│  REST / HTTP │                  │ C++ Models   │                  │ External Dev │
│ DBus Clients │                  │ Native Libs  │                  │ Background   │
└──────┬───────┘                  └──────┬───────┘                  └──────┬───────┘
       │                                 │                                 │
       ▼                                 ▼                                 ▼
┌──────────────┐                  ┌──────────────┐                  ┌──────────────┐
│   Tier 1:    │                  │   Tier 2:    │                  │   Tier 3:    │
│   Pure QML   │                  │  QML + C++   │                  │  QML + DBus  │
│  (Preferred) │                  │   Plugin     │                  │    Daemon    │
└──────────────┘                  └──────────────┘                  └──────────────┘
```

1. **Tier 1: Pure QML / Kirigami (Preferred & Canonical)**
   - UI layer: `PlasmoidItem` + `Kirigami` + `PlasmaComponents`.
   - Data & Logic: Declarative bindings, JavaScript helper functions, `XMLHttpRequest` / `Fetch`, and D-Bus interfaces via `QtDBus` / QML D-Bus bindings.
   - Zero compilation required. Distributed directly through KDE Store / GH releases.

2. **Tier 2: QML + Native C++ Plugin (High Performance / System APIs)**
   - Used when high CPU efficiency, multithreaded I/O (`QThreadPool`, `QThread`), low-level Linux APIs, or custom `QAbstractItemModel` implementations are required.
   - Built using CMake, ECM (Extra CMake Modules), and `libplasma`. Installs QML extension plugins to `${KDE_INSTALL_QMLDIR}`.

3. **Tier 3: QML + External Process / D-Bus Service (Daemon Architecture)**
   - Used when leveraging existing scripts, Python packages (`psutil`, `pydbus`), or external system daemons.
   - Logic runs in a separate process/daemon communicating over the D-Bus Session Bus.
   - The QML widget acts as a D-Bus client.

#### Clarification on Python in Plasma 6
`plasmashell` is a C++ Qt 6 binary. It **does not embed a Python interpreter** or execute arbitrary Python scripts inside the shell process. `PySide6` / `PyQt6` `@QmlElement` decorators cannot be registered directly into `plasmashell` without a dedicated host binary. Any Python logic must run as an **isolated D-Bus daemon** or be invoked asynchronously via a subprocess helper.

---

## 2. Fedora KDE Development Environment & Toolchain

### Required Packages on Fedora

Install the development headers, build system, and debugging utilities:

```bash
# Core Plasma 6 & KF6 Development Tooling
sudo dnf install -y \
    gcc-c++ \
    cmake \
    ninja-build \
    extra-cmake-modules \
    plasma-sdk \
    plasma-workspace-devel \
    libplasma-devel \
    kf6-kirigami-devel \
    kf6-kirigami-addons-devel \
    kf6-kcoreaddons-devel \
    kf6-kpackage-devel \
    kf6-kconfig-devel \
    kf6-kconfigwidgets-devel \
    kf6-ki18n-devel \
    kf6-kcmutils-devel \
    kf6-kdeclarative-devel \
    kf6-kiconthemes-devel \
    kf6-kitemmodels-devel \
    kf6-ksvg-devel \
    qt6-qtdeclarative-devel \
    qt6-qtbase-devel \
    gettext \
    jq
```

### Essential CLI Verification Matrix

| Tool | Package | Purpose | Verification Command |
| :--- | :--- | :--- | :--- |
| `plasmawindowed` | `plasma-workspace` | Runs a single Plasmoid in an isolated X11/Wayland window | `plasmawindowed --version` |
| `plasmoidviewer` | `plasma-sdk` | Tests Plasmoids under simulated panel/desktop form factors | `plasmoidviewer --version` |
| `kpackagetool6` | `kf6-kpackage` | Installs, upgrades, lists, and uninstalls Plasma packages | `kpackagetool6 --list-types` |
| `qmllint-qt6` | `qt6-qtdeclarative-devel` | Static syntax and type checker for QML files | `qmllint-qt6 --version` |
| `qmlformat-qt6` | `qt6-qtdeclarative-devel` | Automated canonical formatter for QML source | `qmlformat-qt6 --version` |
| `iconexplorer` | `plasma-sdk` | System icon lookup and verification tool | `iconexplorer` |

---

## 3. Canonical Package Structure & Metadata

### Directory Tree

For a pure QML or hybrid Plasmoid with ID `org.example.myplasmoid`:

```
org.example.myplasmoid/
├── metadata.json
├── contents/
│   ├── config/
│   │   ├── main.xml              # KConfigXT schema definition
│   │   └── config.qml             # Configuration category/tab registry
│   ├── ui/
│   │   ├── main.qml               # Primary entry point (Root: PlasmoidItem)
│   │   ├── CompactRepresentation.qml
│   │   ├── FullRepresentation.qml
│   │   └── configGeneral.qml      # Configuration page (Root: KCM.SimpleKCM)
│   └── locale/                    # Compiled gettext translations (.mo)
│       └── fr/LC_MESSAGES/plasma_applet_org.example.myplasmoid.mo
├── CMakeLists.txt                 # Build & install definition (for CMake/C++)
├── README.md
└── LICENSES/
    └── LGPL-2.1-or-later.txt
```

### Filesystem Installation Locations

- **User Local (Rootless / KDE Store):**
  `~/.local/share/plasma/plasmoids/<KPlugin.Id>/`
- **System-Wide (RPM / Distro Packages):**
  `/usr/share/plasma/plasmoids/<KPlugin.Id>/`
- **Runtime Configuration State:**
  `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

### Canonical `metadata.json` Specification

In Plasma 6, all metadata **must** use JSON format (`metadata.desktop` is completely obsolete).

```json
{
    "KPackageStructure": "Plasma/Applet",
    "KPlugin": {
        "Id": "org.example.myplasmoid",
        "Name": "System Pulse",
        "Description": "Monitors system resources with real-time responsive visualization",
        "Icon": "utilities-system-monitor",
        "Category": "System Information",
        "Version": "1.0.0",
        "License": "LGPL-2.1-or-later",
        "Website": "https://github.com/example/system-pulse",
        "BugReportUrl": "https://github.com/example/system-pulse/issues",
        "Authors": [
            {
                "Name": "Developer Name",
                "Email": "dev@example.org"
            }
        ],
        "EnabledByDefault": false
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
```

#### Valid Categories in Plasma 6
- `Accessibility`
- `Application Launchers`
- `Astronomy`
- `Date and Time`
- `Development Tools`
- `Education`
- `Environment and Weather`
- `File System`
- `Fun and Games`
- `Graphics`
- `Language`
- `Mapping`
- `Miscellaneous`
- `Multimedia`
- `Online Services`
- `System Information`
- `Utilities`
- `Windows and Tasks`

---

## 4. Modern Plasma 6 QML & Kirigami API

### Module Import Migrations (Plasma 5 -> Plasma 6)

In Qt 6 / KF6, **all imports are unversioned**. Do not specify numbers like `2.0` or `3.0`.

| Obsolete Plasma 5 Import | Modern Plasma 6 / KF6 Import | Notes |
| :--- | :--- | :--- |
| `import QtQuick 2.15` | `import QtQuick` | Unversioned |
| `import QtQuick.Layouts 1.1` | `import QtQuick.Layouts` | Unversioned |
| `import QtQuick.Controls 2.5 as QQC2` | `import QtQuick.Controls as QQC2` | Unversioned |
| `import org.kde.plasma.plasmoid 2.0` | `import org.kde.plasma.plasmoid` | Unversioned |
| `import org.kde.plasma.core 2.0 as PlasmaCore` | `import org.kde.plasma.core as PlasmaCore` | `PlasmaCore` is trimmed; Svg/Icons moved. |
| `import org.kde.plasma.components 3.0 as PC3` | `import org.kde.plasma.components as PlasmaComponents` | Plasma styling on top of QtQuick Controls |
| `import org.kde.plasma.extras 2.0 as Extras` | `import org.kde.plasma.extras as PlasmaExtras` | Extra Plasma components (e.g. Menu, Heading) |
| `import org.kde.kirigami 2.20 as Kirigami` | `import org.kde.kirigami as Kirigami` | Core UI guidelines, theme, icons |
| `import org.kde.kcmutils 1.0 as KCM` | `import org.kde.kcmutils as KCM` | Mandatory for configuration pages |
| `import org.kde.ksvg 1.0 as KSvg` | `import org.kde.ksvg as KSvg` | Replaces `PlasmaCore.Svg` and `FrameSvgItem` |
| `import org.kde.kitemmodels 1.0` | `import org.kde.kitemmodels as KItemModels` | Replaces `PlasmaCore.SortFilterModel` |

### Root Object: `PlasmoidItem`

The root object of `contents/ui/main.qml` **must be `PlasmoidItem`**.

#### Properties Division: `PlasmoidItem` vs `Plasmoid` Attached Property

| Scope | Member | Type | Purpose / Behavior |
| :--- | :--- | :--- | :--- |
| **`PlasmoidItem`** (Root Item) | `compactRepresentation` | `Component` | Compact icon/widget view (used in panels or collapsed states) |
| **`PlasmoidItem`** | `fullRepresentation` | `Component` | Expanded popup or full canvas view |
| **`PlasmoidItem`** | `preferredRepresentation` | `Representation` | Set to `fullRepresentation` or `compactRepresentation` |
| **`PlasmoidItem`** | `compactRepresentationItem` | `Item` (readonly) | Reference to instantiated compact view |
| **`PlasmoidItem`** | `fullRepresentationItem` | `Item` (readonly) | Reference to instantiated full view |
| **`PlasmoidItem`** | `switchWidth` | `int` | Horizontal size threshold to trigger full representation on desktop |
| **`PlasmoidItem`** | `switchHeight` | `int` | Vertical size threshold to trigger full representation on desktop |
| **`PlasmoidItem`** | `toolTipMainText` | `string` | Primary headline in the widget tooltip |
| **`PlasmoidItem`** | `toolTipSubText` | `string` | Secondary descriptive text in the tooltip |
| **`PlasmoidItem`** | `toolTipItem` | `Component` | Custom QML component for rich tooltips |
| **`PlasmoidItem`** | `hideOnWindowDeactivate` | `bool` | Auto-close popup when focus changes (default: `true`) |
| **`Plasmoid`** (Attached) | `Plasmoid.title` | `string` | User-visible widget title |
| **`Plasmoid`** | `Plasmoid.icon` | `string` | Freedesktop theme icon name |
| **`Plasmoid`** | `Plasmoid.configuration` | `KConfigGroup` | Dynamic configuration key-value store from `main.xml` |
| **`Plasmoid`** | `Plasmoid.formFactor` | `enum` | `Horizontal`, `Vertical`, `Planar` (Desktop), `Application` |
| **`Plasmoid`** | `Plasmoid.location` | `enum` | `Floating`, `Desktop`, `TopEdge`, `BottomEdge`, `LeftEdge`, `RightEdge` |
| **`Plasmoid`** | `Plasmoid.expanded` | `bool` | Read/write toggle state for popup visibility |
| **`Plasmoid`** | `Plasmoid.busy` | `bool` | Displays standard Plasma busy spinner overlay when `true` |
| **`Plasmoid`** | `Plasmoid.contextualActions` | `list<Action>` | List of `PlasmaCore.Action` objects added to context menu |
| **`Plasmoid`** | `Plasmoid.backgroundHints` | `enum` | `DefaultBackground`, `NoBackground`, `ConfigurableBackground` |

### Production `main.qml` Implementation

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Sizing and Representation Strategy
    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    preferredRepresentation: {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return fullRepresentation;
        }
        return compactRepresentation;
    }

    // Tooltip Integration
    toolTipMainText: Plasmoid.title
    toolTipSubText: Plasmoid.configuration.showSubtext
        ? i18n("Tracking active metrics (%1s interval)", Plasmoid.configuration.refreshInterval)
        : ""

    // Context Menu Custom Actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Refresh Now")
            icon.name: "view-refresh"
            priority: PlasmaCore.Action.LowPriorityAction
            onTriggered: root.triggerRefresh()
        }
    ]

    function triggerRefresh() {
        if (fullRepresentationItem && fullRepresentationItem.refresh) {
            fullRepresentationItem.refresh();
        }
    }

    // Compact (Panel) Representation
    compactRepresentation: CompactRepresentation {}

    // Full (Popup / Desktop) Representation
    fullRepresentation: FullRepresentation {}
}
```

### Production `CompactRepresentation.qml`

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                 || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.gridUnit * 3
    Layout.minimumHeight: inPanel ? Kirigami.Units.iconSizes.small : Kirigami.Units.gridUnit * 3
    Layout.preferredWidth: inPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 4
    Layout.preferredHeight: inPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 4

    Kirigami.Icon {
        id: widgetIcon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: Plasmoid.icon || "utilities-system-monitor"
        active: mouseArea.containsMouse
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Plasmoid.expanded = !Plasmoid.expanded
    }
}
```

### Production `FullRepresentation.qml`

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 14
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: Kirigami.Units.gridUnit * 16

    property int refreshCounter: 0

    function refresh() {
        refreshCounter++;
    }

    Timer {
        id: refreshTimer
        interval: Math.max(5, Plasmoid.configuration.refreshInterval) * 1000
        running: Plasmoid.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar
        repeat: true
        triggeredOnStart: true
        onTriggered: fullRoot.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: Plasmoid.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
            }

            PlasmaComponents.Label {
                text: Plasmoid.configuration.customTitle || Plasmoid.title
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                text: i18nc("@action:button", "Refresh")
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: fullRoot.refresh()
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Content Area
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Active Updates: %1", fullRoot.refreshCounter)
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: Plasmoid.configuration.showAlert
                    type: Kirigami.MessageType.Information
                    text: i18n("Notifications and live alerts are active.")
                }
            }
        }
    }
}
```

---

## 5. Configuration Architecture (KConfigXT & KCMUtils)

Plasma 6 configuration is built on three synchronizing components:
1. `contents/config/main.xml`: The type-safe schema compiled into default storage.
2. `contents/config/config.qml`: Registers the pages/tabs loaded into the Settings dialog.
3. `contents/ui/config<Page>.qml`: The UI page implementing `KCM.SimpleKCM` with `cfg_<name>` property aliases.

### 1. `contents/config/main.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
    <kcfgfile name=""/>
    <group name="General">
        <entry name="customTitle" type="String">
            <default>System Pulse</default>
            <label>Custom display title for the widget</label>
        </entry>
        <entry name="refreshInterval" type="Int">
            <default>60</default>
            <min>5</min>
            <max>3600</max>
            <label>Refresh frequency in seconds</label>
        </entry>
        <entry name="showSubtext" type="Bool">
            <default>true</default>
            <label>Whether to show status subtext in tooltip</label>
        </entry>
        <entry name="showAlert" type="Bool">
            <default>false</default>
            <label>Display status banner in full view</label>
        </entry>
    </group>
</kcfg>
```

### 2. `contents/config/config.qml`

```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title:tab", "General")
        icon: "preferences-system"
        source: "configGeneral.qml"
    }
}
```

### 3. `contents/ui/configGeneral.qml`

The root element **must be `KCM.SimpleKCM`** (from `import org.kde.kcmutils as KCM`).

> **Rule for Configuration Binding:**
> The KCM engine automatically inspects the root page for properties named with the `cfg_` prefix (e.g. `cfg_refreshInterval`). It reads initial values from `plasmoid.configuration.<name>`, enables the "Apply" button when edited, and serializes updates when saved.

```qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    // Bindings must match main.xml entry names prefixed with cfg_
    property alias cfg_customTitle: titleField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_showSubtext: subtextCheck.checked
    property alias cfg_showAlert: alertCheck.checked

    Kirigami.FormLayout {
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Custom title:")
            placeholderText: i18n("Enter title…")
            Layout.fillWidth: true
        }

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18nc("@label:spinbox", "Refresh interval (s):")
            from: 5
            to: 3600
            stepSize: 5
            editable: true
        }

        QQC2.CheckBox {
            id: subtextCheck
            Kirigami.FormData.label: i18nc("@label:checkbox", "Tooltip options:")
            text: i18n("Show subtext in tooltip")
        }

        QQC2.CheckBox {
            id: alertCheck
            Kirigami.FormData.label: i18nc("@label:checkbox", "Banner:")
            text: i18n("Show status alert banner")
        }
    }
}
```

---

## 6. Native C++ Plasmoid Architecture

When developing high-performance widgets or complex model-view integrations, build a native C++ QML extension plugin using CMake and KDE Frameworks 6.

### CMake Build Definition (`CMakeLists.txt`)

```cmake
cmake_minimum_required(VERSION 3.20)
project(org.example.myplasmoid VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 6.6.0 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(KF6 6.0.0 REQUIRED COMPONENTS CoreAddons I18n)
find_package(Plasma 6.0.0 REQUIRED)

# 1. Install pure QML / KPackage components
plasma_install_package(contents org.example.myplasmoid)

# 2. Build C++ QML Extension Plugin (Optional backend engine)
add_library(myplasmoidbackend SHARED
    src/backendplugin.cpp
    src/backendplugin.h
    src/systemdatasource.cpp
    src/systemdatasource.h
)

target_link_libraries(myplasmoidbackend
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        KF6::CoreAddons
        KF6::I18n
        Plasma::Plasma
)

install(TARGETS myplasmoidbackend DESTINATION ${KDE_INSTALL_QMLDIR}/org/example/myplasmoid/backend)
install(FILES src/qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/example/myplasmoid/backend)
```

### C++ QML Extension Plugin (`src/backendplugin.h` & `src/backendplugin.cpp`)

```cpp
// src/backendplugin.h
#pragma once
#include <QQmlEngineExtensionPlugin>

class BackendPlugin : public QQmlEngineExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlEngineExtensionInterface_iid)
public:
    BackendPlugin() = default;
};
```

```cpp
// src/systemdatasource.h
#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>

class SystemDataSource : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(double cpuLoad READ cpuLoad NOTIFY cpuLoadChanged)

public:
    explicit SystemDataSource(QObject *parent = nullptr);
    double cpuLoad() const;

    Q_INVOKABLE void requestImmediateScan();

Q_SIGNALS:
    void cpuLoadChanged();

private:
    double m_cpuLoad = 0.0;
};
```

```
# src/qmldir
module org.example.myplasmoid.backend
plugin myplasmoidbackend
```

---

## 7. External Process, D-Bus & Python Integration

When Python or an external script is required, design it as an **independent D-Bus service**.

### Architecture: D-Bus Daemon + QML

```
┌──────────────────────────────────────┐
│       Plasma QML UI Layer            │
│  (DBus client via QML / C++ helper)  │
└──────────────────┬───────────────────┘
                   │ Session D-Bus (e.g. org.example.SystemMonitor)
                   ▼
┌──────────────────────────────────────┐
│      Independent Python Daemon       │
│    (systemd user unit / script)      │
└──────────────────────────────────────┘
```

### 1. Standalone Python D-Bus Service (`daemon.py`)

```python
#!/usr/bin/env python3
"""Isolated system monitoring service publishing data over Session D-Bus."""

import sys
import psutil
from pydbus import SessionBus
from gi.repository import GLib

class SystemService:
    """
    <node>
        <interface name='org.example.SystemMonitor'>
            <method name='GetCpuUsage'>
                <arg type='d' name='usage' direction='out'/>
            </method>
            <method name='GetMemoryUsage'>
                <arg type='d' name='usage' direction='out'/>
            </method>
        </interface>
    </node>
    """

    def GetCpuUsage(self) -> float:
        return float(psutil.cpu_percent(interval=None))

    def GetMemoryUsage(self) -> float:
        return float(psutil.virtual_memory().percent)

def main():
    bus = SessionBus()
    loop = GLib.MainLoop()
    bus.publish("org.example.SystemMonitor", SystemService())
    try:
        loop.run()
    except KeyboardInterrupt:
        sys.exit(0)

if __name__ == "__main__":
    main()
```

### 2. Auto-Activation Configuration
Place a D-Bus service file at `~/.local/share/dbus-1/services/org.example.SystemMonitor.service`:
```ini
[D-BUS Service]
Name=org.example.SystemMonitor
Exec=/usr/bin/python3 /path/to/daemon.py
```

---

## 8. Performance, Lifecycle & Memory Rules

### Critical Performance DOs and DON'Ts

| Anti-Pattern (DO NOT DO) | Correct Pattern (DO THIS) | Technical Reason |
| :--- | :--- | :--- |
| Running timers while the popup is closed. | Bind `Timer.running: Plasmoid.expanded \|\| Plasmoid.formFactor === PlasmaCore.Types.Planar` | Inactive timers wake the CPU and drain laptop batteries. |
| Synchronous file I/O or CLI execution in QML JS. | Perform background reads via C++ `QThreadPool` or async D-Bus calls. | Synchronous calls freeze the entire `plasmashell` UI thread. |
| Complex imperative loops inside property bindings. | Use computed properties or cache values in Qt properties. | Re-evaluating large JS blocks causes frame drops. |
| Hardcoding pixel sizes (e.g. `width: 320`). | Use `Kirigami.Units.gridUnit * 16` and `Kirigami.Units.smallSpacing`. | Hardcoded pixel values break on HiDPI / 4K fractional scaling. |
| Directly updating `plasmoid.configuration` on every keystroke. | Let the KCM `cfg_` property aliases buffer changes until "Apply" is clicked. | Rapid disk writes to `plasma-org.kde.plasma.desktop-appletsrc`. |

---

## 9. Security & Sandboxing Constraints

1. **Subprocess Execution Safety:**
   - **Never** pass concatenated strings to `sh -c` or shell interpreters.
   - In C++, use `QProcess::start(program, QStringList{arg1, arg2})` without shell wrapping.
2. **Secrets & Credentials Management:**
   - **Never** store passwords, OAuth tokens, or API secrets in `main.xml` or `plasmoid.configuration`.
   - `plasma-org.kde.plasma.desktop-appletsrc` is stored unencrypted in plaintext.
   - Use `KF6::Wallet` (`KWallet`) or SecretStorage D-Bus APIs for credentials.
3. **Network Content:**
   - Enforce HTTPS for all network calls.
   - Validate JSON schemas before accessing nested keys to prevent `TypeError` exceptions.

---

## 10. Localization & Internationalization (Ki18n)

### QML Translation Rules
- Always use double quotes for strings inside `i18n()` to ensure proper extraction:
  - `i18n("Active")` (Simple string)
  - `i18nc("@action:button", "Save")` (With context for translators)
  - `i18np("%1 item", "%1 items", count)` (Plural form)
  - `i18ncp("@info:status", "%1 error", "%1 errors", count)` (Context + plural)

### Automated Translation Pipeline

```bash
# 1. Extract strings from QML files into a PO template
xgettext --from-code=UTF-8 \
         --language=JavaScript \
         --keyword=i18n:1 \
         --keyword=i18nc:1c,2 \
         --keyword=i18np:1,2 \
         --keyword=i18ncp:1c,2,3 \
         -o template.pot \
         contents/ui/*.qml

# 2. Compile translated .po files to binary .mo format
msgfmt -o contents/locale/fr/LC_MESSAGES/plasma_applet_org.example.myplasmoid.mo fr.po
```

---

## 11. Testing, Debugging & Diagnostic Toolchain

### 1. Isolated Execution with `plasmawindowed`
Launches the widget in a standalone test window:
```bash
# Run installed widget by ID
plasmawindowed org.example.myplasmoid

# Run with QML JS Debugger enabled
plasmawindowed --qmljsdebugger=port:1234,block org.example.myplasmoid
```

### 2. Multi-Form-Factor Simulation with `plasmoidviewer`
Tests panel vs desktop sizing, constraints, and locations:
```bash
# Test as a Desktop (floating planar) widget
plasmoidviewer -a org.example.myplasmoid -l floating -f planar

# Test as a Bottom Panel (horizontal) widget
plasmoidviewer -a org.example.myplasmoid -l bottomedge -f horizontal

# Test in High-DPI mode (2x scaling)
QT_SCALE_FACTOR=2 plasmoidviewer -a org.example.myplasmoid -l floating -f planar
```

### 3. Live Plasma Shell Reloading
```bash
# Recommended on modern systemd-based sessions (Fedora KDE):
systemctl --user restart plasma-plasmashell.service

# Alternative direct replacement:
plasmashell --replace &
```

### 4. Real-time Debug Logs
```bash
# Stream plasmashell runtime logs
journalctl --user -u plasma-plasmashell.service -f

# Enable Qt debug output
export QT_LOGGING_RULES="*.debug=true;kf.*.debug=true"
```

---

## 12. Quality Gates & Automated Validation Checklist

Run this deterministic validation suite before publishing or tagging a release:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] Validating metadata.json schema..."
jq -e . metadata.json > /dev/null
jq -e '.KPlugin.Id and .KPlugin.Name and .KPlugin.Version and .KPlugin.License' metadata.json > /dev/null
test "$(jq -r '.KPackageStructure' metadata.json)" = "Plasma/Applet"
test "$(jq -r '."X-Plasma-API-Minimum-Version"' metadata.json)" = "6.0"

echo "[2/4] Linting QML files with qmllint-qt6..."
qmllint-qt6 $(find contents/ui/ -name "*.qml")

echo "[3/4] Verifying KPackage structure with kpackagetool6..."
kpackagetool6 -t Plasma/Applet --show org.example.myplasmoid || true

echo "[4/4] Validation successful!"
```

### Release Packaging (.plasmoid)

A `.plasmoid` file is a ZIP archive containing `metadata.json` and `contents/` at the root:

```bash
# Build release archive
zip -r org.example.myplasmoid-1.0.0.plasmoid metadata.json contents/

# Verify archive structure (must show metadata.json at archive root)
unzip -l org.example.myplasmoid-1.0.0.plasmoid
```

---

## 13. AI Coding Agent Operational Protocol

When working with KDE Plasma 6 widget codebases, agents must follow this strict sequence:

### Diagnostic Troubleshooting Tree

```
QML Load Failure / Blank Output
├── 1. Check metadata.json
│   ├── "X-Plasma-API-Minimum-Version": "6.0" present?
│   └── "KPackageStructure": "Plasma/Applet" present?
├── 2. Inspect root element of contents/ui/main.qml
│   └── Is it PlasmoidItem? (Plain Item/Rectangle will fail in Plasma 6)
├── 3. Audit QML Module Imports
│   └── Remove all version numbers (e.g. org.kde.plasma.core 2.0 -> org.kde.plasma.core)
└── 4. Inspect live shell logs
    └── Run: journalctl --user -u plasma-plasmashell.service -f
```

### Strict Agent Directives

- **NEVER** use obsolete versioned imports (e.g. `import org.kde.plasma.core 2.0`).
- **NEVER** use `PlasmaCore.IconItem` (use `Kirigami.Icon`).
- **NEVER** use `PlasmaCore.Svg` or `FrameSvgItem` (use `import org.kde.ksvg as KSvg`).
- **NEVER** use `PlasmaCore.SortFilterModel` (use `import org.kde.kitemmodels as KItemModels`).
- **NEVER** use `Item` as the root of a configuration page (must use `KCM.SimpleKCM`).
- **NEVER** execute raw concatenated shell strings.
- **ALWAYS** test changes using `plasmawindowed` or `plasmoidviewer`.
- **ALWAYS** check runtime logs using `journalctl --user -u plasma-plasmashell.service -f`.

---

## 14. Authoritative References

- [KDE Developer Documentation: Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [KDE Developer Documentation: Porting Plasmoids to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [KDE Developer Documentation: Configuration with KConfigXT](https://develop.kde.org/docs/features/configuration/)
- [KDE Developer Documentation: Kirigami Guidelines](https://develop.kde.org/docs/kirigami/)
- [KDE API Reference (libplasma / AppletInterface)](https://api.kde.org/plasma-index.html)
- [Official Plasma Desktop Applets Repository](https://invent.kde.org/plasma/plasma-desktop/-/tree/master/applets)
- [Official KDE Plasma Add-ons Repository](https://invent.kde.org/plasma/kdeplasma-addons)
