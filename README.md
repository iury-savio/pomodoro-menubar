# Pomodoro Menu Bar

A lightweight native macOS Pomodoro timer. Keep the countdown in the menu bar, open a quick-controls popover, or show a floating timer that stays above other windows and across Spaces.

## Features

- Menu bar countdown with a mode icon.
- Focus, short-break, and long-break phases; long break follows every fourth focus session.
- Customizable durations from 1–90 minutes, saved between launches (defaults: 25/5/15).
- Start, pause, reset, and skip controls.
- Optional floating timer window that stays on top and can join all Spaces.
- macOS notification when a phase ends.
- Audible completion chime with an on/off switch and test button in settings.
- Remembers the active timer across app launches.
- No third-party dependencies.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools (Swift 6+)

## Run

### Download the macOS app

Download `Pomodoro-macOS-arm64.zip` from the [latest GitHub Release](https://github.com/iurysavio/pomodoro-menubar/releases/latest), unzip it, then open `Pomodoro.app`. The release build targets Apple silicon Macs and requires macOS 14 or later.

### Build from source

```sh
git clone https://github.com/iurysavio/pomodoro-menubar.git
cd pomodoro-menubar
./scripts/build-app.sh
open build/Pomodoro.app
```

The app appears in the menu bar. Use **Show floating timer** in the menu-bar panel to open the always-on-top timer. Click the sliders icon in the panel to open timer settings. Building from source creates `build/Pomodoro.app`; it is not checked into the repository.

For local use, the unsigned app may require approval in **System Settings → Privacy & Security**. Signing and notarization are not included in this source build.

## License

MIT. See [LICENSE](LICENSE).
