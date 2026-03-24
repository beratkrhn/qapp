// DeenApp/ViewModels/HifzViewModel.swift
//
// State driver for the Hifz (memorisation) reader using the 3×3 Method.
//
// Phase 1 — Listen & Repeat:  Play the current Ayah 3 times.
// Phase 2 — Connect:          Play Ayahs 1…N together, 3 times.
// Then advance to the next Ayah and repeat.
//
// Also manages global text-visibility (eye toggle), manual loop override,
// play/pause audio control, and SwiftData persistence.

import Foundation
import Combine
import SwiftData

@MainActor
final class HifzViewModel: ObservableObject {

    // MARK: - 3×3 Phase

    enum MemorizationPhase: Equatable {
        case listenAndRepeat
        case connect
    }

    // MARK: - Published State

    @Published private(set) var allAyat: [AyahData] = []
    @Published private(set) var currentAyahIndex: Int = 0
    @Published private(set) var playingAyahIndex: Int = 0
    @Published private(set) var surahNumber: Int = 0
    @Published private(set) var surahName: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    @Published private(set) var activeWordID: UUID?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackProgress: Double = 0

    @Published private(set) var currentPhase: MemorizationPhase = .listenAndRepeat
    @Published private(set) var phaseRepeatCount: Int = 0

    @Published var isTextHidden: Bool = false
    @Published var isLooping: Bool = false

    // MARK: - Computed

    var totalAyahCount: Int { allAyat.count }
    var isInSession: Bool { !allAyat.isEmpty }

    var currentAyah: AyahData? {
        allAyat.indices.contains(currentAyahIndex) ? allAyat[currentAyahIndex] : nil
    }

    var canGoNext: Bool { currentAyahIndex < allAyat.count - 1 }
    var canGoPrevious: Bool { currentAyahIndex > 0 }

    var phaseDisplayLabel: String {
        switch currentPhase {
        case .listenAndRepeat: return "Listen & Repeat"
        case .connect:         return "Connect"
        }
    }

    var phaseDisplayIcon: String {
        switch currentPhase {
        case .listenAndRepeat: return "ear.fill"
        case .connect:         return "link"
        }
    }

    /// Human-readable "Ayah 1 → 3" range label for the Connect phase.
    var connectRangeLabel: String? {
        guard currentPhase == .connect else { return nil }
        return "Ayah 1 → \(currentAyahIndex + 1)"
    }

    // MARK: - Dependencies

    private let audioService: HifzAudioService
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private let chunkSize = 3
    private let maxRepeats = 3

    // MARK: - Connection Queue (Phase 2)

    private var connectionQueue: [Int] = []
    private var connectionPlaybackIndex: Int = 0

    // MARK: - Init

    init(audioService: HifzAudioService, modelContext: ModelContext) {
        self.audioService = audioService
        self.modelContext  = modelContext
        bindAudioService()
    }

    // MARK: - Audio Binding

    private func bindAudioService() {
        audioService.$activeWordID
            .receive(on: RunLoop.main)
            .assign(to: &$activeWordID)

        audioService.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)

        audioService.$playbackProgress
            .receive(on: RunLoop.main)
            .assign(to: &$playbackProgress)

