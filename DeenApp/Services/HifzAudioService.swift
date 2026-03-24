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
    let text_uthmani: String?
    let text: String?
    let audio: V4WordAudio?
    let char_type_name: String?
}

private struct V4WordAudio: Codable {
    let url: String?
    let duration: Double?
    let timestamp_from: Int?
    let timestamp_to: Int?
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
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var playbackProgress: Double = 0
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var audioDuration: Double = 0

    // MARK: - AVFoundation

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentWords: [HifzWord] = []

    // MARK: - Config

    private let reciterID: Int = 7

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 120
        return URLSession(configuration: cfg)
    }()

    // MARK: - Public API

    func fetchAyat(surahNumber: Int) async throws -> [AyahData] {
        var components = URLComponents(string: "https://api.quran.com/api/v4/verses/by_chapter/\(surahNumber)")!
        components.queryItems = [
            URLQueryItem(name: "language",         value: "ar"),
            URLQueryItem(name: "words",            value: "true"),
            URLQueryItem(name: "audio",            value: "\(reciterID)"),
            URLQueryItem(name: "word_fields",      value: "text_uthmani,audio"),
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

    func play(ayah: AyahData) {
        stopAndClearObserver()
        playbackFinished = false
        currentWords     = ayah.words
        activeWordID     = nil
        isPaused         = false
        playbackProgress = 0
        currentTime      = 0

        let asset = AVURLAsset(url: ayah.audioURL)
        let item  = AVPlayerItem(asset: asset)
        player    = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let secs = time.seconds
            self.updateActiveWord(at: secs)
            self.currentTime = secs
            if let dur = self.player?.currentItem?.duration.seconds, dur.isFinite, dur > 0 {
                self.audioDuration = dur
                self.playbackProgress = secs / dur
            }
        }

        configureAudioSession()
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
        isPaused  = true
    }

    func resume() {
        guard isPaused, player != nil else { return }
        player?.play()
        isPlaying = true
        isPaused  = false
    }

    func stop() {
        stopAndClearObserver()
        activeWordID     = nil
        playbackFinished = false
        isPlaying        = false
        isPaused         = false
        playbackProgress = 0
        currentTime      = 0
        audioDuration    = 0
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
        isPlaying        = false
        isPaused         = false
        playbackProgress = 1.0

        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self,
            name: .AVPlayerItemDidPlayToEndTime, object: nil)

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

        let audioURLString = audioPath.hasPrefix("http")
            ? audioPath
            : "https://verses.quran.com/\(audioPath)"
        guard let audioURL = URL(string: audioURLString) else { return nil }

        let hifzWords: [HifzWord] = verse.words
            .filter { ($0.char_type_name ?? "word") == "word" }
            .compactMap { w -> HifzWord? in
                let arabic = w.text_uthmani ?? w.text ?? ""
                guard !arabic.isEmpty else { return nil }
                let start = Double(w.audio?.timestamp_from ?? 0) / 1000.0
                let end   = Double(w.audio?.timestamp_to   ?? 0) / 1000.0
                return HifzWord(text: arabic, startTime: start, endTime: end)
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
