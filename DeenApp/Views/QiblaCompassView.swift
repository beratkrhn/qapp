//
//  QiblaCompassView.swift
//  DeenApp
//
//  Classic Qibla compass: a rotating compass dial with N/E/S/W markers and
//  an arrow that points toward the Kaaba. Below the dial sits the
//  "Bin ich Seferi?"-tool: it shows the great-circle distance from the user's
//  current GPS position to their stored Heimatstadt, and warns once that
//  distance crosses 90 km.
//

import SwiftUI
import CoreLocation

struct QiblaCompassView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = QiblaCompassViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        compassSection
                        seferSection
                        if let err = vm.errorMessage {
                            errorBanner(err)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Qibla-Kompass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                vm.bind(appState: appState)
                vm.start()
            }
            .onDisappear { vm.stop() }
        }
    }

    // MARK: - Compass

    private var compassSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(Theme.textSecondary.opacity(0.25), lineWidth: 2)
                Circle()
                    .fill(Theme.cardBackground)
                    .padding(8)

                // Rotating dial: N/E/S/W and tick marks. Rotates by the
                // *negative* heading so North stays anchored to true north
                // even as the device turns.
                CompassDial()
                    .rotationEffect(.degrees(-vm.headingDegrees))
                    .animation(.easeOut(duration: 0.15), value: vm.headingDegrees)

                // Qibla arrow lives on the same rotating coordinate system as
                // the dial — placed at qiblaBearing on the dial, and the dial
                // rotates by -heading. Net rotation = qiblaBearing - heading,
                // which is the on-screen angle the user must face.
                QiblaArrow(isAligned: isAlignedWithQibla)
                    .rotationEffect(.degrees(vm.qiblaBearing - vm.headingDegrees))
                    .animation(.easeOut(duration: 0.15), value: vm.qiblaBearing - vm.headingDegrees)

                // Centre badge
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 58, height: 58)
                Image(systemName: "location.north.line.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(Theme.accent)
                    .rotationEffect(.degrees(-vm.headingDegrees))

                // Top-of-screen reference triangle
                VStack {
                    Triangle()
                        .fill(Theme.accent)
                        .frame(width: 14, height: 14)
                        .offset(y: 4)
                    Spacer()
                }
            }
            .frame(maxWidth: 320)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 12)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "scope")
                        .foregroundColor(Theme.accent)
                    Text("Qibla:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(formatBearing(vm.qiblaBearing))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(Theme.textSecondary)
                    Text("(\(cardinal(for: vm.qiblaBearing)))")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                }
                HStack(spacing: 8) {
                    Image(systemName: "location.north.fill")
                        .foregroundColor(Theme.textSecondary)
                    Text("Blickrichtung:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(formatBearing(vm.headingDegrees))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(Theme.textSecondary)
                }
                if vm.needsCalibration {
                    Label("Kompass kalibrieren — Telefon in einer Acht bewegen.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
                if !vm.hasLocation {
                    Label("Standort wird ermittelt…", systemImage: "location")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.cardBackground)
        )
    }

    // MARK: - Seferi card

    private var seferSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Bin ich Seferi?")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            } icon: {
                Image(systemName: "figure.walk.motion")
                    .foregroundColor(Theme.accent)
            }

            Text("Klassisch (Hanafi): Mehr als ~90 km Luftlinie von der Heimatstadt = Seferi.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if appState.homeCity == nil {
                HStack(spacing: 8) {
                    Image(systemName: "house.slash")
                        .foregroundColor(.orange)
                    Text("Lege zuerst eine Heimatstadt in den Einstellungen fest.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let km = vm.distanceToHomeKm {
                seferStatusView(km: km)
            } else {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Distanz wird berechnet…")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.cardBackground)
        )
    }

    @ViewBuilder
    private func seferStatusView(km: Double) -> some View {
        let homeName = appState.homeCity?.name ?? "Heimatstadt"
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(formatKm(km))
                    .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Theme.textPrimary)
                Text("Luftlinie")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }

            Text("Entfernung zu \(homeName)")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            // Progress bar to the 90 km threshold (caps at 100% visually past it)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.background)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(vm.isSeferi ? Color.orange : Theme.accent)
                        .frame(width: geo.size.width * progressFraction(km: km), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                if vm.isSeferi {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Du bist Seferi.")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.orange)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Theme.accent)
                        Text("Du bist nicht Seferi.")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(Theme.accent)
                    }
                }
                Spacer()
                Text("Schwelle: 90 km")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.cardBackground)
        )
    }

    // MARK: - Formatting helpers

    private func formatBearing(_ deg: Double) -> String {
        String(format: "%.0f°", deg)
    }

    private func formatKm(_ km: Double) -> String {
        if km < 10 { return String(format: "%.2f km", km) }
        if km < 100 { return String(format: "%.1f km", km) }
        return String(format: "%.0f km", km)
    }

    private func progressFraction(km: Double) -> Double {
        let cap = QiblaCompassViewModel.seferThresholdKm
        return max(0, min(km / cap, 1))
    }

    private func cardinal(for deg: Double) -> String {
        let dirs = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
        let idx = Int((deg / 45.0).rounded()) % 8
        return dirs[(idx + 8) % 8]
    }

    private var isAlignedWithQibla: Bool {
        let diff = abs(((vm.qiblaBearing - vm.headingDegrees + 540).truncatingRemainder(dividingBy: 360)) - 180)
        return diff < 5  // within ±5° of perfect alignment
    }
}

// MARK: - Compass Dial

private struct CompassDial: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            ZStack {
                // Major + minor tick marks every 6°
                ForEach(0..<60) { i in
                    let isMajor = i % 5 == 0
                    Rectangle()
                        .fill(isMajor ? Theme.textPrimary.opacity(0.85) : Theme.textSecondary.opacity(0.35))
                        .frame(width: isMajor ? 2 : 1, height: isMajor ? 12 : 6)
                        .offset(y: -radius + (isMajor ? 16 : 12))
                        .rotationEffect(.degrees(Double(i) * 6))
                }
                // Cardinal labels
                cardinalLabel("N", angle: 0,   color: .red)
                cardinalLabel("O", angle: 90,  color: Theme.textPrimary)
                cardinalLabel("S", angle: 180, color: Theme.textPrimary)
                cardinalLabel("W", angle: 270, color: Theme.textPrimary)
                // Numeric markers every 30°
                ForEach([30, 60, 120, 150, 210, 240, 300, 330], id: \.self) { deg in
                    Text("\(deg)")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                        .offset(y: -radius + 36)
                        .rotationEffect(.degrees(Double(deg)))
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func cardinalLabel(_ s: String, angle: Double, color: Color) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            Text(s)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .offset(y: -radius + 32)
                .rotationEffect(.degrees(angle))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

// MARK: - Qibla Arrow

private struct QiblaArrow: View {
    let isAligned: Bool
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Capsule()
                    .fill(isAligned ? Color.green : Theme.accent)
                    .frame(width: 6, height: size * 0.78)
                ArrowHead()
                    .fill(isAligned ? Color.green : Theme.accent)
                    .frame(width: 22, height: 22)
                    .offset(y: -size * 0.78 / 2 - 8)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -size * 0.78 / 2 + 4)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

private struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    QiblaCompassView()
        .environmentObject(AppState())
}
