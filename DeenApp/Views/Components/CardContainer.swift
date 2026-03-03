//
//  CardContainer.swift
//  DeenApp
//
//  Wiederverwendbare Karte mit Schatten & abgerundeten Ecken.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content
    var useHighlightBackground: Bool = false

    init(useHighlightBackground: Bool = false, @ViewBuilder content: () -> Content) {
        self.useHighlightBackground = useHighlightBackground
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(useHighlightBackground ? Theme.cardHighlightBackground : Theme.cardBackground)
            )
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadius,
                x: 0,
                y: Theme.shadowY
            )
    }
}
