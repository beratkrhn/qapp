# DeenApp

Moderne, spirituelle Islam-App (Gebetszeiten, Quran, Lernen) mit High-End SwiftUI-Design.

## Anforderungen

- Xcode 15+
- iOS 17+
- Swift 5.9+

## Projekt in Xcode öffnen

Die Codebasis ist als reine Ordnerstruktur angelegt. So bindest du sie in ein Xcode-Projekt ein:

1. **Neues Projekt anlegen**
   - Xcode → File → New → Project
   - **iOS** → **App**
   - Product Name: `DeenApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Speicherort: Wähle den Ordner `dailydeen` (oder lege das Projekt darin an)

2. **Bestehenden Code einbinden**
   - Lösche die automatisch erzeugte `ContentView.swift` (oder ersetze sie).
   - Im Project Navigator: Rechtsklick auf die gelbe **DeenApp**-Gruppe → **Add Files to "DeenApp"…**
   - Navigiere zum Ordner **DeenApp** (der Unterordner mit allen Swift-Dateien).
   - Wähle den gesamten **DeenApp**-Ordner aus.
   - Optionen:
     - **Copy items if needed**: aus
     - **Create groups**
     - **Add to targets**: DeenApp angehakt
   - Mit **Add** bestätigen.

3. **Einstiegspunkt setzen**
   - Öffne die **Target**-Einstellungen (DeenApp unter TARGETS).
   - Unter **General** → **App Icons and Launch Screen**: prüfen, ob alles passt.
   - Unter **Info** (oder Info.plist):
     - Stelle sicher, dass die mitgelieferte **Info.plist** aus dem DeenApp-Ordner verwendet wird (oder übernimm deren Keys in die Target-Info):
       - `NSLocationWhenInUseUsageDescription` für Standort
       - `UIUserInterfaceStyle` = Dark (optional)

4. **Build & Run**
   - Simulator oder Gerät wählen und **Run** (⌘R).

## Ordnerstruktur (MVVM)

```
DeenApp/
├── DeenAppApp.swift          # App-Einstieg, Environment-Objects
├── Info.plist
├── Models/
│   ├── AppState.swift        # Globaler App-Zustand, Tab-Auswahl
│   ├── PrayerKind.swift      # Fajr, Dhuhr, Asr, Maghrib, Isha
│   ├── PrayerTime.swift      # Einzelne Gebetszeit
│   └── AladhanResponse.swift # API-Modelle (Aladhan)
├── ViewModels/
│   └── PrayerTimeManager.swift  # Aladhan API, Standort, Countdown
├── Views/
│   ├── MainTabView.swift
│   ├── DashboardView.swift
│   ├── HeaderView.swift
│   ├── TabBarView.swift
│   └── Components/
│       ├── CardContainer.swift
│       ├── NextPrayerCard.swift
│       ├── PrayerTimesCardView.swift
│       └── BottomInfoCardsView.swift
└── Resources/
    ├── Theme.swift           # Farben, Schatten, Layout (aus Screenshot)
    └── Assets.xcassets
```

## Features

- **Gebetszeiten**: Anzeige der 5 täglichen Gebete (Fajr/Sabah, Dhuhr/Öğle, Asr/İkindi, Maghrib/Akşam, Isha/Yatsı) über die [Aladhan API](https://aladhan.com/prayer-times-api).
- **Standort**: Automatische Nutzung des Gerätestandorts für die Zeitzone und Berechnung (Fallback: Berlin).
- **Nächstes Gebet**: Hervorgehobene Karte mit Countdown (z. B. „Sabah in 05:05:37“).
- **Design**: Dunkles Theme mit Grün-Palette, Karten mit Schatten und abgerundeten Ecken, Tab-Leiste (Start, Quran, Lernen, Gebet).

## Technik

- **SwiftUI** + **Combine**
- **Theme**-Struct für zentrale Farben und Layout-Werte
- **PrayerTimeManager**: `ObservableObject`, lädt Gebetszeiten per Adresse oder Koordinaten, berechnet nächstes Gebet und Countdown per Timer

## API

- Gebetszeiten: [Aladhan API](https://api.aladhan.com/v1/timingsByAddress?address=Berlin) (kostenfrei, keine API-Key-Pflicht).
