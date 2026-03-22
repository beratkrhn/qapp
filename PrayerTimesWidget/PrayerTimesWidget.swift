//
//  PrayerTimesWidget.swift
//  PrayerTimesWidget
//
//  Home-Screen-Widget: 5 tägliche Gebete, lesbar auf hellen/dunklen Hintergründen.
//  Target in Xcode anlegen (Widget Extension), diese Datei + Entitlements (App Group)
//  zum Widget-Target hinzufügen; dieselbe App Group wie in DeenApp.entitlements.
//

import WidgetKit
import SwiftUI

// MARK: - Mit DeenApp/Models/PrayerWidgetSnapshot.swift abgleichen

private enum WidgetAppGroup {
    static let identifier = "group.d.DailyDee"
    static let snapshotKey = "dailydee.widgetPrayerSnapshot_v1"
}

private struct PrayerSnapshot: Codable {
    struct Row: Codable, Identifiable {
        var id: String { kindRaw + time }
        let kindRaw: String
        let time: String
        let iconSystemName: String
        let title: String
    }
    let savedAt: TimeInterval
    let rows: [Row]
}

private enum WidgetSnapshotLoader {
    static func load() -> PrayerSnapshot? {
        guard let data = UserDefaults(suiteName: WidgetAppGroup.identifier)?.data(forKey: WidgetAppGroup.snapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PrayerSnapshot.self, from: data)
    }
}

// MARK: - Timeline

struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(date: Date(), rows: Self.demoRows)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let entry = entry(for: Date())
        let next = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func entry(for date: Date) -> PrayerTimesEntry {
        if let snap = WidgetSnapshotLoader.load(), !snap.rows.isEmpty {
            return PrayerTimesEntry(date: date, rows: snap.rows)
        }
        return PrayerTimesEntry(date: date, rows: Self.demoRows)
    }

    private static var demoRows: [PrayerSnapshot.Row] {
        [
            .init(kindRaw: "Fajr", time: "—", iconSystemName: "moon.haze.fill", title: "Sabah"),
            .init(kindRaw: "Dhuhr", time: "—", iconSystemName: "sun.max.fill", title: "Öğle"),
            .init(kindRaw: "Asr", time: "—", iconSystemName: "cloud.sun.fill", title: "İkindi"),
            .init(kindRaw: "Maghrib", time: "—", iconSystemName: "sunset.fill", title: "Akşam"),
            .init(kindRaw: "Isha", time: "—", iconSystemName: "moon.fill", title: "Yatsı")
        ]
    }
}

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let rows: [PrayerSnapshot.Row]
}

// MARK: - View (transparent + Material + Kontrast)

struct PrayerTimesWidgetEntryView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var entry: PrayerTimesProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.rows) { row in
                HStack(spacing: 8) {
                    Image(systemName: row.iconSystemName)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 22, alignment: .center)
                        .modifier(WidgetLegibleSymbolStyle())
                    Text(row.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .modifier(WidgetLegibleTextStyle())
                    Spacer(minLength: 4)
                    Text(row.time)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .modifier(WidgetLegibleTextStyle())
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Doppelte Schatten für lesbare Symbole auf beliebigem Wallpaper.
private struct WidgetLegibleSymbolStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .shadow(color: .black.opacity(0.55), radius: 0, x: 0.8, y: 0.8)
            .shadow(color: .white.opacity(0.45), radius: 0, x: -0.6, y: -0.6)
    }
}

private struct WidgetLegibleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .shadow(color: .black.opacity(0.45), radius: 0, x: 0.6, y: 0.6)
            .shadow(color: .white.opacity(0.35), radius: 0, x: -0.5, y: -0.5)
    }
}

// MARK: - Widget

struct PrayerTimesHomeWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Gebetszeiten")
        .description("Die fünf täglichen Gebete mit Uhrzeit.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct PrayerTimesWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesHomeWidget()
    }
}
