# DailyDee / Akh-ira

A premium iOS app for Muslims: prayer times, Qur'an reading & memorisation (Hifz), Qibla compass, and structured Islamic learning. SwiftUI, MVVM, deep theming.

- Xcode project: `Akh-ira.xcodeproj`
- Bundle id: `d.DailyDee` (widget: `d.DailyDee.AkhWidget`)
- App Group: `group.d.DailyDee` (used to share prayer times + accent theme with widgets)
- Deployment target: iOS 26.2, Swift 5.9+, SwiftUI

## Targets

| Target | Folder | Purpose |
|---|---|---|
| `DailyDee` (main app) | `DeenApp/` | The app itself. `@main` is `DeenApp/DeenAppApp.swift`. |
| `AkhWidget` | `AkhWidget/` | Active WidgetKit extension (next prayer + countdown). |
| `PrayerTimesWidget` | `PrayerTimesWidget/` | Legacy widget — leave alone unless asked. |

`other/` holds one-off scripts (e.g. `extract_words.py` for vocab) and source PDFs that get bundled into `DeenApp/Resources/`.

## Architecture (strict MVVM)

```
DeenApp/
├── DeenAppApp.swift        # @main, environment objects, onboarding gate
├── Models/                 # Plain data + enums (PrayerKind, AppCity, QuranModels, …)
├── ViewModels/             # ObservableObjects (PrayerTimeManager, QuranStore, SRSViewModel, …)
├── Services/               # I/O: DitibAPIService, NotificationScheduler, QuranOfflineCache, LocationAutoUpdater
├── Views/                  # SwiftUI views; reusable pieces in Views/Components/
├── Resources/              # Theme.swift, L10n.swift, Assets, fonts, bundled JSON & PDFs
└── Utils/                  # PDFGenerator etc.
```

Rules:
- **Views are dumb.** No API calls, no business logic, no `URLSession`, no `Timer`. Observe state, declare UI.
- **ViewModels own state, async work, timers, persistence.** Use `@StateObject` to instantiate, `@EnvironmentObject` for app-wide state (`AppState`, `PrayerTimeManager`, `LocationAutoUpdater`).
- **Services are stateless** wrappers around external systems (DITIB, Aladhan, CoreLocation, UserNotifications).
- Modern Swift Concurrency (`async/await`, `Task`, `@MainActor`) over completion handlers. Combine only where it genuinely fits (reactive pipelines).

## Persistence & shared state

- User preferences live in `UserDefaults` with the `dailydee.*` key prefix (see `AppState.UserDefaultsKeys`). Don't invent new prefixes.
- Anything the widget needs (current city, prayer snapshot, accent theme) must be written to **both** `UserDefaults.standard` and `UserDefaults(suiteName: "group.d.DailyDee")`, then `WidgetCenter.shared.reloadAllTimelines()`. Pattern in `AppState.accentTheme.didSet`.
- Shared prayer payloads go through `DeenApp/SharedPrayerData.swift` and `Models/PrayerWidgetSnapshot.swift`.

## Prayer times

- Two providers behind `PrayerTimeProvider`: **DITIB** (`DitibAPIService`, preferred for DE/TR cities) and **Aladhan** (fallback / international). Custom calculation parameters live in `Models/PrayerCalculationSettings.swift`.
- City selection: dynamic `selectedDitibCity: DitibCity?` is the source of truth; legacy `selectedCity: AppCity` is the fallback. Use `appState.currentCityName` rather than reading either directly.
- Auto-GPS follow is opt-in via `appState.autoLocationEnabled`; `LocationAutoUpdater` binds to `AppState` + `PrayerTimeManager` in `DeenAppApp.task`.
- Heimat-/Seferi logic uses `AppState.homeCity` (separate from the active city).

## Localisation

- All user-facing strings go through `Resources/L10n.swift` — do **not** hardcode strings in views.
- Languages: `german`, `english`, `turkish`, `germanArabic`, `germanTurkish` (`Models/AppLanguage.swift`). German is the default; many in-code comments and commit messages are German — keep that style.
- New screens must add entries to `L10n` for every language, even if the German string is reused.

## Theming

- `Resources/Theme.swift` exposes accent-aware, light/dark-adaptive colors. Always use `Theme.background`, `Theme.cardBackground`, `Theme.textPrimary`, `Theme.accent`, etc. — never raw `Color(...)` literals in views.
- Accent palette is driven by `ThemeColor` (default `.emeraldGreen`); changing it must propagate to the App Group + reload widget timelines (see `AppState.accentTheme.didSet`).
- Visual language: rounded corners, soft shadows, `.ultraThinMaterial` for elevated surfaces, spring animations for state changes. Avoid jarring transitions.

## Design / UX guidelines

- Premium, calm aesthetic. Generous spacing, typography hierarchy, no clutter.
- Animate state changes (`.animation(.spring(), value: …)`); avoid implicit animations on layout-shifting properties.
- Arabic text uses the bundled fonts in `Resources/fonts/` and `JustifiedArabicText` for paragraph layout.

## Coding standards

- No force unwraps (`!`) outside of clearly-safe `IBOutlet`-style bindings. Use `guard let` / `if let`.
- No print logging in committed code; if logging is needed, prefer `os.Logger`.
- Keep files focused. Reusable view fragments → `Views/Components/`.
- New PDFs/images: drop the source into `other/`, copy the production-ready file into `DeenApp/Resources/`, register in the Xcode target.

## Build & run

- Open `Akh-ira.xcodeproj`, scheme **DailyDee**, run on a simulator (iPhone 15+/iOS 26+) or device.
- Location permissions are required for auto-GPS; the simulator falls back to Berlin.
- Widget testing: build the **AkhWidget** scheme to a device that has the host app installed; the App Group must match.

## Don't

- Don't add a second `@main` — only `DeenAppApp` is the entry point. Legacy `DailyDeen/` material has been removed; if you find references, treat them as dead.
- Don't bypass `AppState` for persisted preferences (no ad-hoc `UserDefaults` reads in views).
- Don't add backwards-compat shims for removed enum cases — `AppState.init` already migrates legacy values; extend that block instead.
- Don't introduce new third-party dependencies without asking.
