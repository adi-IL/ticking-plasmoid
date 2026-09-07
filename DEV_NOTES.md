# Ticking Plasmoid — Developer Guide & Technical Notes

A comprehensive operational manual and architectural guide for developing, debugging, testing, extending, and maintaining **Ticking** on KDE Plasma 6.

---

## Table of Contents

1. [Architectural Overview & Codebase Anatomy](#1-architectural-overview--codebase-anatomy)
2. [Prerequisites & Development Toolchain](#2-prerequisites--development-toolchain)
3. [The Fast Inner Dev Loop](#3-the-fast-inner-dev-loop)
4. [State Management, Timers & Performance](#4-state-management-timers--performance)
5. [Configuration & KConfigXT Schema](#5-configuration--kconfigxt-schema)
6. [Quote Engine & LLM Integration](#6-quote-engine--llm-integration)
7. [UI & Aesthetic System (Obsidian Glass)](#7-ui--aesthetic-system-obsidian-glass)
8. [Automated Testing & CI Safeguards](#8-automated-testing--ci-safeguards)
9. [Packaging & Publishing Pipeline](#9-packaging--publishing-pipeline)
10. [Troubleshooting & Common Pitfalls](#10-troubleshooting--common-pitfalls)

---

## 1. Architectural Overview & Codebase Anatomy

Ticking is a **Tier 1 (Pure QML/JS)** Plasmoid built for **KDE Plasma 6** and **Qt 6**. It requires zero C++ compilation and is distributed directly as a `.plasmoid` bundle.

### Component Hierarchy

```
                    ┌──────────────────────────────┐
                    │    contents/ui/main.qml      │
                    │       (PlasmoidItem)         │
                    │  - Master state & properties │
                    │  - Horizon date math         │
                    │  - Adaptive timer engine     │
                    │  - Quote fetch controller    │
                    └──────────────┬───────────────┘
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
┌──────────────────────────────┐            ┌──────────────────────────────┐
│  CompactRepresentation.qml   │            │   FullRepresentation.qml     │
│  (Panel mode icon & badge)   │            │  (Desktop HUD & Panel Popup) │
└──────────────────────────────┘            └──────────────┬───────────────┘
                                                           │
              ┌────────────────────────────┬───────────────┴────────────┐
              ▼                            ▼                            ▼
   ┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
   │ components/          │     │ components/          │     │ components/          │
   │ CountdownView.qml    │     │ ClockView.qml        │     │ StopwatchView.qml    │
   │ - Tabular cards      │     │ - World clock        │     │ - Split lap history  │
   │ - 10 FPS ticker      │     │ - 12h/24h toggle     │     │ - 25 FPS ticker      │
   │ - Progress bar       │     │ - UTC / ISO week     │     │ - Persistent state   │
   └──────────────────────┘     └──────────────────────┘     └──────────────────────┘
              │                            │                            │
              └────────────────────────────┼────────────────────────────┘
                                           ▼
                                ┌──────────────────────┐
                                │ components/          │
                                │ QuoteBar.qml         │
                                │ - Adaptive glass box │
                                │ - Rotating refresh   │
                                │ - One-click copy     │
                                └──────────┬───────────┘
                                           │
                        ┌──────────────────┴──────────────────┐
                        ▼                                     ▼
             ┌──────────────────────┐              ┌──────────────────────┐
             │ components/          │              │ components/          │
             │ QuoteClient.js       │              │ QuoteLibrary.js      │
             │ - OpenCode Zen API   │              │ - 40+ curated quotes │
             │ - Fallback cascade   │              │ - 4 archetype pools  │
             │ - Sanitizer / regex  │              │ - Progress-tier logic│
             │ - Topic rotation     │              │ - Duplicate filter   │
             └──────────────────────┘              └──────────────────────┘
```

### File Map

| Path | Purpose |
| :--- | :--- |
| `metadata.json` | KPlugin metadata (ID: `org.adi_il.ticking`, semver, Plasma 6 API declaration). |
| `contents/config/main.xml` | KConfigXT declarative schema defining all persisted settings and default values. |
| `contents/config/config.qml` | Declares the settings categories presented in Plasma's configuration dialog. |
| `contents/ui/main.qml` | Root `PlasmoidItem` managing application lifecycle, horizon dates, timer intervals, and quote dispatching. |
| `contents/ui/FullRepresentation.qml` | The primary UI layout for desktop widgets and expanded panel popups. |
| `contents/ui/CompactRepresentation.qml` | Panel representation showing an icon with an optional dynamic remaining-time badge. |
| `contents/ui/configGeneral.qml` | User-facing settings dialog (calendar pickers, presets, theme selector, quote archetype, API keys). |
| `contents/ui/components/` | Sub-views (`CountdownView.qml`, `ClockView.qml`, `StopwatchView.qml`), UI widgets (`QuoteBar.qml`, `SegmentedNav.qml`), and JavaScript service libraries (`QuoteClient.js`, `QuoteLibrary.js`, `Theme.js`). |
| `scripts/` | Tooling: `install.sh` (local dev deployment), `test-quotes.js` (quote engine test suite), `ci-check.py` (static linter/guard), `package.sh` (build `.plasmoid` zip), `extract-messages.py` (i18n catalog extraction). |

---

## 2. Prerequisites & Development Toolchain

### Required Packages

#### Fedora (40+)
```bash
sudo dnf install -y \
    plasma-sdk \
    libplasma-devel \
    kf6-kirigami-devel \
    kf6-kcoreaddons-devel \
    kf6-kpackage-devel \
    kf6-kconfig-devel \
    qt6-qtdeclarative-devel \
    nodejs \
    python3
```

#### Arch Linux
```bash
sudo pacman -S --needed \
    plasma-sdk \
    libplasma \
    kirigami \
    kcoreaddons \
    kpackage \
    kconfig \
    qt6-declarative \
    nodejs \
    python
```

#### Ubuntu / Debian (Plasma 6 / KDE Neon)
```bash
sudo apt install -y \
    plasma-sdk \
    libplasma-dev \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-plasma-core \
    qml6-module-org-kde-plasma-components \
    nodejs \
    python3
```

---

## 3. The Fast Inner Dev Loop

### A. Quick Local Installation & Live Reload

We provide a developer script `scripts/install.sh` that synchronizes local changes to `~/.local/share/plasma/plasmoids/org.adi_il.ticking`, purges the QML bytecode cache, and updates KDE system caches:

```bash
# Sync files to local plasmoid directory and clear QML cache:
./scripts/install.sh

# Sync files AND automatically restart plasmashell:
./scripts/install.sh --restart

# Sync files AND launch in isolated plasmoidviewer:
./scripts/install.sh --viewer
```

### B. Isolated Testing with `plasmoidviewer`

Iterate on QML layouts without restarting your entire desktop:

```bash
# Test desktop widget form factor:
plasmoidviewer -a .

# Test panel representation form factor:
plasmoidviewer -a . -f horizontal
```

> **Wayland Notice:** If `plasmoidviewer` fails to spawn on Wayland, run it under XWayland fallback:
> ```bash
> QT_QPA_PLATFORM=xcb plasmoidviewer -a .
> ```

### C. Live Log Inspection

When running inside the live `plasmashell` process, monitor logs in real time:

```bash
journalctl --user -u plasma-plasmashell.service -f | grep -i ticking
```

### D. Runtime Configuration File

Plasma persists widget configuration in:
```
~/.config/plasma-org.kde.plasma.desktop-appletsrc
```
Look for the applet section corresponding to `org.adi_il.ticking` (e.g. `[Containments][...][Applets][...][Configuration][General]`).

---

## 4. State Management, Timers & Performance

### Adaptive Tick Rate Architecture

Running desktop widgets at high tick rates destroys laptop battery life. Ticking uses an **adaptive ticker** inside `main.qml` that adjusts its interval based on UI visibility and active view:

| Mode | Interval | Condition | Purpose |
| :--- | :--- | :--- | :--- |
| **High Frequency (Stopwatch)** | **40 ms** (25 FPS) | Active tab is Stopwatch AND stopwatch is actively running. | Smooth millisecond counter. |
| **Centisecond Ticker** | **100 ms** (10 FPS) | Full HUD visible AND active tab is Countdown AND `showMilliseconds` is true. | Crisp centisecond update without overloading QML engine. |
| **Standard Desktop Clock** | **1000 ms** (1 s) | Full HUD visible AND active tab is Clock (or Countdown without milliseconds). | Normal 1-second second-hand tick. |
| **Panel Badge Idle** | **30,000 ms** (30 s) | Collapsed in panel mode AND `showPanelBadge` is enabled. | Updates remaining hours/days on panel without CPU drain. |
| **Panel Sleeping** | **60,000 ms** (60 s) | Collapsed in panel mode AND badge is disabled. | Near-zero CPU utilization. |

### Visibility Suppression

Remote network calls and quote refreshes are **strictly suppressed** when the plasmoid is hidden or collapsed:
```qml
// main.qml
Timer {
    id: quoteTimer
    interval: Math.max(1, Plasmoid.configuration.quoteIntervalMinutes) * 60 * 1000
    running: Plasmoid.configuration.showQuoteBar && root.visible
    repeat: true
    onTriggered: root.fetchNextQuote(false)
}
```

### Date Math & Civil Time

Horizon targets are stored as civil calendar dates (`YYYY-MM-DD`) at local midnight:
```javascript
function parseHorizonDate(dateStr) {
    if (!dateStr || typeof dateStr !== "string") return null;
    var parts = dateStr.trim().split("-");
    if (parts.length === 3) {
        var y = parseInt(parts[0], 10);
        var m = parseInt(parts[1], 10) - 1;
        var d = parseInt(parts[2], 10);
        return new Date(y, m, d, 0, 0, 0, 0);
    }
    return null;
}
```
This guarantees consistent countdown milestones regardless of daylight saving time shifts or system timezone adjustments.

### State Persistence Across Plasma Restarts

Stopwatch state and split laps are persisted directly into KConfigXT:
- `stopwatchRunning`: boolean indicating whether the timer was active when Plasma exited.
- `stopwatchElapsedMs`: accumulated time in milliseconds.
- `stopwatchStartTimestamp`: Epoch timestamp recorded at start.
- `stopwatchLapsJson`: JSON serialized array of split laps (`[{ "lapNumber": 1, "lapTimeMs": 1420, "splitTimeMs": 1420 }]`).

When Plasma starts up, `main.qml` reconciles `Date.now() - stopwatchStartTimestamp` to seamlessly resume running stopwatches without loss of precision.

---

## 5. Configuration & KConfigXT Schema

All persisted configuration **MUST** be declared in `contents/config/main.xml`.

### Adding a New Configuration Entry

#### Step 1: Declare in `contents/config/main.xml`
```xml
<entry name="myNewSetting" type="Bool">
    <default>true</default>
</entry>
```

#### Step 2: Bind in UI Component
Access the setting reactively anywhere in QML:
```qml
visible: Plasmoid.configuration.myNewSetting
```

#### Step 3: Add UI Control in `contents/ui/configGeneral.qml`
Use the KDE KConfigXT convention: prefix the control's property with `cfg_`:
```qml
Kirigami.FormLayout {
    QQC2.CheckBox {
        Kirigami.FormData.label: i18n("My New Feature:")
        id: cfg_myNewSetting
        text: i18n("Enable experimental mode")
    }
}
```
The Plasma configuration engine automatically links `cfg_myNewSetting` with `Plasmoid.configuration.myNewSetting`—no manual signal wiring is required!

#### Step 4: Register in `scripts/ci-check.py`
Add the key to the `expected` dictionary in `scripts/ci-check.py` so continuous integration guards pass.

---

## 6. Quote Engine & LLM Integration

The Quote Engine operates in dual mode:
1. **Offline Mode:** Zero network calls; draws from a curated catalog of 40+ timeless quotes across 4 distinct archetypes.
2. **Online Mode:** Uses the **OpenCode Zen API** to generate targeted, context-aware philosophical quotes using remote reasoning models.

### OpenCode Zen Free-Tier Protocol

OpenCode Zen exposes OpenAI-compatible endpoints (`https://opencode.ai/zen/v1/chat/completions`) with two critical protocol requirements:
1. **Session Identification:** All requests to free models (`nemotron-3-ultra-free`, `nemotron-3.5-lightning-free`) **MUST include the `x-session-id` header**. Without this header, the server rejects the request with `HTTP 400 MissingSessionID`.
2. **Model Whitelist:** Free API keys only have access to models ending in `-free`. Paid models return `HTTP 401 CreditsError`.

```javascript
// QuoteClient.js
xhr.open("POST", "https://opencode.ai/zen/v1/chat/completions", true);
xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
xhr.setRequestHeader("Content-Type", "application/json");
xhr.setRequestHeader("x-session-id", "ticking-" + Date.now());
```

### Multi-Model Fallback Cascade

To guarantee that the UI never hangs or displays an error banner:
```
OpenCode Zen: nemotron-3-ultra-free (timeout: 25s)
         │
         ▼ (on error, 4xx/5xx, or timeout)
OpenCode Zen: nemotron-3.5-lightning-free (timeout: 25s)
         │
         ▼ (on error, 4xx/5xx, or timeout)
Curated Offline Library (QuoteLibrary.js)
```

### Anti-Pollution & Sanitization Pipeline

Reasoning models (like Nemotron) often generate `<think>` tokens, conversational preambles, or conversational commentary after the author name. `QuoteClient.js` enforces strict sanitization:

1. **Tag Stripping:** Strips `<think>...</think>` tags and reasoning blocks.
2. **Preamble Removal:** Strips `Here is a quote:`, `Sure!`, `Option 1:`, etc.
3. **Author Sentence Cutting:** Splits on `. ` to remove commentary following names (`"Bruce Lee. That's a quote about focus..."` -> `"Bruce Lee"`).
4. **Attribution Noise Rejection:** Rejects lines starting with `Attributed to...`, `Probably...`, `Maybe...`, or length `> 45` characters. If an author is rejected, the client cascades.
5. **Dynamic Subtopic Diversification:** Rotates through rich archetype subtopics (`ARCHETYPE_TOPICS`) and injects a negative constraint into the prompt (`Do NOT provide the quote: "..." or by <Author>`) to ensure manual refreshes never repeat the same quote.

### Running the Quote Test Suite

A standalone test suite validates all sanitization, parsing, curated pools, and live OpenCode Zen API requests:

```bash
# Run standalone unit test suite:
node scripts/test-quotes.js

# Test live API generation with your API key:
OPENCODE_ZEN_API_KEY="sk-..." node scripts/test-quotes.js
```

---

## 7. UI & Aesthetic System (Obsidian Glass)

Ticking features a custom **Obsidian Glass** aesthetic inspired by Linear and Vercel dark mode, alongside native KDE Plasma system styling.

### Palette Definitions (`components/Theme.js`)

- **Background:** `#000000` with configurable translucency (`0.65` - `1.0`).
- **Surface Fill:** `rgba(255, 255, 255, 0.03)` with soft blurred backdrop.
- **Borders:** Ultra-subtle `rgba(255, 255, 255, 0.08)`.
- **Text Primary:** `#FFFFFF` (high contrast tabular numerals).
- **Text Secondary:** `#71717A` (zinc muted metadata).
- **Accents:**
  - Emerald Cyan: `#00E599`
  - Vercel Blue: `#0070F3`
  - Plasma System Accent: `Kirigami.Theme.highlightColor`

### High-DPI & Grid Units

Never hardcode raw pixel sizes in QML. Always scale metrics using `Kirigami.Units`:
- `Kirigami.Units.gridUnit`: Base layout metric (typically 18px).
- `Kirigami.Units.smallSpacing`: 4px proportional.
- `Kirigami.Units.largeSpacing`: 8px proportional.
- `Kirigami.Units.shortDuration` / `longDuration`: Animations.

---

## 8. Automated Testing & CI Safeguards

The project enforces automated verification via GitHub Actions (`.github/workflows/ci.yml`). All checks can be executed locally:

### 1. Static Safeguards (`ci-check.py`)
Validates QML syntax constraints, schema integrity, and prevents known KDE QML bugs:
```bash
python3 scripts/ci-check.py
```
Checks include:
- `font:` whole-object assignment followed by `font.*` property assignment (illegal in Qt 6).
- `PlasmaCore.Action` priority enum compliance (`LowPriority`, `NormalPriority`, `HighPriority`).
- Illegal `readonly property var foo: ({` blocks embedding statements.
- Synchronization between `main.xml` entries and expected types.
- Semver validation in `metadata.json`.

### 2. Quote Engine Suite (`test-quotes.js`)
Validates string sanitization, author filtering, and model fallback:
```bash
node scripts/test-quotes.js
```

### 3. Packaging Integrity
Ensures `.plasmoid` zip builds cleanly and stays lightweight (< 2 MB):
```bash
./scripts/package.sh
```

---

## 9. Packaging & Publishing Pipeline

### Building Release Artifacts

To create a production `.plasmoid` archive:
```bash
./scripts/package.sh
```
This generates `org.adi_il.ticking-<version>.plasmoid` in the repository root. The package script automatically excludes development files (`scripts/`, `assets/`, `docs/`, `.git/`) to minimize package size.

### Releasing on GitHub

1. Update version in `metadata.json`:
   ```json
   "Version": "2.1.0"
   ```
2. Commit and push:
   ```bash
   git commit -am "chore: bump version to 2.1.0"
   git tag v2.1.0
   git push origin main --tags
   ```
3. GitHub Actions automatically executes the release workflow (`.github/workflows/release.yml`), compiling release notes and attaching the `.plasmoid` asset.

### Publishing to the KDE Store

Upload the generated `org.adi_il.ticking-<version>.plasmoid` archive to:
**[KDE Store — Ticking Plasmoid](https://store.kde.org/p/2370240/)**

---

## 10. Troubleshooting & Common Pitfalls

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| **Changes not visible on desktop after editing QML** | Plasma caches compiled QML bytecode in `~/.cache/plasmashell/qmlcache`. | Run `./scripts/install.sh --restart` to wipe the cache and restart `plasmashell`. |
| **`plasmoidviewer` fails with Wayland protocol error** | Wayland compositor / GPU driver interaction with Qt Quick. | Run with `QT_QPA_PLATFORM=xcb plasmoidviewer -a .`. |
| **Remote quotes fail with HTTP 400 MissingSessionID** | OpenCode Zen free tier requires session header. | Ensure `xhr.setRequestHeader("x-session-id", "ticking-" + Date.now())` is present in `QuoteClient.js`. |
| **Remote quotes fail with HTTP 401 CreditsError** | Non-free model requested on free API key. | Use `REMOTE_MODELS = ["nemotron-3-ultra-free", "nemotron-3.5-lightning-free"]`. |
| **QML error: "Cannot assign to read-only property font"** | Attempted to assign whole font object and then modify subproperty. | Avoid `font: ...` paired with `font.pixelSize: ...`. Assign subproperties directly. |
| **Settings not saving or reverting on reload** | Key missing from `contents/config/main.xml`. | Add entry definition to `contents/config/main.xml` and run `python3 scripts/ci-check.py`. |
| **Stopwatch resets when logging out or rebooting** | State not serialized to KConfigXT. | Verify `stopwatchRunning`, `stopwatchElapsedMs`, and `stopwatchLapsJson` properties are saved in `main.xml`. |
