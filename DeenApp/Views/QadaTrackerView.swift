//
//  QadaTrackerView.swift
//  DeenApp
//
//  Tracks missed (qada/kaza) prayers. Shows a setup flow then an adjustable
//  per-prayer missed-count list with + / - buttons and inline editing.
//

import SwiftUI

// MARK: - Obligatory daily prayers tracked for qada
private let qadaPrayers: [PrayerKind] = [.imsak, .dhuhr, .asr, .maghrib, .isha]

// MARK: - Dashboard entry card

struct QadaTrackerCard: View {
    @EnvironmentObject var appState: AppState
    var onTap: () -> Void

    @AppStorage("qada.isSetup")        private var isSetup: Bool = false
    @AppStorage("qada.missed.fajr")    private var missedFajr: Int = 0
    @AppStorage("qada.missed.dhuhr")   private var missedDhuhr: Int = 0
    @AppStorage("qada.missed.asr")     private var missedAsr: Int = 0
    @AppStorage("qada.missed.maghrib") private var missedMaghrib: Int = 0
    @AppStorage("qada.missed.isha")    private var missedIsha: Int = 0

    private var totalMissed: Int { missedFajr + missedDhuhr + missedAsr + missedMaghrib + missedIsha }
    private var lang: AppLanguage { appState.appLanguage }

