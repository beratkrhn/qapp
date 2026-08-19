//
//  DeenAppApp.swift
//  DeenApp
//
//  Islamische Gebetszeiten & Spiritualität
//

import SwiftUI
import UIKit
import UserNotifications
import FirebaseCore

@main
struct DeenAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var prayerTimeManager = PrayerTimeManager()
    @StateObject private var appState = AppState()
    @StateObject private var locationAutoUpdater = LocationAutoUpdater()
    @StateObject private var accountVM: AccountViewModel
    @StateObject private var goalsVM: GoalsViewModel

    init() {
        _accountVM = StateObject(wrappedValue: AccountViewModel())
        _goalsVM = StateObject(wrappedValue: GoalsViewModel())
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(prayerTimeManager)
            .environmentObject(appState)
            .environmentObject(locationAutoUpdater)
            .environmentObject(accountVM)
            .environmentObject(goalsVM)
            .preferredColorScheme(.dark)
            .task {
                locationAutoUpdater.bind(appState: appState,
                                         prayerTimeManager: prayerTimeManager)
                if appState.autoLocationEnabled {
                    locationAutoUpdater.start()
                }
                PhoneWatchSession.shared.activate()
                // Push-Berechtigung anfragen, sobald der Nutzer eingeloggt ist;
                // bei nicht eingeloggten Nutzern macht sie noch keinen Sinn.
                if accountVM.isSignedIn {
                    PushTokenService.shared.requestAuthorizationIfNeeded()
                }
            }
        }
    }
}

// MARK: - AppDelegate adapter
//
// Bridge für die APNs-Callbacks und Firebase-Konfiguration. SwiftUI bietet
// dafür keinen App-Lifecycle-Hook, deshalb der UIApplicationDelegate-Adapter.

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        // Lazily startet das Token-Tracking (Auth-Wechsel + FCM-Delegate).
        Task { @MainActor in PushTokenService.shared.bootstrap() }
        return true
    }

    // APNs-Token wird vom System geliefert, sobald die Registrierung
    // erfolgreich war.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in PushTokenService.shared.setAPNsToken(deviceToken) }
    }

    // Nudge-Pushes setzen badge=1; beim Aktivieren der App wieder ausblenden.
    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - Foreground notification handler
//
// Sorgt dafür, dass eingehende Push-Nachrichten auch dann sichtbar sind, wenn
// die App im Vordergrund ist.

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions
    {
        [.banner, .sound, .badge]
    }
}
