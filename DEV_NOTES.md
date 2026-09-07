# Ticking Plasmoid — Developer Field Manual & Technical Case Studies

> **Battle-Tested Engineering Notes from the Development & Debugging Sessions**  
> This document captures the real-world discoveries, edge cases, protocol quirks, and architectural solutions encountered while developing, debugging, and polishing the **Ticking** Plasmoid for KDE Plasma 6.

---

## Table of Contents

1. [Executive Summary & Core Lessons](#1-executive-summary--core-lessons)
2. [Case Study 1: The Local Desync & Ghost Cache Trap](#2-case-study-1-the-local-desync--ghost-cache-trap)
3. [Case Study 2: The Mystery of the Persistent Quote & `appletsrc`](#3-case-study-2-the-mystery-of-the-persistent-quote--appletsrc)
4. [Case Study 3: OpenCode Zen Free-Tier Protocol & Cascade Architecture](#4-case-study-3-opencode-zen-free-tier-protocol--cascade-architecture)
5. [Case Study 4: LLM Author Pollution & Commentary Sanitization](#5-case-study-4-llm-author-pollution--commentary-sanitization)
6. [Case Study 5: The "Repeating Bruce Lee" Bug & The Broken Manual Refresh](#6-case-study-5-the-repeating-bruce-lee-bug--the-broken-manual-refresh)
7. [Case Study 6: Pixel-Perfect Adaptive Sizing & Live Badge Decency](#7-case-study-6-pixel-perfect-adaptive-sizing--live-badge-decency)
8. [The Fast Inner Dev Loop (`install.sh` & Tooling)](#8-the-fast-inner-dev-loop-installsh--tooling)
9. [Automated Verification & The Quote Test Suite](#9-automated-verification--the-quote-test-suite)
10. [Reference: Codebase Anatomy & File Map](#10-reference-codebase-anatomy--file-map)

---

## 1. Executive Summary & Core Lessons

Developing desktop widgets for KDE Plasma 6 in pure QML/JS combined with live AI APIs presents several subtle pitfalls:

1. **Plasma Does Not Run From Your Git Repo:** Plasma executes code from `~/.local/share/plasma/plasmoids/<id>` and heavily caches compiled bytecode in `~/.cache/plasmashell/qmlcache`. Editing files in your git workspace will **never** reflect on your desktop until you sync files, wipe the bytecode cache, and restart `plasma-plasmashell.service`.
2. **KConfigXT Persists State Across Desktop Restarts:** Values written to `Plasmoid.configuration` are written to `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. If an unexpected quote or setting appears on startup, it came from this configuration file.
3. **OpenCode Zen Free Tier Has Undocumented Headers:** Free models (`nemotron-3-ultra-free`, `nemotron-3.5-lightning-free`) **strictly require** the `x-session-id` HTTP header. Without it, the server rejects requests with `HTTP 400 MissingSessionID`.
4. **Reasoning Models Emit Rambling Attribution Noise:** Models like Nemotron append conversational thoughts directly into the author field (`- Bruce Lee. That's a quote about focus, but` or `- Attributed to high-performance coaching circles, but I'll be careful. Maybe`). Your sanitizer must actively slice off trailing commentary sentences and reject noise.
5. **Static Prompts Cause Deterministic LLM Prior Loops:** Without topic diversification and negative prompt exclusion, models will deterministically return the exact same famous quote (e.g. Bruce Lee) on every single refresh, making manual refresh look completely broken.

---

## 2. Case Study 1: The Local Desync & Ghost Cache Trap

### The Problem
During development, we updated QML files in the repository, but the widget on the user's desktop continued running an older version with outdated behavior.

### The Root Cause
KDE Plasma architecture separates the development workspace from the desktop runtime in two ways:
1. **Directory Isolation:** Plasma only loads installed applets from:
   ```
   ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
   ```
   Changes made in `~/ILdev/own/ticking-plasmoid/` are invisible to Plasma until copied over.
2. **QML Bytecode Caching (`qmlcache`):** When `plasmashell` loads QML files, it compiles them into optimized bytecode stored in `~/.cache/plasmashell/qmlcache/`. Even if you overwrite the source QML files in `~/.local/share/plasma/`, `plasmashell` will often reuse the stale cached bytecode from memory or disk.

### The Solution: `scripts/install.sh`
We created a dedicated synchronization script that handles the entire pipeline in one shot:

```bash
# 1. Sync files to Plasma applet directory
# 2. Clear QML bytecode cache
# 3. Update sycoca database
# 4. Restart plasma-plasmashell systemd service
./scripts/install.sh --restart
```

#### Manual Commands Reference
```bash
cp -rf contents metadata.json ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
rm -rf ~/.cache/plasmashell/qmlcache
kbuildsycoca6 --noincremental
systemctl --user restart plasma-plasmashell.service
```

---

## 3. Case Study 2: The Mystery of the Persistent Quote & `appletsrc`

### The Problem
The user noticed the quote:
> *"Discipline is the bridge between goals and accomplishment. - Jim Rohn"*

appearing consistently on their desktop, and asked: *"Is this hardcoded anywhere in the codebase?"*

### The Investigation
We searched the entire repository for `"Discipline is the bridge"` or `"Jim Rohn"`. Zero matches were found in `QuoteLibrary.js` or `main.qml`.

So where did it come from?

### The Root Cause: KDE KConfigXT Persistence
In `main.qml`, whenever a quote is fetched (either from remote AI or offline curated pool), it is saved into `Plasmoid.configuration`:
```javascript
Plasmoid.configuration.cachedQuoteText = cleanedText;
Plasmoid.configuration.cachedQuoteAuthor = cleanedAuthor;
```
KDE Plasma serializes this configuration to disk in:
```
~/.config/plasma-org.kde.plasma.desktop-appletsrc
```
Inside the file:
```ini
[Containments][111][Applets][237][Configuration][General]
cachedQuoteAuthor=Bruce Lee. This is perfectly 1 line, famous, about focus.
cachedQuoteText=The successful warrior is the average man, with laser-like focus.
quoteApiKey=sk-s4kew1...
quoteArchetype=intensity
```
When the plasmoid initializes on desktop load, it immediately reads `cachedQuoteText` and `cachedQuoteAuthor` to display an instant quote without waiting for network I/O. The quote was fetched once dynamically, saved to `appletsrc`, and persisted across reboots!

---

## 4. Case Study 3: OpenCode Zen Free-Tier Protocol & Cascade Architecture

### The Problem
The user added their OpenCode Zen API key (`sk-s4kew...`) to `~/.bashrc`, yet the widget either kept showing curated quotes or failed to load new quotes.

### Diagnostic Breakdown

#### Discovery 1: `HTTP 400 MissingSessionID`
Running a manual HTTP POST request against `https://opencode.ai/zen/v1/chat/completions` using the free models revealed:
```json
{
  "error": {
    "message": "x-session-id header is required for free models",
    "type": "invalid_request_error"
  }
}
```
**Resolution:** In `QuoteClient.js`, inject a unique session identifier with every request:
```javascript
xhr.setRequestHeader("x-session-id", "ticking-" + Date.now());
```

#### Discovery 2: `HTTP 401 CreditsError` on Paid Models
When attempting to call `gemini-3.5-flash-lite` or standard endpoints using free keys, OpenCode Zen returned:
```json
{
  "error": {
    "message": "You do not have enough credits to use this model. Please add a payment method.",
    "type": "insufficient_quota"
  }
}
```
**Resolution:** Restricted `REMOTE_MODELS` strictly to the free tier models:
```javascript
var REMOTE_MODELS = [
    "nemotron-3-ultra-free",
    "nemotron-3.5-lightning-free"
];
```

#### Discovery 3: Upstream Errors Wrapped in HTTP 200
Certain upstream proxy failures returned HTTP status 200 but contained an error object in the body:
```javascript
var res = JSON.parse(xhr.responseText);
if (res.error) {
    console.warn("Ticking QuoteClient: upstream error on", modelName, res.error.message);
    tryNextModel(); // Cascade to next candidate!
    return;
}
```

### The Full Resilient Cascade
```
Request 1: nemotron-3-ultra-free (25s timeout)
   │
   ├── Success (clean text & author) ──> Display Quote
   │
   └── Failure / Timeout / Error
         │
         ▼
Request 2: nemotron-3.5-lightning-free (25s timeout)
   │
   ├── Success (clean text & author) ──> Display Quote
   │
   └── Failure / Timeout / Error
         │
         ▼
Fallback: Curated Offline Library (QuoteLibrary.js) ──> Instant Display
```

---

## 5. Case Study 4: LLM Author Pollution & Commentary Sanitization

### The Problem
The user uploaded two screenshots demonstrating severe author field pollution:
1. **Screenshot 1:**
   - Quote: `"Relentless focus turns goals into achievements."`
   - Author: `- Attributed to high-performance coaching circles, but I'll be careful. Maybe`
2. **Screenshot 2:**
   - Quote: `"The successful warrior is the average man, with laser-like focus."`
   - Author: `- Bruce Lee. That's a quote about focus, but`
3. **From `appletsrc` configuration:**
   - Author: `Bruce Lee. This is perfectly 1 line, famous, about focus.`

### The Root Cause
Reasoning LLMs (like Nemotron) generate internal thinking tokens and frequently emit conversational chatter or attribution caveats right after the author's name.

Our original parser split lines on `" - "` and assumed everything after the dash was the author's name:
```javascript
// NAIVE APPROACH (VULNERABLE):
var parts = line.split(" - ");
var author = parts[1].trim(); // Captured: "Bruce Lee. That's a quote about focus, but"
```

### The Solution: Multi-Layer Sanitization Pipeline
In [`QuoteClient.js`](file:///home/adi-IL/ILdev/own/ticking-plasmoid/contents/ui/components/QuoteClient.js):

```javascript
function cleanQuoteAuthor(author) {
    if (!author || typeof author !== "string") return "";
    var cleaned = author.trim();

    // 1. Strip surrounding quotes
    cleaned = cleaned.replace(/^["'\u201c\u201d\u00ab\u00bb]+|["'\u201c\u201d\u00ab\u00bb]+$/g, "").trim();

    // 2. Reject commentary lines masquerading as authors
    if (/^(attributed to|possibly|maybe|this is|that's|probably|unknown|an? \w+ quote)/i.test(cleaned)) {
        return ""; // Triggers candidate rejection and model cascade!
    }

    // 3. Cut off full sentences continuing after the author name
    // e.g. "Bruce Lee. That's a quote about focus, but..." -> "Bruce Lee"
    var periodIdx = cleaned.indexOf(". ");
    if (periodIdx !== -1) {
        var beforePeriod = cleaned.substring(0, periodIdx).trim();
        // Allow initials like "C.S." or "A." but truncate if it's already a full name
        if (!/^[A-Z]\.?\s*[A-Z]?\.?$/.test(beforePeriod)) {
            cleaned = beforePeriod;
        }
    }

    // 4. Cut off trailing explanatory clauses after comma or dash
    cleaned = cleaned.replace(/,\s*(?:which|who|that|a|an|the|as|noting|explaining|saying)[\s\S]*$/i, "");
    cleaned = cleaned.replace(/\s+-\s+.*$/, "");
    cleaned = cleaned.replace(/[.\-,;:\s]+$/, "").trim();

    // 5. Length gate: real author names rarely exceed 45 characters
    if (cleaned.length > 45 || cleaned.length === 0) {
        return "";
    }
    return cleaned;
}
```

If `cleanQuoteAuthor` returns an empty string, the quote is rejected as invalid, and `QuoteClient` immediately falls back to the next model candidate or offline library.

---

## 6. Case Study 5: The "Repeating Bruce Lee" Bug & The Broken Manual Refresh

### The Problem
The user reported:
> *"and one more thing manual refresh is not working even after 2 or 3 refrsh manaullly this same thing is visible The successful warrior is the average man, with laser-like focus. - Bruce Lee..."*

### The Root Cause
1. **Static Prompting:** For archetype `intensity`, `resolveTopic` always returned the exact same static string: `"relentless focus"`.
2. **Greedy LLM Prior Bias:** Given `"relentless focus"`, Nemotron has a massive statistical prior favoring Bruce Lee's quote. With a low temperature (`0.7`) and zero negative constraints, it generated Bruce Lee on request 1, request 2, and request 3.
3. **Perceived UI Failure:** Because the newly generated quote was identical to the quote already on screen, the UI didn't visually change. The user naturally assumed manual refresh was broken!

### The Three-Part Solution

#### 1. Dynamic Topic Rotation (`ARCHETYPE_TOPICS`)
Instead of a single static topic per archetype, we introduced a rich array of rotating sub-angles:
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
    ],
    // ...
};
```
Every refresh randomly picks a different thematic angle!

#### 2. Negative Exclusion Prompt Injection
`main.qml` now passes the active `currentQuoteText` and `currentQuoteAuthor` into the refresh request:
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

#### 3. Client-Side Duplicate Rejection
If the LLM still happens to return an identical quote:
```javascript
if (currentQuote.length > 0 && parsed.text.toLowerCase() === currentQuote.toLowerCase()) {
    console.warn("Ticking QuoteClient: duplicate quote received, cascading");
    tryNextModel();
    return;
}
```
And in `QuoteLibrary.js`, `getCuratedQuote(archetype, ratio, excludeText)` filters out the current quote, guaranteeing that offline fallback will also never serve the same quote twice in a row.

---

## 7. Case Study 6: Pixel-Perfect Adaptive Sizing & Live Badge Decency

### The Problem
User feedback requested:
> *"make this live badge bit more small and decent and this quote box make its size expand incare or decrase as per the count of the words character more pixel perfect and adaptive"*

### The Solution

#### A. Decent, Subtle Live Badge ([`FullRepresentation.qml`](file:///home/adi-IL/ILdev/own/ticking-plasmoid/contents/ui/FullRepresentation.qml))
- Decreased vertical and horizontal padding to fit cleanly beside the title.
- Reduced font size from raw point sizes to `Kirigami.Theme.smallFont.pointSize`.
- Applied a smooth pulsing opacity animation to the dot indicator rather than harsh blinking:
```qml
Rectangle {
    id: liveBadge
    implicitHeight: Kirigami.Units.gridUnit * 1.05
    radius: height / 2
    color: Qt.rgba(0, 0.89, 0.6, 0.12)
    border.color: Qt.rgba(0, 0.89, 0.6, 0.3)
    // ...
}
```

#### B. Content-Adaptive QuoteBar Capsule ([`QuoteBar.qml`](file:///home/adi-IL/ILdev/own/ticking-plasmoid/contents/ui/components/QuoteBar.qml))
- Replaced fixed container heights with dynamic intrinsic heights:
```qml
implicitHeight: Math.max(
    Kirigami.Units.gridUnit * 2.8,
    quoteContentLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
)
```
- Quote text wraps smoothly with `Text.Wrap` and dynamically scales its font point size when quotes exceed 120 characters:
```qml
font.pointSize: quoteText.length > 120 
    ? Kirigami.Theme.smallFont.pointSize 
    : Kirigami.Theme.defaultFont.pointSize
```
- Integrated one-click copy to clipboard with a visual checkmark feedback notification.

---

## 8. The Fast Inner Dev Loop (`install.sh` & Tooling)

### Using `scripts/install.sh`

| Command | Action |
| :--- | :--- |
| `./scripts/install.sh` | Syncs QML & metadata to `~/.local/share/plasma/plasmoids/` and flushes `qmlcache`. |
| `./scripts/install.sh --restart` | Syncs files, flushes cache, and restarts `plasma-plasmashell.service`. |
| `./scripts/install.sh --viewer` | Syncs files, flushes cache, and launches `plasmoidviewer` for isolated testing. |

### Inspecting Live Desktop Output
```bash
journalctl --user -u plasma-plasmashell.service -f | grep -i ticking
```

---

## 9. Automated Verification & The Quote Test Suite

To prevent regressions, we created [`scripts/test-quotes.js`](file:///home/adi-IL/ILdev/own/ticking-plasmoid/scripts/test-quotes.js), an end-to-end automated test runner.

### What It Tests (28 Automated Assertions)
1. **Text Sanitization:** Strips straight & curly quotes, preambles (`"Here is a quote:"`), and `<think>` blocks.
2. **Author Sanitization:** Tests exact edge cases reported by the user:
   - `"Bruce Lee. That's a quote about focus, but"` ➔ `"Bruce Lee"`
   - `"Attributed to high-performance coaching circles..."` ➔ Rejected (`""`)
   - `"Benjamin Franklin, who once noted that"` ➔ `"Benjamin Franklin"`
   - `"Jim Rohn - motivational speaker"` ➔ `"Jim Rohn"`
   - `"C.S. Lewis"` ➔ Preserves initials (`"C.S. Lewis"`)
3. **Offline Curated Library:** Tests 4 archetype pools and `excludeText` duplicate avoidance.
4. **Live Network Reproduction:**
   - Reproduces the `HTTP 400 MissingSessionID` bug when `x-session-id` is omitted.
   - Tests live generation with negative constraints to verify that models avoid duplicate quotes.

### Running the Suite Locally
```bash
# Run unit tests:
node scripts/test-quotes.js

# Run static CI linter:
python3 scripts/ci-check.py
```

---

## 10. Reference: Codebase Anatomy & File Map

```
ticking-plasmoid/
├── DEV_NOTES.md                     <-- You are here (field manual & case studies)
├── README.md                        <-- User-facing overview, screenshots, installation
├── metadata.json                    <-- KPlugin metadata (ID, version, API)
├── contents/
│   ├── config/
│   │   ├── config.qml               <-- Configuration dialog categories
│   │   └── main.xml                 <-- KConfigXT schema (persisted entries & defaults)
│   └── ui/
│       ├── main.qml                 <-- Root PlasmoidItem (state, dates, timers, quote dispatch)
│       ├── FullRepresentation.qml   <-- Desktop HUD / expanded popup layout
│       ├── CompactRepresentation.qml<-- Panel mode icon & badge
│       ├── configGeneral.qml        <-- Settings GUI (calendar pickers, presets, theme)
│       └── components/
│           ├── CountdownView.qml    <-- Tabular countdown cards (10 FPS ticker)
│           ├── ClockView.qml        <-- World clock (12h/24h, UTC offset, day/week)
│           ├── StopwatchView.qml    <-- Split-lap stopwatch (25 FPS ticker, persistent)
│           ├── QuoteBar.qml         <-- Adaptive glass capsule, rotating refresh button
│           ├── QuoteClient.js       <-- OpenCode Zen client, headers, sanitizer, cascade
│           ├── QuoteLibrary.js      <-- 40+ curated offline quotes, 4 archetypes
│           ├── SegmentedNav.qml     <-- Tab navigation selector
│           └── Theme.js             <-- Obsidian dark glass vs Plasma system palette
└── scripts/
    ├── install.sh                   <-- Local developer sync, cache flush, & restart
    ├── test-quotes.js               <-- Quote engine automated test suite
    ├── ci-check.py                  <-- Static safeguards & QML linters
    ├── package.sh                   <-- Production .plasmoid zip builder
    └── extract-messages.py          <-- Translation catalog generator (.pot)
```