    var body: some View {
        Button(action: onTap) {
            CardContainer {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.qadaTitle(lang).uppercased())
                            .font(.caption.weight(.medium))
                            .tracking(0.8)
                            .foregroundStyle(Theme.textSection)

                        if isSetup {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(totalMissed)")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(L10n.qadaMissedLabel(lang))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        } else {
                            Text(L10n.qadaSetupPrompt(lang))
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Tracker Sheet

struct QadaTrackerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Persistence
    @AppStorage("qada.isSetup")        private var isSetup: Bool    = false
    @AppStorage("qada.startDate")      private var startDateTI: Double = 0
    @AppStorage("qada.missed.fajr")    private var missedFajr: Int    = 0
    @AppStorage("qada.missed.dhuhr")   private var missedDhuhr: Int   = 0
    @AppStorage("qada.missed.asr")     private var missedAsr: Int     = 0
    @AppStorage("qada.missed.maghrib") private var missedMaghrib: Int  = 0
    @AppStorage("qada.missed.isha")    private var missedIsha: Int    = 0

    // Setup state
    @State private var setupStep = 1
    @State private var selectedDate: Date = Calendar.current.date(
        byAdding: .year, value: -10, to: Date()
    ) ?? Date()
    @State private var prayedInputs: [PrayerKind: String] = [:]
    @State private var showResetConfirm = false

    private var lang: AppLanguage { appState.appLanguage }
    private var startDate: Date { Date(timeIntervalSince1970: startDateTI) }
    private var totalMissed: Int { missedFajr + missedDhuhr + missedAsr + missedMaghrib + missedIsha }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if isSetup {
                            mainContent
                        } else if setupStep == 1 {
                            step1Content
                        } else {
                            step2Content
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle(L10n.qadaTitle(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.settingsDone(lang)) { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                if isSetup {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(L10n.qadaReset(lang)) { showResetConfirm = true }
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .confirmationDialog(
                L10n.qadaResetQuestion(lang),
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.qadaReset(lang), role: .destructive) { resetSetup() }
                Button(L10n.settingsDone(lang), role: .cancel) {}
            }
        }
    }

    // MARK: - Step 1: Date Picker

    @ViewBuilder
    private var step1Content: some View {
        VStack(spacing: 20) {
            Text(L10n.qadaStartDateQuestion(lang))
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 8)

            CardContainer {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Theme.accent)
                .frame(maxWidth: .infinity)
            }

            Button {
                setupStep = 2
            } label: {
                Text(L10n.onboardingContinue(lang))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Step 2: Prayers Prayed Input

    @ViewBuilder
    private var step2Content: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(L10n.qadaHowManyPrayed(lang))
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.qadaSinceDate(lang, date: selectedDate))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)

            CardContainer {
                VStack(spacing: 0) {
                    ForEach(qadaPrayers, id: \.self) { prayer in
                        HStack(spacing: 12) {
                            Image(systemName: prayer.iconName)
                                .font(.body)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 24)

                            Text(prayer.localizedName(for: lang))
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            TextField("0", text: Binding(
                                get: { prayedInputs[prayer] ?? "" },
                                set: { prayedInputs[prayer] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 80)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Theme.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding(.vertical, 13)

                        if prayer != qadaPrayers.last {
                            Divider()
                                .background(Theme.textSecondary.opacity(0.2))
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    setupStep = 1
                } label: {
                    Text(L10n.qadaBack(lang))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1.5)
                        )
                }

                Button {
                    calculateAndSave()
                } label: {
                    Text(L10n.qadaCalculate(lang))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    // MARK: - Main Tracker Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
            Text(L10n.qadaSinceDate(lang, date: startDate))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)

            // Total badge
            CardContainer(useHighlightBackground: true) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.qadaTotalLabel(lang))
                            .font(.caption.weight(.medium))
                            .tracking(0.8)
                            .foregroundStyle(Theme.textSection)
                        Text("\(totalMissed)")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: totalMissed == 0 ? "checkmark.seal.fill" : "list.bullet.clipboard.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.accent.opacity(0.2))
                }
            }

            // Per-prayer rows
            CardContainer {
                VStack(spacing: 0) {
                    ForEach(qadaPrayers, id: \.self) { prayer in
                        QadaPrayerRow(
                            prayer: prayer,
                            lang: lang,
                            count: missedValue(for: prayer),
                            onDecrement: { setMissed(missedValue(for: prayer) - 1, for: prayer) },
                            onIncrement: { setMissed(missedValue(for: prayer) + 1, for: prayer) },
                            onEdit: { setMissed($0, for: prayer) }
                        )
                        if prayer != qadaPrayers.last {
                            Divider()
                                .background(Theme.textSecondary.opacity(0.15))
                                .padding(.leading, 48)
                        }
                    }
                }
            }

            Text(L10n.qadaEditHint(lang))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func missedValue(for prayer: PrayerKind) -> Int {
        switch prayer {
        case .imsak:   return missedFajr
        case .dhuhr:   return missedDhuhr
        case .asr:     return missedAsr
        case .maghrib: return missedMaghrib
        case .isha:    return missedIsha
        default:       return 0
        }
    }

    private func setMissed(_ value: Int, for prayer: PrayerKind) {
        let v = max(0, value)
        switch prayer {
        case .imsak:   missedFajr    = v
        case .dhuhr:   missedDhuhr   = v
        case .asr:     missedAsr     = v
        case .maghrib: missedMaghrib = v
        case .isha:    missedIsha    = v
        default:       break
        }
    }

    private func calculateAndSave() {
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: selectedDate),
            to: cal.startOfDay(for: Date())
        ).day ?? 0
        let totalDays = max(0, days)

        for prayer in qadaPrayers {
            let prayed = Int(prayedInputs[prayer] ?? "0") ?? 0
            setMissed(max(0, totalDays - prayed), for: prayer)
        }

        startDateTI = selectedDate.timeIntervalSince1970
        isSetup = true
    }

    private func resetSetup() {
        missedFajr    = 0
        missedDhuhr   = 0
        missedAsr     = 0
        missedMaghrib = 0
        missedIsha    = 0
        startDateTI   = 0
        prayedInputs  = [:]
        setupStep     = 1
        isSetup       = false
    }
}

// MARK: - Prayer Row

private struct QadaPrayerRow: View {
    let prayer: PrayerKind
    let lang: AppLanguage
    let count: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onEdit: (Int) -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.iconName)
                .font(.body)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)

            Text(prayer.localizedName(for: lang))
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(count > 0 ? Theme.accent : Theme.textSecondary.opacity(0.25))
                }
                .disabled(count == 0)
                .buttonStyle(.plain)

                if isEditing {
                    TextField("", text: $editText)
                        .keyboardType(.numberPad)
                        .focused($fieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.body.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 60)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onSubmit { commitEdit() }
                        .onChange(of: fieldFocused) { _, focused in
                            if !focused { commitEdit() }
                        }
                } else {
                    Text("\(count)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minWidth: 52, alignment: .center)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editText = "\(count)"
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                fieldFocused = true
                            }
                        }
                }

                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
    }

    private func commitEdit() {
        if let value = Int(editText) {
            onEdit(value)
        }
        isEditing = false
    }
}

#Preview {
    QadaTrackerView()
        .environmentObject(AppState())
}
