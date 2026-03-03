//
//  HeaderView.swift
//  DeenApp
//

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
    }
}

#Preview {
    HeaderView(userName: "Berat", timezone: "Europe/Berlin")
        .padding()
        .background(Theme.background)
}
