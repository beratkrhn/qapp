//
//  PhoneWatchSession.swift
//  DeenApp
//
//  Activates WCSession on the iPhone side and pushes a prayer payload
//  to the paired Apple Watch every time PrayerTimeManager refreshes its
//  data. Uses updateApplicationContext (replace-on-write, no quota) for
//  general state and transferCurrentComplicationUserInfo for live
//  complication wakeups (limited to ~50/day by the system).
//
//  Target membership: DailyDee (iOS).
//

import Foundation
import WatchConnectivity
import os

@MainActor
final class PhoneWatchSession: NSObject {

    static let shared = PhoneWatchSession()

    private let logger = Logger(subsystem: "d.DailyDee", category: "PhoneWatchSession")
    private var lastPayloadHash: Int?

    private override init() {
        super.init()
    }

    /// Call once at app launch. Safe to call when no watch is paired.
    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Push the current prayer snapshot to the watch. No-op when no watch
    /// is paired or installed.
    func send(_ payload: WatchPrayerPayload) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }

        // Skip if nothing material changed since the last send.
        let hash = stableHash(of: payload)
        if hash == lastPayloadHash { return }
        lastPayloadHash = hash

        do {
            let dict = try payload.asDictionary()
            try session.updateApplicationContext(dict)
            // Wake the complication too — but only if budget exists.
            if session.isComplicationEnabled {
                session.transferCurrentComplicationUserInfo(dict)
            }
        } catch {
            logger.error("Failed to push payload to watch: \(error.localizedDescription)")
        }
    }

    private func stableHash(of payload: WatchPrayerPayload) -> Int {
        var hasher = Hasher()
        hasher.combine(payload.cityName)
        hasher.combine(payload.accentThemeRaw)
        for p in payload.prayers {
            hasher.combine(p.kindRaw)
            hasher.combine(p.timeString)
            hasher.combine(p.time)
        }
        return hasher.finalize()
    }
}

// MARK: - WCSessionDelegate (iOS requires the full set of stubs)

extension PhoneWatchSession: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error {
            Logger(subsystem: "d.DailyDee", category: "PhoneWatchSession")
                .error("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required on iOS: re-activate so a newly-paired watch can connect.
        WCSession.default.activate()
    }
}
