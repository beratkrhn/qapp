//
//  HeaderView.swift
//  DeenApp
//
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
                cycleDone = true
            }
        }
    }
}

#Preview {
    HeaderView(userName: "Berat", cityName: "Berlin")
        .padding()
        .background(Theme.background)
}
