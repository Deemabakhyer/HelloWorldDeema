# Learning Streak

A SwiftUI app that helps you build a daily learning habit. Pick something to learn and how long you want to take, then log each day as **learned**, or use a **freeze** when you can't. Finish every day of your goal to complete it; miss a day and the streak starts over.

The UI is built for **iOS 26** and uses native **Liquid Glass** components.

---

## Features

- **Onboarding** – choose a subject (e.g. *Swift*) and a duration (Week / Month / Year).
- **Activity screen** – week strip, Learned / Freezed counters, a big *Log as Learned* button and a *Freeze for a day* button with a freeze counter.
- **Goal results** – a *Well done!* or *You didn't reach your goal this time* screen when a goal ends, with a shortcut to set the next goal.
- **Update goal** – a pushed page to change the subject or duration, with a "your streak will start over" alert.
- **Calendar** – a view-only, scrolling month-by-month calendar of learned and frozen days.
- **Persistence** – progress and the current goal are saved on the device.

## Requirements

| | |
|---|---|
| Xcode | 26 or later |
| Deployment target | iOS 26 or later |
| Language | Swift 6 / SwiftUI |
| Dependencies | None |

## Getting started

1. Open the project in Xcode 26.
2. Make sure the asset catalog contains two **Color Sets**: `Orange` and `Cyan` (see [Assets](#assets)).
3. Set `RootView` as the app's root:

   ```swift
   @main
   struct MyAppApp: App {
       var body: some Scene {
           WindowGroup {
               RootView()
           }
       }
   }
   ```
4. Run on an iOS 26 simulator or device.

Onboarding is shown only on first launch. To see it again, delete the app from the simulator or clear the `hasCompletedOnboarding` key.

---

## Project structure

| File | Purpose |
|---|---|
| `RootView.swift` | Shows onboarding on first launch, then the Activity screen. Owns the shared `ActivityViewModel`. |
| `OnboardingView.swift` | Welcome screen. Also defines `LearningDuration` (Week / Month / Year). Calls `onStart(subject, duration)` when *Start Learning* is pressed. |
| `ActivityView.swift` | Main screen: header, week strip, stat cards, log / freeze buttons, goal result view. Hosts the `NavigationStack`. |
| `UpdateGoalView.swift` | Pushed page to change the learning goal, with the confirmation alert. |
| `CalendarView.swift` | View-only calendar of learned and frozen days. |
| `ActivityViewModel.swift` | All app logic and state (`@Observable`). |
| Model types | `DayStatus` (`learned`, `frozen`), `Goal`, `GoalState` (`active`, `completed`, `failed`), and a `LearningDuration` extension (`days`, `closest(toDays:)`). |

### Navigation

```
RootView
 ├─ OnboardingView ──(Start Learning)──▶ ActivityView
 └─ ActivityView  (NavigationStack)
      ├─ calendar button ──▶ CalendarView
      └─ pencil button / "Set a goal" ──▶ UpdateGoalView
```

---

## How it works

### Architecture

The app uses **MVVM** with the Observation framework. `ActivityViewModel` is the single source of truth; views only read from it and call its actions.

### Data model

- `entries: [String: DayStatus]` – one entry per day, keyed by `yyyy-MM-dd`. A day with no entry is "not logged".
- `goal: Goal` – `subject`, `startDate`, `targetDays`.

Counters (Learned, Freezed, freezes used) are **derived** from the entries, so they can never get out of sync.

### Goal rules

| Duration | Goal length | Freezes allowed |
|---|---|---|
| Week | 7 days | 2 |
| Month | 30 days | 6 |
| Year | 365 days | 12 |

- A goal is **completed** when every day from its start date is either *learned* or *frozen*.
- A goal **fails** when a past day has no entry.
- Otherwise it is **active**, and the Log / Freeze buttons are available.
- Days before the goal's start date are ignored by the Activity screen.

### Logging and freezing

- *Log as Learned* marks today as learned. If today was frozen, it becomes learned and the freeze is given back.
- *Freeze for a day* marks today as frozen. It is disabled once today is frozen, when all freezes are used, or when the goal has ended.
- Both actions are locked once a goal is completed or failed.

### Updating the goal

- While a goal is **active**, changing it shows an alert: *"If you update now, your streak will start over."* Saving without changes just goes back.
- After a goal **ended**, the confirm button sets the new goal straight away, even if the subject and duration are unchanged ("set the same goal again").
- Starting a new goal begins today and clears today's previous entry.

### Calendar

Shows the current month and every following month through December. Learned days are orange, frozen days are cyan, and today (with nothing logged) is a filled orange circle. The screen is view only.

### Persistence

Data is stored in `UserDefaults`:

| Key | Content |
|---|---|
| `activity.entries` | JSON of all day entries |
| `activity.goal` | JSON of the current goal |
| `hasCompletedOnboarding` | `Bool`, set after onboarding |

`ActivityViewModel` accepts `persistenceKey: nil`, plus `seed`, `goal` and `now` parameters, so previews and tests can run with fixed data and no saving.

---

## Assets

Add these **Color Sets** to the asset catalog:

| Name | Used for | Suggested value |
|---|---|---|
| `Orange` | Learned days, main buttons, accents | `#F58C21` |
| `Cyan` | Frozen days, freeze button | `#64CAF2` |

## Liquid Glass components used

- `glassEffect(_:in:)` with `.regular`, `.tint(_:)` and `.interactive()`
- `GlassEffectContainer`
- `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)`
- `Button(role: .confirm)` in the navigation bar toolbar
