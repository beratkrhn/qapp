// DeenApp/Services/HifzAudioService.swift
//
// Fetches Surah data (Arabic text + word timestamps) from Quran.com API v4
// and drives AVFoundation playback with per-word time-sync notifications.

import Foundation
import AVFoundation
import Combine

// MARK: - API Response Models (Codable, private to this file)

private struct V4SurahResponse: Codable {
    let verses: [V4Verse]
}

private struct V4Verse: Codable {
    let id: Int
    let verse_key: String
    let words: [V4Word]
    let audio: V4Audio?
}

private struct V4Word: Codable {
    let id: Int
    let text_uthmani: String
    let audio: V4WordAudio?
    let char_type_name: String   // "word" | "end"
}

private struct V4WordAudio: Codable {
    let url: String?
    let duration: Double?
    let timestamp_from: Int?     // milliseconds
    let timestamp_to: Int?       // milliseconds
}

private struct V4Audio: Codable {
    let url: String
}

// MARK: - Service

@MainActor
final class HifzAudioService: NSObject, ObservableObject {

    // MARK: - Published

    @Published private(set) var activeWordID: UUID?
    @Published private(set) var playbackFinished: Bool = false

    // MARK: - AVFoundation

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentWords: [HifzWord] = []

    // MARK: - Config

    /// Quran.com reciter ID — Mishari Rashid al-'Afasy (default).
    private let reciterID: Int = 7

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 120
        return URLSession(configuration: cfg)
    }()

    // MARK: - Public API

    /// Fetch all verses for a Surah, including word-level timestamps.
    func fetchAyat(surahNumber: Int) async throws -> [AyahData] {
        // Quran.com v4: fields=words,audio; word_fields=audio
        var components = URLComponents(string: "https://api.quran.com/api/v4/verses/by_chapter/\(surahNumber)")!
        components.queryItems = [
            URLQueryItem(name: "language",         value: "ar"),
            URLQueryItem(name: "words",            value: "true"),
            URLQueryItem(name: "audio",            value: "\(reciterID)"),
            URLQueryItem(name: "word_fields",      value: "audio"),
            URLQueryItem(name: "fields",           value: "text_uthmani"),
            URLQueryItem(name: "per_page",         value: "300"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HifzAudioError.badResponse
        }

        let decoded = try JSONDecoder().decode(V4SurahResponse.self, from: data)
        return decoded.verses.compactMap { self.mapVerse($0, surahNumber: surahNumber) }
    }

    /// Begin playback of a single Ayah, firing word-highlight updates.
    func play(ayah: AyahData) {
        stopAndClearObserver()
        playbackFinished  = false
        currentWords      = ayah.words
        activeWordID      = nil

        guard let asset = AVURLAsset(url: ayah.audioURL) as AVURLAsset? else { return }
        let item   = AVPlayerItem(asset: asset)
        player     = AVPlayer(playerItem: item)

        // Register for playback-did-end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        // Periodic observer every 50 ms for word highlighting
        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.updateActiveWord(at: time.seconds)
        }

        configureAudioSession()
        player?.play()
    }

    /// Stop playback and release resources.
    func stop() {
        stopAndClearObserver()
        activeWordID     = nil
        playbackFinished = false
    }

    // MARK: - Private

    private func updateActiveWord(at seconds: Double) {
        let match = currentWords.first {
            seconds >= $0.startTime && seconds < $0.endTime
        }
        if activeWordID != match?.id {
            activeWordID = match?.id
        }
    }

    @objc private func playerDidFinish() {
        stopAndClearObserver()
        playbackFinished = true
    }

    private func stopAndClearObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self,
            name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Mapping

    private func mapVerse(_ verse: V4Verse, surahNumber: Int) -> AyahData? {
        guard let audioPath = verse.audio?.url else { return nil }

        // Resolve relative paths returned by the API
        let audioURLString = audioPath.hasPrefix("http")
            ? audioPath
            : "https://verses.quran.com/\(audioPath)"
        guard let audioURL = URL(string: audioURLString) else { return nil }

        // Build HifzWord array from API words (skip punctuation / end markers)
        let hifzWords: [HifzWord] = verse.words
            .filter { $0.char_type_name == "word" }
            .map { w in
                let start = Double(w.audio?.timestamp_from ?? 0) / 1000.0
                let end   = Double(w.audio?.timestamp_to   ?? 0) / 1000.0
                return HifzWord(text: w.text_uthmani, startTime: start, endTime: end)
            }

        let parts = verse.verse_key.split(separator: ":")
        let ayahNumber = parts.count == 2 ? Int(parts[1]) ?? verse.id : verse.id
        let arabicText = hifzWords.map(\.text).joined(separator: " ")

        return AyahData(
            id:           verse.id,
            verseKey:     verse.verse_key,
            surahNumber:  surahNumber,
            ayahNumber:   ayahNumber,
            arabicText:   arabicText,
            words:        hifzWords,
            audioURL:     audioURL
        )
    }
}

// MARK: - Errors

enum HifzAudioError: LocalizedError {
    case badResponse
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .badResponse: return "Could not load Surah data. Please try again."
        case .invalidURL:  return "Invalid audio URL received from server."
        }
    }
}
