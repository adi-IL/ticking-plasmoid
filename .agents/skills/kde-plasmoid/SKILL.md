---
name: kde-plasmoid
description: "Develop, debug, test, package, and publish KDE Plasma 6 widgets using modern Qt 6, KDE Frameworks 6, Kirigami, and C++ or QML architecture on Linux."
metadata:
  author: Aditya Gaurav
  github: https://github.com/adi-IL
  publisher: adi-IL
  applet_id_prefix: org.adi_il
  license: GPL-3.0-or-later
  version: "2.1.0"
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
---

# KDE Plasma 6 plasmoid development playbook

A production-grade specification and operational manual for developing, debugging, testing, packaging, and publishing KDE Plasma 6 desktop and panel widgets.

## Author identity and repository conventions

Widgets authored under this playbook must adopt the following project defaults:

- Author: Aditya Gaurav
- GitHub profile: https://github.com/adi-IL
- KDE Store publisher: adi-IL
- Applet identifier format: `org.adi_il.<widget_name>`
- Default license: `GPL-3.0-or-later`
- Repository URL format: `https://github.com/adi-IL/<widget_name>-plasmoid`
- Bug report URL format: `https://github.com/adi-IL/<widget_name>-plasmoid/issues`

## Technical baseline and core architecture

### Platform targets

| Component | Minimum version | Reference target | Notes |
| :--- | :--- | :--- | :--- |
| KDE Plasma | 6.0.0 | 6.2 or newer | Plasma 5 APIs and legacy compatibility shims are removed. |
| KDE Frameworks | 6.0.0 | 6.5 or newer | Unversioned QML imports. plasma-framework is split into libplasma, ksvg, and plasma5support. |
| Qt Framework | 6.6.0 | 6.7 or newer | Pure Qt 6 QML and C++20 standard library. |
| Operating system | Linux | Fedora KDE 40 or newer | Native Wayland session with systemd user units. |

### Architecture selection tiers

1. **Tier 1: Pure QML and Kirigami.** Preferred and canonical.
   - UI layer: `PlasmoidItem`, `Kirigami`, and `PlasmaComponents`.
   - Data and logic: Declarative property bindings, JavaScript helper modules, `XMLHttpRequest`, and D-Bus interfaces via `QtDBus`.
   - Zero compilation needed. Distributed directly through KDE Store and GitHub releases.

2. **Tier 2: QML with native C++ plugin.** High performance and system APIs.
   - Used when CPU efficiency, multithreaded background I/O, or custom item models are required.
   - Built using CMake, Extra CMake Modules, and `libplasma`. Installs QML extension plugins into the KDE QML directory.

3. **Tier 3: QML with standalone D-Bus daemon.** External scripts or background services.
   - Used when external Python packages or long-lived system monitors run in background processes.
   - Logic runs in a separate process communicating over the session D-Bus.
   - The QML widget acts as a D-Bus client.

### Python in Plasma 6 rule

The `plasmashell` process is a Qt 6 C++ binary. It does not embed a Python interpreter and cannot execute arbitrary Python scripts inside the shell process. `PySide6` decorators cannot be registered directly into `plasmashell` without a dedicated host binary. Python logic must run as an isolated D-Bus daemon or be invoked asynchronously through subprocess helpers.

## Runtime execution traps and cache mechanics

Plasma development has three pitfalls that cause local edits to be ignored or old state to persist.

### 1. The install path trap

Plasma does not run code directly from git working directories. The desktop shell loads user widgets exclusively from:

```
~/.local/share/plasma/plasmoids/<KPlugin.Id>/
```

Edits inside your git workspace have zero effect on screen until copied into that target directory.

### 2. The bytecode cache trap

The `plasmashell` engine compiles QML files into bytecode and stores them in:

```
~/.cache/plasmashell/qmlcache/
```

If you copy updated files into `~/.local/share/plasma/plasmoids/` without deleting this cache directory, `plasmashell` continues executing stale bytecode. You must delete this cache directory and restart the shell before testing.

### 3. The KConfigXT serialization trap

Every assignment to `Plasmoid.configuration` writes state to disk at:

```
~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

During startup, the applet immediately deserializes cached properties from this file before any network I/O completes. When debugging unexpected initial values or ghost data, inspect this file under your containment and applet IDs.

### 4. Canonical local sync command sequence

```bash
# Copy workspace files to local Plasma applet directory
mkdir -p ~/.local/share/plasma/plasmoids/org.adi_il.<widget_name>
cp -rf contents metadata.json ~/.local/share/plasma/plasmoids/org.adi_il.<widget_name>/

