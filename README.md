# Ticking: horizon and time HUD for KDE Plasma 6

[![KDE Store](https://img.shields.io/badge/KDE%20Store-Download-0070F3?style=flat-square&logo=kde&logoColor=white)](https://store.kde.org/p/2370240/)
[![GitHub Release](https://img.shields.io/github/v/release/adi-IL/ticking-plasmoid?style=flat-square&color=00E599)](https://github.com/adi-IL/ticking-plasmoid/releases/latest)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue?style=flat-square)](LICENSE)
[![Plasma: 6.0+](https://img.shields.io/badge/KDE%20Plasma-6.0+-blueviolet?style=flat-square)](https://kde.org/plasma-desktop/)

A desktop and panel HUD for KDE Plasma 6. Track a milestone countdown, read a world clock, run a split-lap stopwatch, and keep a quiet philosophy quote on the desktop.

![Ticking Desktop HUD](assets/desktop-hero.png)

---

## Visual gallery

| Horizon Countdown | Live Clock | Precision Stopwatch |
| :---: | :---: | :---: |
| ![Countdown View](assets/countdown-view.png) | ![Clock View](assets/clock-view.png) | ![Stopwatch View](assets/stopwatch-view.png) |
| Tabular cards, 10 FPS centisecond ticker, journey progress bar | 12h and 24h formats, UTC offset, day of year, ISO week number | Split lap recording, hours support, 25 FPS while running |

### Intellect quote companion

![Intellect Quote Companion](assets/intellect-quotes.png)

A rounded glass capsule at the bottom of the HUD. Rotates short quotes on time, craft, and discipline. Includes an offline library of 40 lines with Seneca, Marcus Aurelius, Feynman, Da Vinci, and Sagan. An optional OpenCode Zen key uses Nemotron with local fallback. Copy takes one click.

The Zen key is stored unencrypted in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Leave it empty to stay offline.

### Panel mode

![Panel Mode](assets/panel-mode.png)

Compact panel icon with an optional remaining-time badge. Expands to the full HUD on click. Supports horizontal and vertical panels.

---

## Core features

- Themes: Obsidian dark glass, or Plasma system colors.
- Horizon dates: Calendar pickers for start and end, anchored to local midnight. Legacy ISO dates load as the civil date they encoded.
- Presets: New Year 2027, End of 2026, 100-day goal, October 25 2026.
- Countdown: Days, hours, minutes, seconds, centiseconds, and progress track.
- Clock: Locale date, 12h or 24h format, UTC offset, day of year, and ISO week.
- Stopwatch: Start, pause, lap, reset, and split history. State and laps persist across Plasma restarts.
- Idle timers: Collapsed panels tick every 30s with the badge enabled, or 60s with the badge disabled. A visible countdown with milliseconds ticks at 10 FPS. A running stopwatch ticks at 25 FPS. Quote fetches run only while the HUD is visible.
- Customization: Default tab, glass opacity, accent color, panel badge, sub-second ticker, and quote rhythm.
- Localization: Gettext template at `po/plasma_applet_org.adi_il.ticking.pot`.

---

## Requirements

- KDE Plasma 6.0+ (tested on 6.7)
- KF6: Kirigami, KCMUtils, KPackage
- Qt 6.6+ (Quick, Layouts, Controls)
- Linux: Fedora KDE, Arch, openSUSE, Debian, and Ubuntu

---

## Installation

Install the `.plasmoid` zip, not the git working tree. `kpackagetool6 --install .` from a git clone copies scripts, assets, and build artifacts into the applet directory.

### From a release

Download `org.adi_il.ticking-1.5.1.plasmoid` from [GitHub Releases](https://github.com/adi-IL/ticking-plasmoid/releases/latest) or the [KDE Store](https://store.kde.org/p/2370240/).

```bash
kpackagetool6 -t Plasma/Applet --install org.adi_il.ticking-1.5.1.plasmoid
# or if upgrading an earlier build:
kpackagetool6 -t Plasma/Applet --upgrade org.adi_il.ticking-1.5.1.plasmoid
```

### Build from source

```bash
git clone https://github.com/adi-IL/ticking-plasmoid.git
cd ticking-plasmoid
./scripts/package.sh
kpackagetool6 -t Plasma/Applet --install org.adi_il.ticking-1.5.1.plasmoid
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

## Development and contributing

Read [DEV_NOTES.md](DEV_NOTES.md) for architecture details, state persistence rules, QML notes, and debugging steps.

### Quick inner loop

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

Developed by Aditya Gaurav, [`adi-IL`](https://github.com/adi-IL).
