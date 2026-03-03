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

    // MARK: - Font animation state
    @State private var fontIndex: Int = 0
    @State private var animationDone: Bool = false
    @State private var greetingOpacity: Double = 1.0

    private let fontCycleTimer = Timer.publish(
        every: GreetingFontCycle.interval,
        on: .main,
        in: .common
    ).autoconnect()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {

            // Arabic greeting — font cycles through 10 styles with reliable fade animation
            Text(L10n.greetingArabic)
                .font(GreetingFontCycle.font(at: fontIndex))
                .foregroundColor(Theme.accent)
                .multilineTextAlignment(.center)
                // .id forces a full view replacement so SwiftUI loads the new font correctly
                .id(GreetingFontCycle.fontName(at: fontIndex))
                .opacity(greetingOpacity)

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
            animationDone = false
            greetingOpacity = 1.0
            #if DEBUG
            GreetingFontCycle.dumpAllFontNames()
            #endif
        }
        .onReceive(fontCycleTimer) { _ in
            guard !animationDone else { return }
            // Fade out → swap font → fade in
            withAnimation(.easeOut(duration: 0.15)) {
                greetingOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                if fontIndex < GreetingFontCycle.count - 1 {
                    fontIndex += 1
                } else {
                    animationDone = true
                }
                withAnimation(.easeIn(duration: 0.2)) {
                    greetingOpacity = 1
                }
            }
        }
    }
}

#Preview {
    HeaderView(userName: "Berat", cityName: "Berlin")
        .padding()
        .background(Theme.background)
}