# Clear compiled QML bytecode cache
rm -rf ~/.cache/plasmashell/qmlcache

# Rebuild system configuration cache
kbuildsycoca6 --noincremental > /dev/null 2>&1 || true

# Restart the user desktop shell service
systemctl --user restart plasma-plasmashell.service
```

## Canonical package structure and metadata

### Directory tree

```
org.adi_il.<widget_name>/
├── metadata.json
├── contents/
│   ├── config/
│   │   ├── main.xml              # KConfigXT schema definition
│   │   └── config.qml             # Configuration category registry
│   ├── ui/
│   │   ├── main.qml               # Primary entry point with PlasmoidItem root
│   │   ├── CompactRepresentation.qml
│   │   ├── FullRepresentation.qml
│   │   ├── configGeneral.qml      # Configuration page with KCM.SimpleKCM root
│   │   └── components/            # Reusable views and JavaScript helpers
│   └── locale/                    # Compiled gettext translations (.mo)
│       └── fr/LC_MESSAGES/plasma_applet_org.adi_il.<widget_name>.mo
├── scripts/
│   ├── install.sh                 # Local installation and reload tool
│   ├── package.sh                 # Release packaging tool
│   └── ci-check.py                # Deterministic static safeguards
├── LICENSES/
│   └── GPL-3.0-or-later.txt
├── README.md
└── LICENSE
```

### Canonical metadata.json specification

Plasma 6 requires JSON metadata. The legacy `metadata.desktop` format is unsupported.

```json
{
    "KPackageStructure": "Plasma/Applet",
    "KPlugin": {
        "Authors": [
            {
                "Email": "mr.x.l.r.8.pride@gmail.com",
                "Name": "Aditya Gaurav"
            }
        ],
        "BugReportUrl": "https://github.com/adi-IL/ticking-plasmoid/issues",
        "Category": "Date and Time",
        "Description": "Precision horizon tracker and AI quote companion.",
        "Icon": "chronometer",
        "Id": "org.adi_il.ticking",
        "License": "GPL-3.0-or-later",
        "Name": "Ticking: Horizon and Time HUD",
        "Version": "1.5.1",
        "Website": "https://github.com/adi-IL/ticking-plasmoid"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
```

## Modern Plasma 6 QML and Kirigami API

### Unversioned module imports

In Qt 6 and KF6, all QML imports must omit version numbers.

| Obsolete Plasma 5 import | Modern Plasma 6 import |
| :--- | :--- |
| `import QtQuick 2.15` | `import QtQuick` |
| `import QtQuick.Layouts 1.1` | `import QtQuick.Layouts` |
| `import QtQuick.Controls 2.5 as QQC2` | `import QtQuick.Controls as QQC2` |
| `import org.kde.plasma.plasmoid 2.0` | `import org.kde.plasma.plasmoid` |
| `import org.kde.plasma.core 2.0 as PlasmaCore` | `import org.kde.plasma.core as PlasmaCore` |
| `import org.kde.plasma.components 3.0 as PC3` | `import org.kde.plasma.components as PlasmaComponents` |
| `import org.kde.plasma.extras 2.0 as Extras` | `import org.kde.plasma.extras as PlasmaExtras` |
| `import org.kde.kirigami 2.20 as Kirigami` | `import org.kde.kirigami as Kirigami` |
| `import org.kde.kcmutils 1.0 as KCM` | `import org.kde.kcmutils as KCM` |
| `import org.kde.ksvg 1.0 as KSvg` | `import org.kde.ksvg as KSvg` |
| `import org.kde.kitemmodels 1.0` | `import org.kde.kitemmodels as KItemModels` |

### Critical QML syntax rules

1. **Root object requirement.** The root item in `contents/ui/main.qml` must be `PlasmoidItem`. Plain `Item` or `Rectangle` causes load failures in Plasma 6.
2. **Configuration page requirement.** The root item of settings pages must be `KCM.SimpleKCM`.
3. **Action priority names.** PlasmaCore action priority uses `PlasmaCore.Action.LowPriority`, `NormalPriority`, or `HighPriority`. The names `LowPriorityAction` and `NormalPriorityAction` are invalid.
4. **Font assignment restrictions.** Never assign a whole font object and then set a subproperty in the same block. QML rejects double font assignment.
5. **Object literal binding restrictions.** Property bindings defined as object literals cannot embed `var` or `return` statements. Compute those values in separate properties.
6. **No em dashes.** User facing QML strings must avoid Unicode em dashes to maintain clean typography. Use commas or periods instead.

### Production main.qml implementation

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 14

    // Remove the default Plasma frame when drawing custom card surfaces
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    preferredRepresentation: {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return fullRepresentation;
        }
        return compactRepresentation;
    }

    toolTipMainText: Plasmoid.title
    toolTipSubText: Plasmoid.configuration.showSubtext
        ? i18n("Active interval: %1s", Plasmoid.configuration.refreshInterval)
        : ""

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu", "Refresh metrics")
            icon.name: "view-refresh"
            priority: PlasmaCore.Action.LowPriority
            onTriggered: root.triggerRefresh()
        }
    ]

    function triggerRefresh() {
        if (fullRepresentationItem && fullRepresentationItem.refresh) {
            fullRepresentationItem.refresh();
        }
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
```

### Production CompactRepresentation.qml

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
        source: Plasmoid.icon || "chronometer"
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

## Configuration architecture with KConfigXT and KCMUtils

Configuration synchronization uses three linked files:

1. `contents/config/main.xml`: Type-safe XML schema compiled into default storage.
2. `contents/config/config.qml`: Category registration model.
3. `contents/ui/configGeneral.qml`: UI page using `KCM.SimpleKCM` with `cfg_<name>` property aliases.

### 1. contents/config/main.xml

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
            <label>Display status subtext in tooltip</label>
        </entry>
        <entry name="themeMode" type="String">
            <default>obsidian</default>
            <label>Visual styling mode</label>
        </entry>
    </group>
</kcfg>
```

### 2. contents/config/config.qml

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

### 3. contents/ui/configGeneral.qml

```qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_customTitle: titleField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_showSubtext: subtextCheck.checked

    Kirigami.FormLayout {
        QQC2.TextField {
            id: titleField
            Kirigami.FormData.label: i18nc("@label:textbox", "Custom title:")
            placeholderText: i18n("Enter title...")
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
    }
}
```

## Obsidian glass theme and visual design standards

Custom desktop widgets must adhere to the Obsidian glass visual hierarchy:

1. **Card foundation.** Use `Kirigami.ShadowedRectangle` with rounded corners (radius 12), dark translucent fill (`Qt.rgba(0.03, 0.03, 0.03, 0.88)`), subtle 1px border (`Qt.rgba(1, 1, 1, 0.09)`), and deep drop shadows.
2. **Interactive specular glint.** Render a 1px specular beam along the top edge using a horizontal gradient. Position the brightest stop dynamically to follow `mouseArea.mouseX`.
3. **Pulsing live badge.** Display an indicator pill with subtle border and text. An inner circle pulses using `SequentialAnimation on opacity` running only when the widget is visible.
4. **Adaptive grid units.** All widths, heights, margins, and paddings must derive from `Kirigami.Units.gridUnit`, `Kirigami.Units.smallSpacing`, and `Kirigami.Units.largeSpacing`. Never hardcode raw pixel values.
5. **Text wrapping and graceful downsizing.** Long quotes or titles must enable `Text.Wrap`. Drop font sizes to `Kirigami.Theme.smallFont.pointSize` when string length exceeds 120 characters to prevent clipping.

```qml
// Example specular beam implementation
Rectangle {
    id: specularBeam
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 1
    height: 1
    radius: 1
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
        GradientStop {
            position: Math.max(0.05, Math.min(0.95, mouseTracker.mouseX / Math.max(1, parent.width)))
            color: mouseTracker.containsMouse ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.20)
        }
        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
    }
}
```

## Sub-second ticker and timer architecture

Widgets that render high-frequency time updates (such as countdown centiseconds or stopwatch split-times) must throttle timer intervals according to visibility and tab selection.

### Multi-mode throttling rules

1. **Hidden or collapsed state.** When `Plasmoid.expanded` is false and form factor is not planar, interval drops to 30,000ms or 60,000ms. If a background stopwatch is actively running, throttle to 1,000ms. Never tick at sub-second rates when hidden.
2. **Active stopwatch view.** When visible and measuring elapsed time, tick at 40ms (25 frames per second).
3. **Active countdown centisecond view.** When visible and displaying fractional seconds, tick at 100ms (10 frames per second).
4. **Standard clock view.** Tick at 1,000ms (1 frame per second).

```qml
Timer {
    id: tickerTimer
    interval: {
        var isVisible = (Plasmoid.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar);
        if (!isVisible) {
            if (root.stopwatchRunning) {
                return 1000;
            }
            return (Plasmoid.configuration.showPanelBadge !== false) ? 30000 : 60000;
        }
        if (root.currentViewIndex === 2) {
            return root.stopwatchRunning ? 40 : 1000;
        }
        if (root.currentViewIndex === 0) {
            return Plasmoid.configuration.showMilliseconds ? 100 : 1000;
        }
        return 1000;
    }
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.updateAllMetrics()
}
```

## AI service and network integration doctrine

When connecting desktop widgets to remote LLM endpoints (such as OpenCode Zen at `https://opencode.ai/zen/v1/chat/completions`), apply these operational safeguards.

