//
//  GoalEditorView.swift
//  DeenApp
//
//  Sheet zum Anlegen eines neuen Ziels. Schritt 1 = Typ wählen,
//  Schritt 2 = typ-spezifische Konfiguration + Freunde-Sichtbarkeit.
//

import SwiftUI

struct GoalEditorView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: GoalType? = nil
    @State private var visibleToFriends: Bool = false

    // Type-specific config
    @State private var khatmTargetDate: Date = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
    @State private var dailyPagesTarget: Int = 5
    @State private var sunnahKind: SunnahPrayerKind = .tahajjud
    @State private var sunnahWeeklyTarget: Int = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        sectionTitle(L10n.goalsPickType(appState.appLanguage))
                        typeGrid
                        if selectedType != nil {
                            sectionTitle(L10n.goalsConfigureTitle(appState.appLanguage))
                            typeConfig
                            visibilityCard
                            saveButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L10n.goalsAddNew(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.commonCancel(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.medium))
            .tracking(0.8)
            .foregroundColor(Theme.textSection)
    }

    private var typeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(GoalType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedType = type
                    }
                } label: {
                    typeTile(type)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func typeTile(_ type: GoalType) -> some View {
        let isSelected = selectedType == type
        return VStack(alignment: .leading, spacing: 10) {
            Image(systemName: type.iconName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : Theme.accent)
            Text(typeLabel(type))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .multilineTextAlignment(.leading)
            Text(typeBlurb(type))
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.85) : Theme.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(isSelected ? Theme.accent : Theme.cardBackground)
        )
    }

    @ViewBuilder
    private var typeConfig: some View {
        switch selectedType {
        case .khatmByDate:
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.goalsKhatmTargetDate(appState.appLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $khatmTargetDate,
                               in: Date()...,
                               displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .tint(Theme.accent)
                }
            }
        case .dailyQuranPages:
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.goalsDailyPagesTarget(appState.appLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Stepper(value: $dailyPagesTarget, in: 1...50) {
                        Text("\(dailyPagesTarget) \(L10n.goalsPagesUnit(appState.appLanguage))")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        case .fivePrayersDaily:
            CardContainer {
                Text(L10n.goalsFivePrayersBlurb(appState.appLanguage))
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        case .sunnahPrayer:
            CardContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.goalsSunnahPick(appState.appLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Picker("", selection: $sunnahKind) {
                        ForEach(SunnahPrayerKind.allCases, id: \.self) { kind in
                            Text(kind.localizedName(language: appState.appLanguage)).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper(value: $sunnahWeeklyTarget, in: 1...14) {
                        Text("\(sunnahWeeklyTarget)× \(L10n.goalsPerWeek(appState.appLanguage))")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        case .none:
            EmptyView()
        }
    }

    private var visibilityCard: some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Theme.accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.goalsShareWithFriends(appState.appLanguage))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(L10n.goalsShareBlurb(appState.appLanguage))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $visibleToFriends)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(L10n.goalsCreate(appState.appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(Theme.accent))
        }
        .padding(.top, 4)
    }

    // MARK: - Labels

    private func typeLabel(_ t: GoalType) -> String {
        switch t {
        case .khatmByDate:      return L10n.goalTypeKhatm(appState.appLanguage)
        case .dailyQuranPages:  return L10n.goalTypeDailyPages(appState.appLanguage)
        case .fivePrayersDaily: return L10n.goalTypeFivePrayers(appState.appLanguage)
        case .sunnahPrayer:     return L10n.goalTypeSunnah(appState.appLanguage)
        }
    }

    private func typeBlurb(_ t: GoalType) -> String {
        switch t {
        case .khatmByDate:      return L10n.goalTypeKhatmBlurb(appState.appLanguage)
        case .dailyQuranPages:  return L10n.goalTypeDailyPagesBlurb(appState.appLanguage)
        case .fivePrayersDaily: return L10n.goalTypeFivePrayersBlurb(appState.appLanguage)
        case .sunnahPrayer:     return L10n.goalTypeSunnahBlurb(appState.appLanguage)
        }
    }

    // MARK: - Save

    private func save() {
        guard let type = selectedType else { return }
        let goal: Goal
        switch type {
        case .khatmByDate:
            goal = Goal(
                type: .khatmByDate,
                visibleToFriends: visibleToFriends,
                khatmTargetDate: khatmTargetDate
            )
        case .dailyQuranPages:
            goal = Goal(
                type: .dailyQuranPages,
                visibleToFriends: visibleToFriends,
                dailyPagesTarget: dailyPagesTarget
            )
        case .fivePrayersDaily:
            goal = Goal(
                type: .fivePrayersDaily,
                visibleToFriends: visibleToFriends
            )
        case .sunnahPrayer:
            goal = Goal(
                type: .sunnahPrayer,
                visibleToFriends: visibleToFriends,
                sunnahKind: sunnahKind,
                sunnahWeeklyTarget: sunnahWeeklyTarget
            )
        }
        goalsVM.add(goal)
        dismiss()
    }
}
