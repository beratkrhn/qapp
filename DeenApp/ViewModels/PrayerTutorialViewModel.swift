//
//  PrayerTutorialViewModel.swift
//  DeenApp
//
//  Zustandsverwaltung für das interaktive Gebetstutorial.
//

import Foundation
import Observation

@Observable
final class PrayerTutorialViewModel {

    // MARK: - State

    var selectedGender: Gender?
    var selectedPrayer: String?
    private(set) var currentStepIndex: Int = 0
    private(set) var steps: [PrayerStep] = []

    // MARK: - Computed

    var currentStep: PrayerStep? {
        guard !steps.isEmpty, currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool  { currentStepIndex == steps.count - 1 }

    var stepProgress: String {
        guard !steps.isEmpty else { return "" }
        return "\(currentStepIndex + 1) / \(steps.count)"
    }

    // MARK: - Actions

    func loadSteps(for prayer: String) {
        selectedPrayer = prayer
        switch prayer {
        case "fajr_fard":    steps = PrayerTutorialData.steps(for: .fajr)
        case "dhuhr_fard":   steps = PrayerTutorialData.steps(for: .dhuhr)
        case "asr_fard":     steps = PrayerTutorialData.steps(for: .asr)
        case "maghrib_fard": steps = PrayerTutorialData.steps(for: .maghrib)
        case "isha_fard":    steps = PrayerTutorialData.steps(for: .isha)
        default:             steps = []
        }
        currentStepIndex = 0
    }

    func nextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        currentStepIndex += 1
    }

    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    func reset() {
        currentStepIndex = 0
        steps = []
        selectedPrayer = nil
    }
}
