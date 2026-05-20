//
//  WatchSessionReceiver.swift
//  AkhWatch
//
//  Receives WCSession application-context updates and complication
//  user-info transfers from the paired iPhone. Forwards decoded
//  payloads to WatchPrayerStore.
//

import Foundation
import WatchConnectivity
import os

@MainActor
final class WatchSessionReceiver: NSObject {

    static let shared = WatchSessionReceiver()

    private let logger = Logger(subsystem: "d.DailyDee.AkhWatch", category: "Receiver")
    private weak var store: WatchPrayerStore?

    private override init() {
        super.init()
    }

    func activate(store: WatchPrayerStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        // Drain whatever was last sent — applicationContext survives restarts.
        consume(session.receivedApplicationContext)
    }

    private func consume(_ context: [String: Any]) {
        guard let payload = WatchPrayerPayload.decode(from: context) else { return }
        Task { @MainActor [weak self] in
            self?.store?.update(payload)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error {
            Logger(subsystem: "d.DailyDee.AkhWatch", category: "Receiver")
                .error("Activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in self?.consume(applicationContext) }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor [weak self] in self?.consume(userInfo) }
    }
}