### 1. Mandatory session header

Free tier models (such as `nemotron-3-ultra-free` and `nemotron-3.5-lightning-free`) require the `x-session-id` header on every HTTP request. Omission causes HTTP 400 with the error message `MissingSessionID`.

```javascript
xhr.setRequestHeader("x-session-id", "ticking-" + Date.now());
```

### 2. Model whitelisting and fallback cascade

Paid models return HTTP 401 `CreditsError` when called with free API keys. Whitelist candidate models and cascade across them before falling back to local curated storage:

```javascript
var REMOTE_MODELS = [
    "nemotron-3-ultra-free",
    "nemotron-3.5-lightning-free"
];
```

### 3. Error envelopes inside HTTP 200

Proxy services occasionally return HTTP status 200 containing a JSON error envelope. Always verify the payload does not contain an `error` key before reading completions:

```javascript
var res = JSON.parse(xhr.responseText);
if (res.error) {
    console.warn("Upstream error on model", modelName, res.error.message);
    tryNextModel();
    return;
}
```

### 4. Author commentary sanitization

Reasoning models frequently append commentary, explanations, or disclaimers to the author field. The parser must clean this string:

- Remove `<think>` blocks and preamble phrases.
- Cut off sentences continuing after the author name at the first period, unless the text matches an abbreviated initial such as `C.S. Lewis`.
- Cut off trailing explanatory phrases after commas or dashes.
- Reject attribution commentary such as `Attributed to high-performance coaching circles`.
- If the sanitized author name is empty or longer than 45 characters, discard the result and try the next candidate.

