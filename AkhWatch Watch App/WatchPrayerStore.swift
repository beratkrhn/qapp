//
//  WatchPrayerStore.swift
//  AkhWatch
//
//  Owns the most-recent prayer payload on the watch side. Persists into
//  the watch's UserDefaults.standard so the widget process — which runs
//  in its own sandbox — can decode the same data without WCSession.
//

import Foundation
import WidgetKit
import Combine

@MainActor
final class WatchPrayerStore: ObservableObject {

    static let shared = WatchPrayerStore()

    @Published private(set) var payload: WatchPrayerPayload?

    private init() {
        self.payload = WatchPrayerPayload.loadFromDisk()
    }

    /// Persist a freshly received payload and reload the widget timeline.
    func update(_ new: WatchPrayerPayload) {
        new.saveToDisk()
        payload = new
        WidgetCenter.shared.reloadAllTimelines()
    }
}
