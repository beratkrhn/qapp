//
//  AkhWatchApp.swift
//  AkhWatch (watchOS app target)
//
//  Minimal host app that activates a WCSession on launch so the watch
//  can receive prayer payloads from the iPhone. The complication is
//  declared by the AkhWatchWidget extension target.
//

import SwiftUI

@main
struct AkhWatchApp: App {
    @StateObject private var store = WatchPrayerStore.shared

    init() {
        // Wire the receiver to the store so payloads land in UserDefaults
        // and reload the widget timeline.
        WatchSessionReceiver.shared.activate(store: WatchPrayerStore.shared)
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
