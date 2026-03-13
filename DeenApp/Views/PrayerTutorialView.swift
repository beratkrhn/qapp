//
//  PrayerTutorialView.swift
//  DeenApp
//
//  Interaktive Schritt-für-Schritt-Ansicht für das Gebetstutorial.
//

import SwiftUI

struct PrayerTutorialView: View {
    @Environment(PrayerTutorialViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showArabic") private var showArabic = true
    @AppStorage("showTransliteration") private var showTransliteration = true
    @AppStorage("showTranslation") private var showTranslation = true

    private var activeCount: Int {
        [showArabic, showTransliteration, showTranslation].filter(\.self).count
    }

    private var arabicBaseSize: CGFloat {
        switch activeCount {
        case 1:  return 80
        case 2:  return 60
        default: return 48
        }
    }

    private var translitBaseSize: CGFloat {
        switch activeCount {
        case 1:  return 70
        case 2:  return 50
        default: return 38
        }
    }

    private var translationBaseSize: CGFloat {
        switch activeCount {
        case 1:  return 60
        case 2:  return 44
        default: return 34
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let step = viewModel.currentStep {
                VStack(spacing: 0) {
                    poseVisual(for: step)
                    textContent(for: step)
                }
                .safeAreaInset(edge: .bottom) {
                    navigationBar
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.stepProgress)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(1)
            }
        }
    }

    // MARK: - Top Half: Pose Visual

    @ViewBuilder
    private func poseVisual(for step: PrayerStep) -> some View {
        let imageName = viewModel.selectedGender == .female
            ? step.imageNameFemale
            : step.imageNameMale

        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)

            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: poseSystemIcon(for: step.id))
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(Theme.accent.opacity(0.6))

                    Text(imageName)
                        .font(.caption2.monospaced())
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: 220)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Bottom Half: Text Content (No-Scroll, Aggressive Scaling)

    private func textContent(for step: PrayerStep) -> some View {
        VStack(spacing: 6) {
            Text(step.title)
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            if showArabic, let arabic = step.arabicText, !arabic.isEmpty {
                Text(arabic)
                    .font(QuranArabicFont.getHafsFont(size: arabicBaseSize))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(20)
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            if showTransliteration, let translit = step.transliteration, !translit.isEmpty {
                Text(translit)
                    .font(.system(size: translitBaseSize))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(15)
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if showTranslation, let translation = step.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: translationBaseSize))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(15)
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if activeCount == 0 {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pinned Bottom Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.previousStep()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Zurück")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(viewModel.isFirstStep ? Theme.textSecondary.opacity(0.4) : Theme.accent)
            }
            .disabled(viewModel.isFirstStep)

            Spacer()

            stepIndicator

            Spacer()

            Button {
                if viewModel.isLastStep {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.isLastStep ? "Abschließen" : "Weiter")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: viewModel.isLastStep ? "checkmark" : "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundColor(Theme.accent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 100)
        .background(
            Theme.cardBackground
                .shadow(color: Theme.shadowColor, radius: 8, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Step Indicator Dots

    private var stepIndicator: some View {
        let total = viewModel.steps.count
        let current = viewModel.currentStepIndex
        let windowSize = 7
        let half = windowSize / 2

        let start = max(0, min(current - half, total - windowSize))
        let end = min(total, start + windowSize)
        let range = start..<end

        return HStack(spacing: 4) {
            ForEach(range, id: \.self) { idx in
                Circle()
                    .fill(idx == current ? Theme.accent : Theme.textSecondary.opacity(0.3))
                    .frame(width: idx == current ? 8 : 5, height: idx == current ? 8 : 5)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }

    // MARK: - Fallback Icon Mapping

    private func poseSystemIcon(for stepId: String) -> String {
        if stepId.contains("sujud") || stepId.contains("sajda") {
            return "arrow.down.to.line"
        } else if stepId.contains("ruku") {
            return "figure.flexibility"
        } else if stepId.contains("jalsa") || stepId.contains("qa_da") || stepId.contains("tahiyyat") || stepId.contains("salli") || stepId.contains("barik") || stepId.contains("rabbena") {
            return "figure.seated.seatbelt"
        } else if stepId.contains("salam") {
            return "hand.wave.fill"
        } else if stepId.contains("takbir") {
            return "hands.sparkles.fill"
        } else {
            return "figure.stand"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerTutorialView()
    }
    .environment({
        let vm = PrayerTutorialViewModel()
        vm.selectedGender = .male
        vm.loadSteps(for: "fajr_fard")
        return vm
    }())
}