        audioService.$playbackFinished
            .receive(on: RunLoop.main)
            .sink { [weak self] finished in
                guard let self, finished else { return }
                self.handlePlaybackFinished()
            }
            .store(in: &cancellables)
    }

    // MARK: - Session Lifecycle

    func startSession(surahNumber: Int, surahName: String) {
        self.surahNumber = surahNumber
        self.surahName   = surahName
        isLoading    = true
        errorMessage = nil

        Task {
            do {
                let ayat = try await audioService.fetchAyat(surahNumber: surahNumber)
                guard !ayat.isEmpty else {
                    isLoading    = false
                    errorMessage = "No verses found for this Surah."
                    return
                }
                allAyat          = ayat
                currentAyahIndex = 0
                isLoading        = false
                beginListenAndRepeat()
            } catch {
                isLoading    = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func endSession() {
        persistProgress()
        audioService.stop()
        allAyat               = []
        currentAyahIndex      = 0
        playingAyahIndex      = 0
        surahNumber           = 0
        surahName             = ""
        currentPhase          = .listenAndRepeat
        phaseRepeatCount      = 0
        connectionQueue       = []
        connectionPlaybackIndex = 0
        isTextHidden          = false
        isLooping             = false
        errorMessage          = nil
    }

    // MARK: - 3×3 Phase Control

    private func beginListenAndRepeat() {
        currentPhase     = .listenAndRepeat
        phaseRepeatCount = 0
        playAyahAt(currentAyahIndex)
    }

    private func beginConnectPhase() {
        currentPhase          = .connect
        phaseRepeatCount      = 0
        connectionQueue       = Array(0...currentAyahIndex)
        connectionPlaybackIndex = 0
        playAyahAt(connectionQueue[0])
    }

    private func advanceToNextAyah() {
        if canGoNext {
            currentAyahIndex += 1
            beginListenAndRepeat()
        }
    }

    // MARK: - Playback Events (3×3 State Machine)

    private func handlePlaybackFinished() {
        if isLooping {
            playAyahAt(playingAyahIndex)
            return
        }

        switch currentPhase {

        case .listenAndRepeat:
            if phaseRepeatCount < maxRepeats - 1 {
                phaseRepeatCount += 1
                playAyahAt(currentAyahIndex)
            } else {
                if currentAyahIndex == 0 {
                    advanceToNextAyah()
                } else {
                    beginConnectPhase()
                }
            }

        case .connect:
            if connectionPlaybackIndex < connectionQueue.count - 1 {
                connectionPlaybackIndex += 1
                playAyahAt(connectionQueue[connectionPlaybackIndex])
            } else if phaseRepeatCount < maxRepeats - 1 {
                phaseRepeatCount += 1
                connectionPlaybackIndex = 0
                playAyahAt(connectionQueue[0])
            } else {
                advanceToNextAyah()
            }
        }
    }

    // MARK: - Navigation (manual — resets 3×3 for target Ayah)

    func goToNextAyah() {
        guard canGoNext else { return }
        audioService.stop()
        currentAyahIndex += 1
        beginListenAndRepeat()
    }

    func goToPreviousAyah() {
        guard canGoPrevious else { return }
        audioService.stop()
        currentAyahIndex -= 1
        beginListenAndRepeat()
    }

    func jumpToAyah(at index: Int) {
        guard allAyat.indices.contains(index) else { return }
        audioService.stop()
        currentAyahIndex = index
        beginListenAndRepeat()
    }

    // MARK: - Audio Control

    func togglePlayPause() {
        if isPlaying {
            audioService.pause()
        } else if audioService.isPaused {
            audioService.resume()
        } else {
            playAyahAt(playingAyahIndex)
        }
    }

    func playCurrentAyah() {
        playAyahAt(currentAyahIndex)
    }

    private func playAyahAt(_ index: Int) {
        guard allAyat.indices.contains(index) else { return }
        playingAyahIndex = index
        audioService.play(ayah: allAyat[index])
    }

    // MARK: - Toggles

    func toggleTextVisibility() {
        isTextHidden.toggle()
    }

    func toggleLoop() {
        isLooping.toggle()
    }

    // MARK: - Persistence

    private func persistProgress() {
        guard surahNumber > 0 else { return }
        let surahNum    = surahNumber
        let totalChunks = (allAyat.count + chunkSize - 1) / chunkSize
        let chunkIdx    = currentAyahIndex / chunkSize
        let ayatCount   = min(chunkSize, allAyat.count - chunkIdx * chunkSize)

        let sDescriptor = FetchDescriptor<SRSItem>(
            predicate: #Predicate {
                $0.surahNumber == surahNum &&
                $0.chunkIndex  == chunkIdx
            }
        )
        if let existing = try? modelContext.fetch(sDescriptor).first {
            existing.markReviewed()
        } else {
            modelContext.insert(SRSItem(surahNumber: surahNum, chunkIndex: chunkIdx))
        }

        let today = DailyActivity.normalise(.now)
        let aDescriptor = FetchDescriptor<DailyActivity>(
            predicate: #Predicate { $0.date == today }
        )
        if let activity = try? modelContext.fetch(aDescriptor).first {
            activity.loopsCompleted += 1
            activity.ayatMemorized  += ayatCount
        } else {
            modelContext.insert(DailyActivity(date: today,
                                              loopsCompleted: 1,
                                              ayatMemorized: ayatCount))
        }

        let pDescriptor = FetchDescriptor<HifzProgress>(
            predicate: #Predicate { $0.surahNumber == surahNum }
        )
        if let progress = try? modelContext.fetch(pDescriptor).first {
            progress.currentChunkIndex = chunkIdx
            progress.totalChunks       = totalChunks
        } else {
            let p = HifzProgress(surahNumber: surahNum, totalChunks: totalChunks)
            p.currentChunkIndex = chunkIdx
            modelContext.insert(p)
        }

        try? modelContext.save()
    }
}
