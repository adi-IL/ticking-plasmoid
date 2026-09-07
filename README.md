# Ticking - Horizon & Time HUD (KDE Plasma 6)

[![KDE Store](https://img.shields.io/badge/KDE%20Store-Download-0070F3?style=flat-square&logo=kde&logoColor=white)](https://store.kde.org/p/2370240/)
[![GitHub Release](https://img.shields.io/github/v/release/adi-IL/ticking-plasmoid?style=flat-square&color=00E599)](https://github.com/adi-IL/ticking-plasmoid/releases/latest)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue?style=flat-square)](LICENSE)
[![Plasma: 6.0+](https://img.shields.io/badge/KDE%20Plasma-6.0+-blueviolet?style=flat-square)](https://kde.org/plasma-desktop/)

A desktop and panel HUD for KDE Plasma 6. Track a milestone countdown, read a world clock, run a split-lap stopwatch, and keep a quiet philosophy quote on the desktop.

![Ticking Desktop HUD](assets/desktop-hero.png)

---

## Visual Gallery

| Horizon Countdown | Live Clock | Precision Stopwatch |
| :---: | :---: | :---: |
| ![Countdown View](assets/countdown-view.png) | ![Clock View](assets/clock-view.png) | ![Stopwatch View](assets/stopwatch-view.png) |
| Tabular cards, 10 FPS centisecond ticker, journey progress bar | 12h/24h formats, UTC offset, day of year, ISO week number | Split lap recording, hours support, 25 FPS while running |

### Intellect Quote Companion

![Intellect Quote Companion](assets/intellect-quotes.png)

A rounded glass capsule at the bottom of the HUD. Rotates short quotes on time, craft, and discipline. Offline library of 40+ lines (Seneca, Marcus Aurelius, Feynman, Da Vinci, Sagan). Optional OpenCode Zen key uses Nemotron with local fallback. Copy is one click.

The Zen key is stored unencrypted in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Leave it empty to stay offline.

### Panel Mode

![Panel Mode](assets/panel-mode.png)

Compact panel icon with an optional remaining-time badge. Expands to the full HUD on click. Horizontal and vertical panels.

---

## Core Features

- **Themes:** Obsidian dark glass, or Plasma system colors.
- **Horizon dates:** Calendar pickers for start and end, local midnight. Legacy ISO dates still load as the civil date they encoded.
- **Quick presets:** New Year 2027, End of 2026, 100-day goal, October 25 2026.
- **Countdown:** Days, hours, minutes, seconds, centiseconds, progress track.
- **Clock:** Locale date, 12h/24h, UTC offset, day-of-year, ISO week.
- **Stopwatch:** Start, pause, lap, reset, split history, with state and split history persisted across Plasma restarts.
- **Idle timers:** Collapsed panel ticks at 30s (badge on) or 60s (badge off). Visible countdown with milliseconds uses 10 FPS. Running stopwatch uses 25 FPS. Quote fetches run only while the HUD is visible.
- **Customization:** Default tab, glass opacity, accent, panel badge, sub-second ticker, quote rhythm.
- **Localization:** Gettext template at `po/plasma_applet_org.adi_il.ticking.pot`. No compiled `.mo` catalogs yet.

---

## Requirements

- KDE Plasma 6.0+ (tested on 6.7)
- KF6: Kirigami, KCMUtils, KPackage
- Qt 6.6+ (Quick, Layouts, Controls)
- Linux (Fedora KDE, Arch, openSUSE, Debian, and friends)

---

## Installation

Install the `.plasmoid` zip, not the git working tree. `kpackagetool6 --install .` from a clone copies scripts, assets, and leftover zips into the applet dir.

### From a release (preferred)

Download `org.adi_il.ticking-1.5.0.plasmoid` from [GitHub Releases](https://github.com/adi-IL/ticking-plasmoid/releases/latest) or the [KDE Store](https://store.kde.org/p/2370240/).

```bash
kpackagetool6 -t Plasma/Applet --install org.adi_il.ticking-1.5.0.plasmoid
# later:
kpackagetool6 -t Plasma/Applet --upgrade org.adi_il.ticking-1.5.0.plasmoid
```

`--upgrade` replaces package files and keeps your applet settings (dates, 12h/24h, quote key).

### From git

```bash
git clone https://github.com/adi-IL/ticking-plasmoid.git
cd ticking-plasmoid
./scripts/package.sh
kpackagetool6 -t Plasma/Applet --install org.adi_il.ticking-1.5.0.plasmoid
```

### Manual copy

```bash
mkdir -p ~/.local/share/plasma/plasmoids/org.adi_il.ticking
cp metadata.json ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
cp -r contents ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
systemctl --user restart plasma-plasmashell.service
```

Copy only `metadata.json` and `contents/`. Do not copy `assets/`, `scripts/`, or `*.plasmoid` into that folder.

---

## Development & Contributing

Comprehensive architectural documentation, state persistence details, QML guidelines, and troubleshooting notes are available in **[DEV_NOTES.md](DEV_NOTES.md)**.

### Quick Inner Loop

```bash
# Sync local changes and clear QML cache:
./scripts/install.sh

# Sync local changes and restart plasmashell:
./scripts/install.sh --restart

# Run isolated in plasmoidviewer without touching your desktop:
./scripts/install.sh --viewer

# Run automated tests and static CI guards:
node scripts/test-quotes.js
python3 scripts/ci-check.py

# Package production .plasmoid bundle:
./scripts/package.sh
```

---

## License

GNU General Public License v3.0 or later ([GPL-3.0-or-later](LICENSE)).

Developed by **Aditya Gaurav** ([`adi-IL`](https://github.com/adi-IL))
