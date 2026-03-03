//
//  AppState.swift
//  DeenApp
//
//  Globaler App-Zustand (z. B. ausgewählter Tab, Nutzername)
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var selectedTab: MainTab = .start
    @Published var userName: String = "Berat"
}

enum MainTab: Int, CaseIterable {
    case start = 0
    case quran
    case lernen
    case gebet

    var title: String {
        switch self {
        case .start: return "Start"
        case .quran: return "Quran"
        case .lernen: return "Lernen"
        case .gebet: return "Gebet"
        }
    }

    var iconName: String {
        switch self {
        case .start: return "house.fill"
        case .quran: return "book.fill"
        case .lernen: return "graduationcap.fill"
        case .gebet: return "heart.fill"
        }
    }
}
