// DeenApp/ViewModels/HifzViewModel.swift
//
// State-machine driver for the 3×3 Memorisation Method.
// Coordinates the audio service, SRS persistence, and heatmap logging.

import Foundation
import Combine
import SwiftData

@MainActor
final class HifzViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var phase: HifzPhase = .idle
    @Published private(set) var currentChunk: HifzChunk?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var activeWordID: UUID?          // for word-by-word highlight
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let audioService: HifzAudioService
    private let modelContext: ModelContext

    // MARK: - Internal Bookkeeping

    /// The index (0-based) of the verse currently being worked on within the chunk.
    private var currentVerseIndex: Int = 0

    /// Tracks how many times the user has read/recalled the current verse.
    private var verseReadCount: Int = 0
    private var verseRecallCount: Int = 0

    /// How many times the full block has been recalled in State 4.
    private var blockRecallCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    private let requiredReads: Int    = 3
    private let requiredRecalls: Int  = 3
    private let chunkSize: Int        = 3

    // MARK: - Init

    init(audioService: HifzAudioService, modelContext: ModelContext) {
        self.audioService = audioService
        self.modelContext = modelContext
        bindAudioService()
    }

    // MARK: - Audio Binding

    private func bindAudioService() {
        audioService.$activeWordID
            .receive(on: RunLoop.main)
            .assign(to: &$activeWordID)

        audioService.$playbackFinished
            .receive(on: RunLoop.main)
            .sink { [weak self] finished in
                guard let self, finished else { return }
                self.handlePlaybackFinished()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Load a Surah and begin from the correct chunk (based on persisted progress).
    func startSession(surahNumber: Int) {
        phase     = .idle
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let ayat = try await audioService.fetchAyat(surahNumber: surahNumber)
                let chunks = buildChunks(surahNumber: surahNumber, ayat: ayat)

                // Upsert progress record
                let chunkIndex = resolvedChunkIndex(surahNumber: surahNumber,
                                                    totalChunks: chunks.count)
                guard chunkIndex < chunks.count else {
                    phase     = .complete
                    isLoading = false
                    return
                }

                currentChunk = chunks[chunkIndex]
                isLoading    = false
                beginVerseLoop(verseIndex: 0)
            } catch {
                isLoading    = false
                phase        = .error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: State 2a — Read & Listen

    /// Called by the UI "Play" button (or automatically on state entry).
    func playCurrentVerse() {
        guard case .readAndListen(let vi, _) = phase,
              let chunk = currentChunk,
              vi < chunk.ayat.count else { return }

        audioService.play(ayah: chunk.ayat[vi])
    }

    /// Called when the user taps "Done listening" or audio finishes.
    func confirmRead() {
        guard case .readAndListen(let vi, let count) = phase else { return }
        audioService.stop()

        let next = count + 1
        if next >= requiredReads {
            // Transition to active recall
            verseRecallCount = 0
            phase = .activeRecall(verseIndex: vi, recallCount: 0)
        } else {
            verseReadCount = next
            phase = .readAndListen(verseIndex: vi, readCount: next)
            playCurrentVerse()
        }
    }

    // MARK: State 2b — Active Recall

    /// Called when the user taps "I recalled it correctly".
    func confirmRecall() {
        guard case .activeRecall(let vi, let count) = phase else { return }

        let next = count + 1
        if next >= requiredRecalls {
            advanceToNextVerse(after: vi)
        } else {
            verseRecallCount = next
            phase = .activeRecall(verseIndex: vi, recallCount: next)
        }
    }

    /// Called when the user taps "I made a mistake".
    func reportMistake() {
        guard case .activeRecall(let vi, _) = phase else { return }
        // Reset this verse's counters entirely — back to State 2a, read 0
        verseReadCount   = 0
        verseRecallCount = 0
        phase = .readAndListen(verseIndex: vi, readCount: 0)
        playCurrentVerse()
    }

    // MARK: State 3 — Concatenation

    /// User acknowledges the full concatenated block; advance to State 4.
    func confirmConcatenation() {
        guard case .concatenation = phase else { return }
        blockRecallCount = 0
        phase = .commitToMemory(recallCount: 0)
    }

    // MARK: State 4 — Commit to Memory

    /// Called when user successfully recalls the whole block.
    func confirmBlockRecall() {
        guard case .commitToMemory(let count) = phase else { return }

        let next = count + 1
        if next >= requiredRecalls {
            phase = .saving
            persistCompletion()
        } else {
            blockRecallCount = next
            phase = .commitToMemory(recallCount: next)
        }
    }

    /// Called when user mistakes on full-block recall — restart from State 4 recall 0.
    func reportBlockMistake() {
        guard case .commitToMemory(_) = phase else { return }
        blockRecallCount = 0
        phase = .commitToMemory(recallCount: 0)
    }

    // MARK: - Private Helpers

    private func beginVerseLoop(verseIndex: Int) {
        verseReadCount   = 0
        verseRecallCount = 0
        currentVerseIndex = verseIndex
        phase = .readAndListen(verseIndex: verseIndex, readCount: 0)
        playCurrentVerse()
    }

    private func advanceToNextVerse(after vi: Int) {
        guard let chunk = currentChunk else { return }

        let nextIndex = vi + 1
        if nextIndex < chunk.ayat.count {
            beginVerseLoop(verseIndex: nextIndex)
        } else {
            // All verses done → concatenation phase
            phase = .concatenation
        }
    }

    private func handlePlaybackFinished() {
        // Auto-advance read count when audio ends
        guard case .readAndListen = phase else { return }
        confirmRead()
    }

    // MARK: - Chunking

    private func buildChunks(surahNumber: Int, ayat: [AyahData]) -> [HifzChunk] {
        stride(from: 0, to: ayat.count, by: chunkSize).enumerated().map { idx, start in
            let slice = Array(ayat[start..<min(start + chunkSize, ayat.count)])
            return HifzChunk(surahNumber: surahNumber, chunkIndex: idx, ayat: slice)
        }
    }

    // MARK: - Persistence

    private func resolvedChunkIndex(surahNumber: Int, totalChunks: Int) -> Int {
        let descriptor = FetchDescriptor<HifzProgress>(
            predicate: #Predicate { $0.surahNumber == surahNumber }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.totalChunks = totalChunks
            return existing.currentChunkIndex
        }
        let progress = HifzProgress(surahNumber: surahNumber, totalChunks: totalChunks)
        modelContext.insert(progress)
        return 0
    }

    private func persistCompletion() {
        guard let chunk = currentChunk else {
            phase = .complete
            return
        }

        // 1. Save / update SRSItem
        let sDescriptor = FetchDescriptor<SRSItem>(
            predicate: #Predicate {
                $0.surahNumber == chunk.surahNumber &&
                $0.chunkIndex  == chunk.chunkIndex
            }
        )
        if let existing = try? modelContext.fetch(sDescriptor).first {
            existing.markReviewed()
        } else {
            modelContext.insert(SRSItem(surahNumber: chunk.surahNumber,
                                        chunkIndex: chunk.chunkIndex))
        }

        // 2. Upsert DailyActivity for today
        let today = DailyActivity.normalise(.now)
        let aDescriptor = FetchDescriptor<DailyActivity>(
            predicate: #Predicate { $0.date == today }
        )
        if let activity = try? modelContext.fetch(aDescriptor).first {
            activity.loopsCompleted += 1
            activity.ayatMemorized  += chunk.ayat.count
        } else {
            modelContext.insert(DailyActivity(date: today,
                                              loopsCompleted: 1,
                                              ayatMemorized: chunk.ayat.count))
        }

        // 3. Advance HifzProgress
        let pDescriptor = FetchDescriptor<HifzProgress>(
            predicate: #Predicate { $0.surahNumber == chunk.surahNumber }
        )
        try? modelContext.fetch(pDescriptor).first?.advanceChunk()

        // 4. Commit
        try? modelContext.save()

        phase = .complete
    }
}