```javascript
function cleanQuoteAuthor(author) {
    if (!author || typeof author !== "string") return "";
    var cleaned = author.trim();

    cleaned = cleaned.replace(/^["'\u201c\u201d\u00ab\u00bb]+|["'\u201c\u201d\u00ab\u00bb]+$/g, "").trim();

    if (/^(attributed to|possibly|maybe|this is|that's|probably|unknown|an? \w+ quote|not fitting|unattributed|anonymous|n\/a)/i.test(cleaned)) {
        return "";
    }

    var periodIdx = cleaned.indexOf(". ");
    if (periodIdx !== -1) {
        var beforePeriod = cleaned.substring(0, periodIdx).trim();
        if (!/^[A-Z]\.?\s*[A-Z]?\.?$/.test(beforePeriod)) {
            cleaned = beforePeriod;
        }
    }

    cleaned = cleaned.replace(/,\s*(?:which|who|that|a|an|the|as|noting|explaining|saying)[\s\S]*$/i, "");
    cleaned = cleaned.replace(/\s+-\s+.*$/, "");
    cleaned = cleaned.replace(/[.\-,;:\s]+$/, "").trim();

    if (cleaned.length > 45 || cleaned.length === 0) {
        return "";
    }
    return cleaned;
}
```

### 5. Topic rotation and negative constraints

Static prompts cause LLMs to generate identical quotes on every refresh. Rotate subtopics randomly within the active archetype, and inject the currently displayed quote as a negative constraint in the prompt:

```javascript
var prompt = "Famous quote about " + topic + ".";
if (currentQuote.length > 10) {
    var quoteSnippet = currentQuote.replace(/["\n]/g, "").slice(0, 35);
    prompt += " Do NOT provide the quote: \"" + quoteSnippet + "...\"";
    if (currentAuthor.length > 0) {
        prompt += " or any quote by " + currentAuthor;
    }
    prompt += ".";
}
prompt += " 1 line only: \"Quote\" - Author Name";
```

## Developer tooling and automation templates

