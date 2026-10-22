# Chilly Eye

A macOS menu bar app for break reminders, built around the **20-20-20 rule**: every 20 minutes, look at something 20 feet (6 m) away for 20 seconds. You can add as many other timers as you like (posture, water, stretch, pomodoro, countdowns, breaks at fixed clock times).

Native Swift / SwiftUI, macOS 14+, with a WidgetKit widget.

## Features

- **Menu bar countdown** for the soonest timer you've pinned ("Show countdown in menu bar" on each timer). Click it to see every timer, sorted by which rings next, with pause / take break now on each.
- **Many timers, grouped by category.** New timer → pick a category (Eyes, Posture, Water, Stretch, Pomodoro, Countdown, Scheduled, Custom, or your own) → it pre-fills sensible defaults → tweak.
- **Timer types:** repeating, pomodoro (long break every N rounds), one-shot countdown, scheduled at clock times.
- **Break style per timer:** full-screen blurred overlay on every display, or a small popup. Skip, snooze, or the break ends by itself when its countdown finishes.
- **Active hours per timer**, for example Mon–Fri 9:00–18:00.
- **Smart pausing:**
  - when you're idle, the screen is locked or the Mac sleeps, timers are held, and repeating timers restart when you return (you already rested)
  - breaks are postponed during calls (camera or mic in use) and while a fullscreen app is in front
- **Pause all** for 30 min, 1 h, until tomorrow, or until resumed. Global shortcut **⌃⌥⌘P**.
- **Stats:** breaks taken / skipped / snoozed per day, and a day streak.
- **Widget** (medium): the next 3 timers with live countdowns.
- **Launch at login.**

## Build and run

Needs Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

1. In Xcode → Settings → Accounts, add your Apple ID. A free Personal Team is enough to run it locally.
2. Put your team ID in `Config/Local.xcconfig` (git-ignored):
   ```
   DEVELOPMENT_TEAM = ABCDE12345
   ```
   You can find the team ID in Xcode → Settings → Accounts → your team, or in the Apple Developer portal.
3. Generate the project and run it:
   ```bash
   xcodegen generate
   open ChillyEye.xcodeproj   # then ⌘R on the "ChillyEye" scheme
   ```
4. To add the widget, right-click the desktop → Edit Widgets → search "Chilly Eye".

The widget needs a signed build. The app and the widget share their data through an App Group (`<team>.com.cecchetti.chillyeye`), and an unsigned build has no App Group, so the widget would stay empty.

## Tests

The scheduling, stats and storage logic lives in the `Core` Swift package:

```bash
cd Core && swift test
```

## Layout

| Path | What |
|------|------|
| `Core/` | `ChillyCore` package: models, scheduling, stats, JSON store (shared by app and widget) |
| `App/` | Menu bar app: timer engine, break overlay/popup, settings, idle/call detection, hotkey |
| `Widget/` | WidgetKit extension |
| `project.yml` | XcodeGen spec (the `.xcodeproj` is generated, not committed) |
