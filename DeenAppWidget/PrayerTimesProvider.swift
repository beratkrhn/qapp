//
//  PrayerTimesProvider.swift
//  DailyDeen Widget
//
//  Reads cached SharedPrayerData written by the main app (DITIB / Aladhan).
//  Falls back to a lightweight Aladhan API call using the user's saved city.
//

import WidgetKit
import Foundation

struct PrayerTimesProvider: TimelineProvider {

    // MARK: - Protocol

    func placeholder(in context: Context) -> PrayerTimesEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        completion(entryFromCache() ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )

        if let cached = entryFromCache() {
            completion(Timeline(entries: timelineEntries(from: cached), policy: .after(midnight)))
        } else {
            fetchFromAPI { entry in
                completion(Timeline(entries: self.timelineEntries(from: entry), policy: .after(midnight)))
            }
        }
    }

    // MARK: - Cache

    private func entryFromCache() -> PrayerTimesEntry? {
        guard let data = SharedPrayerData.load(), data.isToday else { return nil }
        return makeEntry(from: data, at: .now)
    }

    // MARK: - API Fallback (uses the user's saved coordinates + method)

    private func fetchFromAPI(completion: @escaping (PrayerTimesEntry) -> Void) {
        let cached  = SharedPrayerData.load()
        let loc     = SharedPrayerData.loadLocation()
        let city    = SharedPrayerData.loadCity() ?? cached?.cityName ?? "Berlin"
        let lat     = loc?.lat    ?? cached?.latitude  ?? 52.52
        let lon     = loc?.lon    ?? cached?.longitude ?? 13.405
        let method  = loc?.method ?? cached?.methodId  ?? 13

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "dd-MM-yyyy"
        let dateStr = dateFmt.string(from: .now)

        // Prefer coordinate-based lookup (exact method, city-agnostic)
        guard let url = URL(string: "https://api.aladhan.com/v1/timings/\(dateStr)?latitude=\(lat)&longitude=\(lon)&method=\(method)") else {
            completion(.placeholder)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data, error == nil,
                  let response = try? JSONDecoder().decode(WidgetAladhanResponse.self, from: data),
                  response.code == 200
            else {
                completion(.placeholder)
                return
            }

            let t = response.data.timings
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let shared = SharedPrayerData(
                fajr: t.Fajr, sunrise: t.Sunrise,
                dhuhr: t.Dhuhr, asr: t.Asr,
                maghrib: t.Maghrib, isha: t.Isha,
                dateString: fmt.string(from: .now),
                timezone: response.data.meta?.timezone ?? "Europe/Berlin",
                cityName: city,
                latitude: lat, longitude: lon,
                methodId: method
            )
            SharedPrayerData.save(shared)
            completion(self.makeEntry(from: shared, at: .now))
        }.resume()
    }

    // MARK: - Entry Building

    private func makeEntry(from data: SharedPrayerData, at date: Date) -> PrayerTimesEntry {
        let nextIndex = data.nextSlotIndex()
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "d MMMM"

        let slots = data.allSlots.enumerated().map { i, s in
            PrayerSlot(id: i, label: s.label, time: s.time, icon: s.icon, isNext: i == nextIndex)
        }

        let nextPrayerDate: Date? = nextIndex.flatMap {
            data.dateFrom(timeString: data.allSlots[$0].time)
        }

        // Always prefer the standalone city key (updated instantly by the main app)
        let resolvedCity = SharedPrayerData.loadCity() ?? data.cityName

        return PrayerTimesEntry(
            date: date,
            slots: slots,
            dayLabel: dayFmt.string(from: .now),
            cityName: resolvedCity,
            isPlaceholder: false,
            nextPrayerDate: nextPrayerDate
        )
    }

    /// One entry per remaining prayer so the "next" indicator auto-advances.
    private func timelineEntries(from base: PrayerTimesEntry) -> [PrayerTimesEntry] {
        guard let data = SharedPrayerData.load() else { return [base] }
        var entries = [base]

        for slot in data.allSlots {
            if let prayerDate = data.dateFrom(timeString: slot.time), prayerDate > .now {
                entries.append(makeEntry(from: data, at: prayerDate))
            }
        }
        return entries
    }
}

// MARK: - Minimal Codable models (widget-only, no main app dependency)

private struct WidgetAladhanResponse: Decodable {
    let code: Int
    let data: WidgetAladhanData
}

private struct WidgetAladhanData: Decodable {
    let timings: WidgetTimings
    let meta: WidgetMeta?
}

private struct WidgetTimings: Decodable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

private struct WidgetMeta: Decodable {
    let timezone: String?
}