### 1. Local installation helper: scripts/install.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ID="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Id"])')"
TARGET_DIR="${HOME}/.local/share/plasma/plasmoids/${ID}"

RESTART=false
VIEWER=false

for arg in "$@"; do
    case "$arg" in
        --restart|-r)
            RESTART=true
            ;;
        --viewer|-v)
            VIEWER=true
            ;;
        *)
            echo "Usage: $0 [--restart|-r] [--viewer|-v]"
            exit 1
            ;;
    esac
done

echo "==> Syncing files to ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"
cp -f metadata.json "${TARGET_DIR}/"
cp -rf contents "${TARGET_DIR}/"
if [[ -d po ]]; then
    cp -rf po "${TARGET_DIR}/"
fi

echo "==> Clearing QML bytecode cache..."
rm -rf ~/.cache/plasmashell/qmlcache

echo "==> Updating KDE system configuration cache..."
kbuildsycoca6 --noincremental > /dev/null 2>&1 || true

if [ "$RESTART" = true ]; then
    echo "==> Restarting plasma-plasmashell service..."
    systemctl --user restart plasma-plasmashell.service
fi

if [ "$VIEWER" = true ]; then
    echo "==> Launching plasmoidviewer..."
    plasmoidviewer -a "${TARGET_DIR}"
fi

echo "==> Finished."
```

### 2. Release packaging tool: scripts/package.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ID="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Id"])')"
VER="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')"
OUT="${ID}-${VER}.plasmoid"

STAGE="$(mktemp -d)"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

mkdir -p "$STAGE/$ID"
cp metadata.json "$STAGE/$ID/"
cp -a contents "$STAGE/$ID/"
if [[ -d po ]]; then
    cp -a po "$STAGE/$ID/"
fi

rm -f "$OUT"
(
    cd "$STAGE"
    zip -r -q "$ROOT/$OUT" "$ID"
)

echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"
```

### 3. Deterministic static safeguards: scripts/ci-check.py

```python
#!/usr/bin/env python3
"""Static safeguards for Plasma 6 plasmoids."""
from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
warnings: list[str] = []

def fail(msg: str) -> None:
    errors.append(msg)

def warn(msg: str) -> None:
    warnings.append(msg)

def check_metadata() -> dict | None:
    path = ROOT / "metadata.json"
    if not path.is_file():
        fail("metadata.json missing")
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"metadata.json is not valid JSON: {exc}")
        return None

    if data.get("KPackageStructure") != "Plasma/Applet":
        fail('metadata.json KPackageStructure must be "Plasma/Applet"')

    plugin = data.get("KPlugin") or {}
    for key in ("Id", "Name", "Version", "License", "Authors"):
        if key not in plugin:
            fail(f"metadata.json missing KPlugin.{key}")

    plugin_id = plugin.get("Id", "")
    if not plugin_id.startswith("org.adi_il."):
        warn(f'plugin Id "{plugin_id}" does not use org.adi_il prefix')

    version = str(plugin.get("Version", ""))
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        fail(f'version "{version}" is not semver X.Y.Z')

    api = data.get("X-Plasma-API-Minimum-Version")
    if not api or not str(api).startswith("6"):
        fail(f"X-Plasma-API-Minimum-Version must be 6.x (got {api!r})")

    return data

def check_no_em_dash_in_qml() -> None:
    em = "\u2014"
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if em in line:
                rel = path.relative_to(ROOT)
                fail(f"{rel}:{i}: em dash found in QML; use comma or period")

def check_qml_action_priority() -> None:
    bad = re.compile(r"PlasmaCore\.Action\.(LowPriorityAction|NormalPriorityAction|HighPriorityAction)")
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        text = path.read_text(encoding="utf-8")
        for i, line in enumerate(text.splitlines(), 1):
            if bad.search(line):
                rel = path.relative_to(ROOT)
                fail(f"{rel}:{i}: invalid Action priority name (use LowPriority or NormalPriority)")

def check_qml_font_double_assign() -> None:
    pair_re = re.compile(r"^\s*font\s*:")
    sub_re = re.compile(r"^\s*font\.")
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        lines = path.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines):
            if not pair_re.match(line):
                continue
            for j in range(i + 1, min(i + 8, len(lines))):
                nxt = lines[j]
                if not nxt.strip() or nxt.strip().startswith("//"):
                    continue
                if sub_re.match(nxt):
                    rel = path.relative_to(ROOT)
                    fail(f"{rel}:{i + 1}: whole font assigned then font subproperty set at line {j + 1}")
                break

def main() -> int:
    check_metadata()
    check_no_em_dash_in_qml()
    check_qml_action_priority()
    check_qml_font_double_assign()

    for w in warnings:
        print(f"WARNING: {w}")
    if errors:
        print(f"FAILED ({len(errors)} error(s)):")
        for e in errors:
            print(f"  - {e}")
        return 1

    print("OK: all static safeguards passed.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

### 4. GitHub Actions release workflow: .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    tags:
      - "v*"
  workflow_dispatch:
    inputs:
      dry_run:
        description: "Build package only without uploading release"
        type: boolean
        default: true

permissions:
  contents: write

jobs:
  release:
    name: Build and publish
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Run static safeguards
        run: python3 scripts/ci-check.py

      - name: Resolve version and package name
        id: ver
        run: |
          set -euo pipefail
          META_VER=$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')
          ID=$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Id"])')
          TAG="${GITHUB_REF_NAME:-}"
          if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
            TAG_VER="${TAG#v}"
            if [[ "$TAG_VER" != "$META_VER" ]]; then
              echo "Tag $TAG does not match metadata version $META_VER" >&2
              exit 1
            fi
          fi
          echo "version=$META_VER" >> "$GITHUB_OUTPUT"
          echo "id=$ID" >> "$GITHUB_OUTPUT"
          echo "artifact=${ID}-${META_VER}.plasmoid" >> "$GITHUB_OUTPUT"

      - name: Build plasmoid archive
        run: |
          chmod +x scripts/package.sh
          ./scripts/package.sh
          test -f "${{ steps.ver.outputs.artifact }}"

      - name: Publish GitHub release
        if: (github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')) || (github.event_name == 'workflow_dispatch' && inputs.dry_run == false)
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          TAG="v${{ steps.ver.outputs.version }}"
          ART="${{ steps.ver.outputs.artifact }}"
          if gh release view "$TAG" >/dev/null 2>&1; then
            gh release upload "$TAG" "$ART" --clobber
          else
            gh release create "$TAG" "$ART" \
              --title "${{ steps.ver.outputs.id }} v${{ steps.ver.outputs.version }}" \
              --generate-notes \
              --verify-tag
          fi
```

