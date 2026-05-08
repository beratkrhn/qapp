//
//  SettingsView.swift
//  DeenApp
//
//  Einstellungen: Name, Sprache, Standort, Zeitrechnungsmethode.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var locationAutoUpdater: LocationAutoUpdater
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var nameInput: String = ""
    @StateObject private var locationVM = LocationSearchViewModel()
    @State private var notificationsEnabled: Bool = false
    @State private var notificationsDenied: Bool = false
    @State private var notificationMinutesBefore: Int = 15

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 24) {

                        // MARK: - Name
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsName(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                TextField(L10n.settingsNamePlaceholder(appState.appLanguage), text: $nameInput)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Theme.background)
                                    )
                                    .foregroundColor(Theme.textPrimary)
                                    .autocorrectionDisabled()
                                    .onSubmit { appState.updateName(nameInput) }
                                    .onChange(of: nameInput) { _, newValue in
                                        appState.updateName(newValue)
                                    }
                            }
                        }

                        // MARK: - Sprache
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.onboardingLanguagePrompt(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "globe")
                                        .foregroundColor(Theme.accent)
                                }

                                ForEach(AppLanguage.allCases) { lang in
                                    Button(action: { appState.updateLanguage(lang) }) {
                                        HStack {
                                            Text(lang.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.appLanguage == lang {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if lang != AppLanguage.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }
                            }
                        }

                        // MARK: - App Theme (Akzentfarbe)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label {
                                    Text("Akzentfarbe")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                                    spacing: 10
                                ) {
                                    ForEach(ThemeColor.allCases) { theme in
                                        Button(action: { appState.updateAccentTheme(theme) }) {
                                            ZStack {
                                                Circle()
                                                    .fill(theme.color)
                                                    .frame(width: 38, height: 38)
                                                if appState.accentTheme == theme {
                                                    Circle()
                                                        .strokeBorder(accentSelectionRingColor, lineWidth: 2.5)
                                                        .frame(width: 38, height: 38)
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(theme.displayName)
                                    }
                                }

                                Text(appState.accentTheme.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Theme.accent)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        // MARK: - Standort (Dynamic DITIB picker)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsLocation(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                // Current selection
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appState.selectedDitibCity?.name ?? appState.selectedCity.displayName)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Aktuell ausgewählt")
                                            .font(.caption)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accent)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 4)

                                // Auto-Standort: GPS-basierte Stadtaktualisierung alle 10 Minuten
                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                Toggle(isOn: Binding(
                                    get: { appState.autoLocationEnabled },
                                    set: { handleAutoLocationToggle($0) }
                                )) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Standort automatisch erkennen")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Aktualisiert die Stadt alle 10 Minuten anhand deiner GPS-Position.")
                                            .font(.caption)
                                            .foregroundColor(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .tint(Theme.accent)
                                .padding(.horizontal, 4)

                                if appState.autoLocationEnabled {
                                    if let detected = locationAutoUpdater.lastDetectedCityName {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(Theme.accent)
                                            Text("Erkannt: \(detected)")
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        .padding(.horizontal, 4)
                                    } else if locationAutoUpdater.isFetching {
                                        HStack(spacing: 8) {
                                            ProgressView().scaleEffect(0.7)
                                            Text("Standort wird ermittelt…")
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }

                                if let err = locationAutoUpdater.lastErrorMessage,
                                   appState.autoLocationEnabled || locationAutoUpdater.authorizationStatus == .denied {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                        Text(err)
                                            .font(.caption)
                                            .foregroundColor(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.horizontal, 4)

                                    if locationAutoUpdater.authorizationStatus == .denied {
                                        Button(action: openAppSettings) {
                                            HStack {
                                                Image(systemName: "gear").font(.system(size: 13))
                                                Text("In iOS-Einstellungen öffnen").font(.subheadline)
                                            }
                                            .foregroundColor(Theme.accent)
                                            .padding(.horizontal, 4)
                                        }
                                    }
                                }

                                // Recent cities — shown directly (no hidden button)
                                if !locationVM.recentCities.isEmpty {
                                    Divider().overlay(Theme.textSecondary.opacity(0.2))

                                    Label("Zuletzt verwendet", systemImage: "clock.arrow.circlepath")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Theme.textSecondary)
                                        .padding(.horizontal, 4)

                                    ForEach(locationVM.recentCities) { city in
                                        Button(action: {
                                            locationVM.confirmCity(city, appState: appState, prayerTimeManager: prayerTimeManager)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: "clock")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.textSecondary.opacity(0.6))
                                                    .frame(width: 20)
                                                Text(city.name)
                                                    .font(.body)
                                                    .foregroundColor(Theme.textPrimary)
                                                Spacer()
                                                if appState.selectedDitibCity?.id == city.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Theme.accent)
                                                }
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                // Navigate to full state → city picker
                                NavigationLink {
                                    StateSelectionView(locationVM: locationVM)
                                        .environmentObject(appState)
                                        .environmentObject(prayerTimeManager)
                                } label: {
                                    HStack {
                                        Text("Neuen Ort wählen")
                                            .font(.body)
                                            .foregroundColor(Theme.accent)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }

                        // MARK: - Heimatstadt (für Seferi-Berechnung)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text("Heimatstadt")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "house.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                Text("Wird für die Seferi-Distanz im Qibla-Kompass verwendet (>90 km Luftlinie = Seferi).")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let home = appState.homeCity {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(home.name)
                                                .font(.body.weight(.semibold))
                                                .foregroundColor(Theme.textPrimary)
                                            Text("Aktuelle Heimatstadt")
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.accent)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 4)
                                } else {
                                    Text("Noch nicht festgelegt")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                        .padding(.horizontal, 4)
                                }

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                NavigationLink {
                                    HomeCityPickerView()
                                        .environmentObject(appState)
                                } label: {
                                    HStack {
                                        Text(appState.homeCity == nil ? "Heimatstadt wählen" : "Heimatstadt ändern")
                                            .font(.body)
                                            .foregroundColor(Theme.accent)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }

                                if appState.homeCity != nil {
                                    Button(role: .destructive) {
                                        appState.updateHomeCity(nil)
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                                .font(.system(size: 13))
                                            Text("Heimatstadt entfernen")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }

                        // MARK: - Gebetszeiten-Quelle
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsPrayerSource(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundColor(Theme.accent)
                                }

                                ForEach(PrayerTimeProvider.allCases) { provider in
                                    Button(action: {
                                        appState.updatePrayerTimeProvider(provider)
                                        if let city = appState.selectedDitibCity {
                                            prayerTimeManager.loadPrayerTimes(ditibCity: city)
                                        }
                                    }) {
                                        HStack {
                                            Text(provider.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.prayerTimeProvider == provider {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if provider != PrayerTimeProvider.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }
                            }
                        }

                        // MARK: - Zeitrechnungsmethode (Aladhan / Fazilet / Custom)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsCalculationMethod(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(Theme.accent)
                                }

                                if appState.prayerTimeProvider == .ditib {
                                    Text("Voreinstellung und eigene Parameter wirken bei der Quelle „Aladhan API“. DITIB liefert feste Vakitler.")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }

                                ForEach(AladhanPresetCalculation.allCases) { preset in
                                    Button(action: {
                                        appState.updatePrayerCalculation(.preset(preset))
                                        if let city = appState.selectedDitibCity {
                                            prayerTimeManager.loadPrayerTimes(ditibCity: city)
                                        }
                                    }) {
                                        HStack {
                                            Text(preset.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.prayerCalculation.presetValue == preset, !appState.prayerCalculation.isCustom {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if preset != AladhanPresetCalculation.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                NavigationLink {
                                    CustomPrayerCalculationView()
                                        .environmentObject(appState)
                                        .environmentObject(prayerTimeManager)
                                } label: {
                                    HStack {
                                        Text("Selber rechnen")
                                            .font(.body)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if appState.prayerCalculation.isCustom {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.accent)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        // MARK: - Benachrichtigungen
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.notificationsTitle(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                Text(L10n.notificationsDescription(appState.appLanguage))
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                Toggle(L10n.notificationsToggleLabel(appState.appLanguage), isOn: $notificationsEnabled)
                                    .tint(Theme.accent)
                                    .foregroundColor(Theme.textPrimary)
                                    .onChange(of: notificationsEnabled) { _, enabled in
                                        handleNotificationsToggle(enabled)
                                    }

                                if notificationsEnabled {
                                    Divider().overlay(Theme.textSecondary.opacity(0.2))

                                    HStack {
                                        Text(L10n.notificationsMinutesBefore(appState.appLanguage))
                                            .font(.body)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        HStack(spacing: 6) {
                                            ForEach(NotificationScheduler.allowedMinutes, id: \.self) { minutes in
                                                Button(action: {
                                                    notificationMinutesBefore = minutes
                                                    NotificationScheduler.shared.minutesBeforePrayer = minutes
                                                    NotificationScheduler.shared.schedulePrayerNotifications(
                                                        for: prayerTimeManager.prayerTimes,
                                                        cityName: prayerTimeManager.currentDitibCity?.name ?? "",
                                                        language: appState.appLanguage
                                                    )
                                                }) {
                                                    Text(L10n.notificationsMinutesUnit(appState.appLanguage, minutes: minutes))
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundColor(notificationMinutesBefore == minutes ? Theme.background : Theme.textPrimary)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                .fill(notificationMinutesBefore == minutes ? Theme.accent : Theme.background)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }

                                if notificationsDenied {
                                    Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    Button(action: openAppSettings) {
                                        HStack {
                                            Image(systemName: "gear")
                                                .font(.system(size: 13))
                                            Text(L10n.notificationsOpenSettings(appState.appLanguage))
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(Theme.accent)
                                    }
                                }
                            }
                        }

                        // MARK: - Feedback & TestFlight
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text("Dein Feedback ist wichtig!")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                Text("Diese App ist noch in der Beta-Phase und dein Feedback hilft uns enorm, sie zu verbessern. Bitte teile uns deine Gedanken, Fehlerberichte und Wünsche mit.")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Feedback über TestFlight senden:")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.textPrimary)

                                    HStack(alignment: .top, spacing: 8) {
                                        Text("1.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.accent)
                                        Text("Öffne die **TestFlight**-App auf deinem iPhone.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("2.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.accent)
                                        Text("Tippe auf **Akh-ira** in der Liste der Beta-Apps.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("3.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.accent)
                                        Text("Tippe auf **Feedback senden** und beschreibe dein Anliegen.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }

                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L10n.settingsTitle(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.settingsDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                nameInput = appState.userName
                notificationMinutesBefore = NotificationScheduler.shared.minutesBeforePrayer
                Task { await syncNotificationState() }
            }
        }
    }

    // MARK: - Notification Helpers

    private func syncNotificationState() async {
        let status = await NotificationScheduler.shared.authorizationStatus()
        let saved = NotificationScheduler.shared.isEnabled
        switch status {
        case .authorized, .provisional, .ephemeral:
            notificationsEnabled = saved
            notificationsDenied = false
        case .denied:
            notificationsEnabled = false
            notificationsDenied = saved // only show link if user previously tried to enable
        default:
            notificationsEnabled = false
            notificationsDenied = false
        }
    }

    private func handleNotificationsToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await NotificationScheduler.shared.requestPermission()
                if granted {
                    NotificationScheduler.shared.isEnabled = true
                    notificationsDenied = false
                    NotificationScheduler.shared.schedulePrayerNotifications(
                        for: prayerTimeManager.prayerTimes,
                        cityName: prayerTimeManager.currentDitibCity?.name ?? "",
                        language: appState.appLanguage
                    )
                } else {
                    NotificationScheduler.shared.isEnabled = false
                    notificationsEnabled = false
                    notificationsDenied = true
                }
            }
        } else {
            NotificationScheduler.shared.isEnabled = false
            NotificationScheduler.shared.cancelAll()
            notificationsDenied = false
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func handleAutoLocationToggle(_ enabled: Bool) {
        appState.autoLocationEnabled = enabled
        if enabled {
            locationAutoUpdater.start()
        } else {
            locationAutoUpdater.stop()
        }
    }

    private var accentSelectionRingColor: Color {
        colorScheme == .dark ? Color.white : Color.black.opacity(0.85)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
            )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(PrayerTimeManager())
        .environmentObject(LocationAutoUpdater())
}
