# Ticking - Horizon & Time HUD (KDE Plasma 6)

[![KDE Store](https://img.shields.io/badge/KDE%20Store-Download-0070F3?style=flat-square&logo=kde&logoColor=white)](https://store.kde.org/p/2370240/)
[![GitHub Release](https://img.shields.io/github/v/release/adi-IL/ticking-plasmoid?style=flat-square&color=00E599)](https://github.com/adi-IL/ticking-plasmoid/releases/latest)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue?style=flat-square)](LICENSE)
[![Plasma: 6.0+](https://img.shields.io/badge/KDE%20Plasma-6.0+-blueviolet?style=flat-square)](https://kde.org/plasma-desktop/)

Desktop and panel widget for KDE Plasma 6. Countdown to a horizon date, live clock, and a millisecond stopwatch, with an Obsidian glass look or Plasma system colors.

![Ticking Desktop HUD](assets/desktop-hero.png)

---

## Visual gallery

| Horizon countdown | Live clock | Stopwatch |
| :---: | :---: | :---: |
| ![Countdown View](assets/countdown-view.png) | ![Clock View](assets/clock-view.png) | ![Stopwatch View](assets/stopwatch-view.png) |
| Tabular cards, sub-second ticker, journey progress | 12h/24h, UTC offset, day of year, ISO week | Hours support, lap splits |

### Panel mode

![Panel Mode](assets/panel-mode.png)

Compact icon with an optional remaining-time badge. Expands to the full HUD. Works on horizontal and vertical panels.

---

## Features

- **Themes:** Vercel-style Obsidian glass, or Plasma system adaptive (Breeze, Catppuccin, Nord, and friends).
- **Horizon dates:** Month/day/year pickers for start and end. Both are **local calendar days at 00:00** in your timezone. Legacy `…T00:00:00Z` values still load as the civil date they encoded.
- **Presets:** New Year 2027, End of 2026, 100-day goal, Oct 25 2026.
- **Countdown:** Days/hours/mins/secs/ms cards, milestone banner, journey progress bar.
- **Clock:** Locale long date, 12h/24h, UTC offset, day-of-year, ISO week number.
- **Stopwatch:** Start/pause/lap/reset with split history. Timer steps up to ~25 FPS only while you need it.
- **Config:** Default view tab, panel badge toggle, glass opacity, accent swatches, ms ticker, progress bar.
- **i18n:** gettext template in `po/`.

---

## Requirements

- KDE Plasma 6.0+ (tested on 6.2+)
- KF6: Kirigami, KCMUtils, KPackage
- Qt 6.6+ (Quick, Layouts, Controls)
- Linux (Fedora KDE, Arch, openSUSE, Debian, …)

---

## Install

### User install (no root)

```bash
git clone https://github.com/adi-IL/ticking-plasmoid.git
cd ticking-plasmoid

kpackagetool6 -t Plasma/Applet --install .
# later:
kpackagetool6 -t Plasma/Applet --upgrade .
```

Manual copy:

```bash
mkdir -p ~/.local/share/plasma/plasmoids/org.adi_il.ticking
cp -r metadata.json contents ~/.local/share/plasma/plasmoids/org.adi_il.ticking/
```

### Build a release zip

```bash
chmod +x scripts/package.sh
./scripts/package.sh
# → org.adi_il.ticking-1.3.0.plasmoid
```

---

## Development

```bash
plasmawindowed org.adi_il.ticking
systemctl --user restart plasma-plasmashell.service
python3 scripts/extract-messages.py
```

---

## License

GNU General Public License v3.0 or later ([GPL-3.0-or-later](LICENSE)).

---

Developed with ❤️ by **Aditya Gaurav** ([`adi-IL`](https://github.com/adi-IL))