## Diagnostic troubleshooting tree

```
QML Load Failure or Blank Output
├── 1. Check metadata.json
│   ├── "X-Plasma-API-Minimum-Version": "6.0" present?
│   └── "KPackageStructure": "Plasma/Applet" present?
├── 2. Inspect root element of contents/ui/main.qml
│   └── Is it PlasmoidItem? (Plain Item or Rectangle will fail in Plasma 6)
├── 3. Audit QML module imports
│   └── Remove all version numbers (e.g. org.kde.plasma.core)
├── 4. Clear bytecode cache
│   └── rm -rf ~/.cache/plasmashell/qmlcache
└── 5. Inspect live shell logs
    └── journalctl --user -u plasma-plasmashell.service -f
```

## Strict agent directives

- Never use versioned QML imports.
- Never use `PlasmaCore.IconItem`. Use `Kirigami.Icon`.
- Never use `PlasmaCore.Svg` or `FrameSvgItem`. Use `import org.kde.ksvg as KSvg`.
- Never use `PlasmaCore.SortFilterModel`. Use `import org.kde.kitemmodels as KItemModels`.
- Never use plain `Item` as the root of a configuration page. Use `KCM.SimpleKCM`.
- Never assign whole `font:` objects and subproperties in the same element.
- Never execute raw shell string concatenation.
- Always verify changes locally using `scripts/install.sh --viewer` or `scripts/install.sh --restart`.
- Always verify logs using `journalctl --user -u plasma-plasmashell.service -f`.

## Authoritative references

- KDE Developer Documentation: https://develop.kde.org/docs/plasma/widget/
- Porting Plasmoids to KF6: https://develop.kde.org/docs/plasma/widget/porting_kf6/
- Configuration with KConfigXT: https://develop.kde.org/docs/features/configuration/
- Kirigami UI Guidelines: https://develop.kde.org/docs/kirigami/
- libplasma API Reference: https://api.kde.org/plasma-index.html
- Official KDE Plasma Desktop Applets: https://invent.kde.org/plasma/plasma-desktop/-/tree/master/applets
- Official KDE Plasma Add-ons: https://invent.kde.org/plasma/kdeplasma-addons
