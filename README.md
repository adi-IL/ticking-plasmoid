# Ticking — Horizon & Time HUD (KDE Plasma 6)

A high-aesthetic, Vercel-inspired desktop and panel widget for KDE Plasma 6. Designed for precision tracking toward the **October 25, 2026** horizon, live digital world time, and high-precision stopwatch metrics.

Developed by **Aditya Gaurav** ([`adi-IL`](https://github.com/adi-IL)).

---

## Features

- **Vercel Obsidian Glass Aesthetic:** Ultra-dark translucent surfaces, sub-pixel specular borders, and glowing accents.
- **Horizon Countdown (Target: October 25, 2026):**
  - Modular tabular cards: Days, Hours, Minutes, Seconds, and live Sub-second Milliseconds.
  - Live journey progress track with 3-decimal percentage completion resolution.
- **Precision Live Clock:**
  - Full date string, 12h/24h time, UTC offset timezone indicator, and day-of-year counter.
- **Digital Stopwatch:**
  - Millisecond-accurate stopwatch with Start / Pause / Lap / Reset controls.
  - Lap history table with split time calculations.
- **Desktop & Panel Versatility:**
  - Desktop Mode: Full floating HUD card.
  - Panel Mode: Sleek minimal icon with remaining time badge that expands into the full HUD on click.
- **KConfigXT Settings:**
  - Customizable target date, custom milestone title, accent color, and glass opacity slider.

---

## Requirements

- **KDE Plasma:** 6.0+ (Tested on Plasma 6.7+)
- **KDE Frameworks:** 6.0+ (Kirigami, KCMUtils, KPackage)
- **Qt:** 6.6+ (Qt Quick, Qt Quick Layouts, Qt Quick Controls)
- **Operating System:** Linux (Fedora KDE 40+ recommended)

---

## Installation

### User Space Installation (Rootless)

```bash
# Clone repository
git clone https://github.com/adi-IL/ticking-plasmoid.git
cd ticking-plasmoid

# Package and install via kpackagetool6
kpackagetool6 -t Plasma/Applet --install .

# Or manual copy
mkdir -p ~/.local/share/plasma/plasmoids/org.adi_il.ticking
cp -r metadata.json contents ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
```

### Upgrading Existing Installation

```bash
kpackagetool6 -t Plasma/Applet --upgrade .
```

---

## Development & Testing

### Run in Standalone Window

```bash
plasmawindowed org.adi_il.ticking
```

### Simulate Desktop & Panel Modes

```bash
# Test as a floating desktop widget
plasmoidviewer -a org.adi_il.ticking -l floating -f planar

# Test as a horizontal panel widget
plasmoidviewer -a org.adi_il.ticking -l bottomedge -f horizontal
```

### Reload Plasma Shell

```bash
systemctl --user restart plasma-plasmashell.service
```

---

## License

GNU General Public License v3.0 or later ([GPL-3.0-or-later](LICENSES/GPL-3.0-or-later.txt)).
