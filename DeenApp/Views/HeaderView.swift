//
//  HeaderView.swift
//  DeenApp
//
<<<<<<< HEAD
//  Zentrierter Header mit animierter arabischer Begrüßung (10 Schriften, danach Stopp),
//  großem Nutzernamen und Stadtanzeige.
//

import SwiftUI
import Combine

struct HeaderView: View {
    let userName: String
    let cityName: String

    /// Observing appState ensures the header re-renders instantly when the user
    /// changes the accent theme in Settings (Theme.accent is a computed var).
    @EnvironmentObject var appState: AppState

    // MARK: - Font cycle state (no animation — strict instant swap)
    @State private var fontIndex: Int = 0
    @State private var cycleDone: Bool = false

    private let fontCycleTimer = Timer.publish(
        every: GreetingFontCycle.interval,
        on: .main,
        in: .common
    ).autoconnect()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {

            // Arabic greeting — fixed-height container prevents layout shift
            // when fonts with different intrinsic heights cycle through.
            ZStack {
                Text(L10n.greetingArabic)
                    .font(GreetingFontCycle.font(at: fontIndex))
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                    .id(GreetingFontCycle.fontName(at: fontIndex))
                    .animation(nil, value: fontIndex)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(height: 50)
            .clipped()

            // User name — large, bold
            Text(userName)
                .font(.largeTitle.weight(.bold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            // City pin
            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill")
                    .font(.footnote)
                    .foregroundColor(Theme.accent.opacity(0.8))
                Text(cityName)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .onAppear {
            fontIndex = 0
            cycleDone = false
            #if DEBUG
            GreetingFontCycle.dumpAllFontNames()
            #endif
        }
        .onReceive(fontCycleTimer) { _ in
            guard !cycleDone else { return }
            if fontIndex < GreetingFontCycle.count - 1 {
                fontIndex += 1
            } else {
                // Pick a random font from the valid set so each launch settles on a different face.
                fontIndex = Int.random(in: 0..<max(GreetingFontCycle.count, 1))
                cycleDone = true
            }
        }
=======

import SwiftUI

struct HeaderView: View {
    let userName: String
    let timezone: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("السلام عليكم")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text(userName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(timezone)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.vertical, 8)
>>>>>>> origin/claude/adoring-banach
    }
}

#Preview {
<<<<<<< HEAD
    HeaderView(userName: "Berat", cityName: "Berlin")
=======
    HeaderView(userName: "Berat", timezone: "Europe/Berlin")
>>>>>>> origin/claude/adoring-banach
        .padding()
        .background(Theme.background)
}
