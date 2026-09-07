# Developer notes: Ticking plasmoid

Engineering notes from development and debugging sessions on KDE Plasma 6.

## Table of contents

1. [Core lessons](#1-core-lessons)
2. [Case study 1: local desync and the QML cache](#2-case-study-1-local-desync-and-the-qml-cache)
3. [Case study 2: quote persistence and appletsrc](#3-case-study-2-quote-persistence-and-appletsrc)
4. [Case study 3: OpenCode Zen free tier headers and fallbacks](#4-case-study-3-opencode-zen-free-tier-headers-and-fallbacks)
5. [Case study 4: LLM author pollution and cleaning](#5-case-study-4-llm-author-pollution-and-cleaning)
6. [Case study 5: repeating quotes and manual refresh](#6-case-study-5-repeating-quotes-and-manual-refresh)
7. [Case study 6: adaptive box sizing and badge styling](#7-case-study-6-adaptive-box-sizing-and-badge-styling)
8. [Inner development loop](#8-inner-development-loop)
9. [Automated tests and validation](#9-automated-tests-and-validation)
10. [File map and code layout](#10-file-map-and-code-layout)

---

## 1. Core lessons

Writing desktop widgets for KDE Plasma 6 in QML and JavaScript with remote AI services revealed five main traps.

1. Plasma runs installed code, not your git checkout. Plasma reads applets from `~/.local/share/plasma/plasmoids/<id>` and saves compiled bytecode in `~/.cache/plasmashell/qmlcache`. Changing files in your git directory changes nothing on screen until you copy them over, wipe the bytecode cache, and restart `plasma-plasmashell.service`.
2. KConfigXT writes state to disk. Any assignment to `Plasmoid.configuration` updates `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. If an unexpected quote or setting appears when Plasma loads, check that file.
3. OpenCode Zen free tier models require a session header. Requests to `nemotron-3-ultra-free` and `nemotron-3.5-lightning-free` must include `x-session-id`. Without it, the server responds with HTTP 400 and the message `MissingSessionID`.
4. Reasoning models dump thoughts into the author string. Nemotron often continues writing after the name, giving values like `Bruce Lee. That's a quote about focus, but` or `Attributed to high-performance coaching circles`. The parser must slice off trailing sentences and reject attribution text.
5. Static prompts make LLMs repeat themselves. Asking for quotes on a single fixed topic causes the model to return the same famous line on every refresh. Rotating subtopics and sending the current quote as a negative constraint fixes this.

---

## 2. Case study 1: local desync and the QML cache

### The problem
We modified QML files in the repository, but the widget running on the desktop showed older logic and old bugs.

### The cause
Two layers separate your repository from the running shell.
First, Plasma only loads user widgets from `~/.local/share/plasma/plasmoids/org.adi_il.ticking/`. Edits in `~/ILdev/own/ticking-plasmoid/` have no effect until copied.
Second, `plasmashell` compiles QML files into bytecode and stores them in `~/.cache/plasmashell/qmlcache/`. If you overwrite files in `~/.local/share/plasma/` without deleting this directory, the shell continues executing cached bytecode.

### The fix
We added `scripts/install.sh` to automate the steps needed for a clean reload:

```bash
./scripts/install.sh --restart
```

To run the steps manually:

```bash
cp -rf contents metadata.json ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
rm -rf ~/.cache/plasmashell/qmlcache
kbuildsycoca6 --noincremental
systemctl --user restart plasma-plasmashell.service
```

---

## 3. Case study 2: quote persistence and appletsrc

### The problem
The quote `Discipline is the bridge between goals and accomplishment. - Jim Rohn` kept appearing on startup. We needed to confirm whether this line was hardcoded.

### The investigation
Searching the codebase for `Discipline is the bridge` and `Jim Rohn` returned zero matches. The quote was not in `QuoteLibrary.js` or `main.qml`.

### The cause
In `main.qml`, successful quote fetches save the text and author to the widget configuration:

```javascript
Plasmoid.configuration.cachedQuoteText = cleanedText;
Plasmoid.configuration.cachedQuoteAuthor = cleanedAuthor;
```

Plasma syncs this configuration to disk at `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Inside the file:

```ini
[Containments][111][Applets][237][Configuration][General]
cachedQuoteAuthor=Bruce Lee. This is perfectly 1 line, famous, about focus.
cachedQuoteText=The successful warrior is the average man, with laser-like focus.
quoteApiKey=sk-s4kew1...
quoteArchetype=intensity
```

On startup, the applet loads these values so the interface displays a quote immediately without waiting on network I/O. The quote came from an earlier remote fetch, was written to disk, and remained across restarts.

---

## 4. Case study 3: OpenCode Zen free tier headers and fallbacks

### The problem
After configuring an API key, the widget still fell back to local quotes or failed to update.

### Discoveries and fixes

#### 1. HTTP 400 MissingSessionID
Posting to `https://opencode.ai/zen/v1/chat/completions` with free models produced an error:

```json
{
  "error": {
    "message": "x-session-id header is required for free models",
    "type": "invalid_request_error"
  }
}
```

We updated `QuoteClient.js` to send a generated session ID with every request:

```javascript
xhr.setRequestHeader("x-session-id", "ticking-" + Date.now());
```

#### 2. HTTP 401 CreditsError on paid models
Requesting models like `gemini-3.5-flash-lite` with a free key failed with an insufficient quota error.
We restricted the candidate list to models that are free on the platform:

```javascript
var REMOTE_MODELS = [
    "nemotron-3-ultra-free",
    "nemotron-3.5-lightning-free"
];
```

#### 3. Error payloads inside HTTP 200 responses
Certain proxy errors arrived with status 200 and a JSON payload containing an error field. We added an explicit check before reading choices:

```javascript
var res = JSON.parse(xhr.responseText);
if (res.error) {
    console.warn("Ticking QuoteClient: upstream error on", modelName, res.error.message);
    tryNextModel();
    return;
}
```

The cascade sequence runs `nemotron-3-ultra-free`, then `nemotron-3.5-lightning-free`, then the offline library in `QuoteLibrary.js`.

---

## 5. Case study 4: LLM author pollution and cleaning

### The problem
Models leaked thoughts into the author field. Real outputs showed:
- `Relentless focus turns goals into achievements.` with author `- Attributed to high-performance coaching circles, but I'll be careful. Maybe`
- `The successful warrior is the average man, with laser-like focus.` with author `- Bruce Lee. That's a quote about focus, but`
- In `appletsrc`, the author saved as `Bruce Lee. This is perfectly 1 line, famous, about focus.`

### The cause
The initial code split lines on ` - ` and treated everything to the right as the author. When the model added commentary after the name, that commentary was displayed in the UI.

### The fix
In `QuoteClient.js`, we rewrote `cleanQuoteAuthor`:

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

If `cleanQuoteAuthor` returns an empty string, the quote is treated as invalid and the client tries the next candidate.

---

## 6. Case study 5: repeating quotes and manual refresh

### The problem
Clicking the refresh button several times kept showing the same Bruce Lee quote.

### The cause
The topic was hardcoded to `relentless focus` for the intensity archetype. With a static prompt and zero negative constraints, Nemotron deterministically selected the same quote. Because the text did not change, the UI appeared broken.

### The fix
We addressed this at three levels.

First, we added `ARCHETYPE_TOPICS` in `QuoteClient.js` with rotating subtopics for each archetype.

```javascript
var ARCHETYPE_TOPICS = {
    intensity: [
        "unwavering self-discipline and daily mastery",
        "grit and relentless determination",
        "deep work and eliminating all distractions",
        "perseverance through pain and struggle",
        "laser focus and fierce urgency",
        "mental toughness and relentless drive",
        "obsession with excellence and execution"
    ],
    stoic: [
        "stoic discipline and inner fortress",
        "amor fati and enduring hardship",
        "focusing strictly on what is in your control",
        "memento mori and the brevity of time"
    ]
};
```

Second, we added negative constraints to the prompt using the active quote:

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

Third, `QuoteClient.js` rejects matching text, and `QuoteLibrary.js` filters out `excludeText` so offline fallback also avoids duplicates.

---

## 7. Case study 6: adaptive box sizing and badge styling

### The problem
The live badge was too prominent, and the quote container clipped longer lines.

### The fix

In `FullRepresentation.qml`, we reduced badge padding, switched to `Kirigami.Theme.smallFont.pointSize`, and replaced hard blinking with an opacity animation:

```qml
Rectangle {
    id: liveBadge
    implicitHeight: Kirigami.Units.gridUnit * 1.05
    radius: height / 2
    color: Qt.rgba(0, 0.89, 0.6, 0.12)
    border.color: Qt.rgba(0, 0.89, 0.6, 0.3)
}
```

In `QuoteBar.qml`, we set the height to follow content size:

```qml
implicitHeight: Math.max(
    Kirigami.Units.gridUnit * 2.8,
    quoteContentLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
)
```

Text wraps with `Text.Wrap`, and lines over 120 characters drop to small font size to stay legible.

---

## 8. Inner development loop

### Using scripts/install.sh

- `./scripts/install.sh`: Copies QML and metadata to `~/.local/share/plasma/plasmoids/org.adi_il.ticking` and clears `~/.cache/plasmashell/qmlcache`.
- `./scripts/install.sh --restart`: Copies files, clears cache, and restarts `plasma-plasmashell.service`.
- `./scripts/install.sh --viewer`: Copies files, clears cache, and opens the widget in `plasmoidviewer`.

### Checking logs

```bash
journalctl --user -u plasma-plasmashell.service -f | grep -i ticking
```

---

## 9. Automated tests and validation

We created `scripts/test-quotes.js` to test sanitization and API behavior outside Plasma.

### What it checks
1. Strips quotes, preambles, and `<think>` blocks from quote text.
2. Slices commentary sentences after names, so `Bruce Lee. That's a quote about focus, but` yields `Bruce Lee`.
3. Rejects attribution phrases like `Attributed to high-performance coaching circles`.
4. Leaves initials alone, so `C.S. Lewis` stays intact.
5. Verifies that `QuoteLibrary.js` pools contain at least 10 entries per archetype and honors duplicate exclusions.
6. Verifies that missing `x-session-id` reproduces HTTP 400, and verifies live generation with negative constraints.

### Running checks

```bash
node scripts/test-quotes.js
python3 scripts/ci-check.py
```

---

## 10. File map and code layout

- `metadata.json`: Applet identification, semver, and Plasma 6 API version.
- `contents/config/main.xml`: KConfigXT declarations and default values.
- `contents/config/config.qml`: Configuration category registration.
- `contents/ui/main.qml`: Root item, timer engine, date parsing, and quote controller.
- `contents/ui/FullRepresentation.qml`: Desktop HUD layout and popup view.
- `contents/ui/CompactRepresentation.qml`: Panel icon and dynamic badge.
- `contents/ui/configGeneral.qml`: Settings dialog.
- `contents/ui/components/CountdownView.qml`: Tabular cards and 10 FPS centisecond ticker.
- `contents/ui/components/ClockView.qml`: World clock, UTC offset, and week numbers.
- `contents/ui/components/StopwatchView.qml`: Split-lap recording and 25 FPS running timer.
- `contents/ui/components/QuoteBar.qml`: Glass container and refresh control.
- `contents/ui/components/QuoteClient.js`: API client, headers, cleaning, and model fallbacks.
- `contents/ui/components/QuoteLibrary.js`: Offline quote catalog with 4 archetypes.
- `contents/ui/components/Theme.js`: Color palettes and surface translucency.
- `scripts/install.sh`: Developer sync and shell reload tool.
- `scripts/test-quotes.js`: Standalone test suite for quotes.
- `scripts/ci-check.py`: Static validation gate.
- `scripts/package.sh`: Packaging script for `.plasmoid` zip files.
