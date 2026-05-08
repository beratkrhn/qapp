//
//  MushafPDFViewer.swift
//  DeenApp
//
//  PDF-Mushaf viewer. Backed by either a bundled PDF (Diyanet, Quran-Schrift 2)
//  or by per-page JPEGs (pc2-web). The active source comes from
//  `AppState.quranPDFSource` and is selected in the Quran settings sheet.
//  Page mapping: pdfIndex = mushafPage
//  (pdfIndex 0 = cover/skip, pdfIndex 1 = Al-Fatiha = mushafPage 1 = PDF page 2)
//  Swipe right = next page (RTL Quran direction).
//

import SwiftUI
import PDFKit

// MARK: - Navigation pop-gesture helpers

/// Walks the full UIViewController tree to find the first UINavigationController.
private func findNavController(_ vc: UIViewController?) -> UINavigationController? {
    if let nc = vc as? UINavigationController { return nc }
    for child in (vc?.children ?? []) {
        if let found = findNavController(child) { return found }
    }
    if let presented = vc?.presentedViewController {
        return findNavController(presented)
    }
    return nil
}

private func setPopGestureEnabled(_ enabled: Bool) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }) else { return }
    findNavController(window.rootViewController)?.interactivePopGestureRecognizer?.isEnabled = enabled
}

// MARK: - PDFKit UIViewRepresentable

struct PDFKitRepresentableView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var targetPageIndex: Int
    let onPageChanged: (Int) -> Void
    let onResetZoom: (@escaping () -> Void) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChanged: onPageChanged)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        context.coordinator.pdfView = pdfView
        // Track initial index so updateUIView doesn't re-navigate on first render
        context.coordinator.trackedIndex = targetPageIndex

        // Expose reset-zoom action to SwiftUI layer
        onResetZoom {
            pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        }

        // RTL swipe gestures: swipe right = next page, swipe left = previous page
        // (No PDFViewPageChanged observer — swipe handlers notify directly to avoid
        //  "Modifying state during view update" feedback loop through updateUIView.)
        let swipeRight = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipeRight)
        )
        swipeRight.direction = .right
        pdfView.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipeLeft)
        )
        swipeLeft.direction = .left
        pdfView.addGestureRecognizer(swipeLeft)

        // Navigate to the initial page once the view is laid out
        let target = targetPageIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak pdfView] in
            guard let pdfView, let page = pdfView.document?.page(at: target) else { return }
            pdfView.go(to: page)
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only navigate when SwiftUI requests a new page (e.g. slider or surah tap).
        // Guard on trackedIndex (not the PDF's current page) to avoid re-entering
        // when the coordinator itself already navigated via a swipe.
        guard context.coordinator.trackedIndex != targetPageIndex,
              let targetPage = pdfView.document?.page(at: targetPageIndex) else { return }
        context.coordinator.trackedIndex = targetPageIndex
        UIView.transition(with: pdfView, duration: 0.22, options: .transitionCrossDissolve) {
            pdfView.go(to: targetPage)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        let onPageChanged: (Int) -> Void
        weak var pdfView: PDFView?
        /// Tracks the last index this coordinator navigated to, preventing updateUIView
        /// from re-navigating after a swipe-driven page change.
        var trackedIndex: Int = -1

        init(onPageChanged: @escaping (Int) -> Void) {
            self.onPageChanged = onPageChanged
        }

        @objc func handleSwipeRight() {
            guard let pdfView else { return }
            guard let doc = pdfView.document,
                  let current = pdfView.currentPage else { return }
            let currentIndex = doc.index(for: current)
            let nextIndex = currentIndex + 1
            guard nextIndex < doc.pageCount,
                  let nextPage = doc.page(at: nextIndex) else { return }
            trackedIndex = nextIndex
            UIView.transition(with: pdfView, duration: 0.22, options: .transitionCrossDissolve) {
                pdfView.go(to: nextPage)
            }
            // Notify SwiftUI outside the current render pass
            Task { @MainActor [weak self] in self?.onPageChanged(nextIndex) }
        }

        @objc func handleSwipeLeft() {
            guard let pdfView else { return }
            guard let doc = pdfView.document,
                  let current = pdfView.currentPage else { return }
            let currentIndex = doc.index(for: current)
            let prevIndex = currentIndex - 1
            guard prevIndex >= 0,
                  let prevPage = doc.page(at: prevIndex) else { return }
            trackedIndex = prevIndex
            UIView.transition(with: pdfView, duration: 0.22, options: .transitionCrossDissolve) {
                pdfView.go(to: prevPage)
            }
            // Notify SwiftUI outside the current render pass
            Task { @MainActor [weak self] in self?.onPageChanged(prevIndex) }
        }
    }
}

// MARK: - Mushaf PDF Page View (container — switches between PDF and image viewer)

struct MushafPDFPageView: View {
    let suraList: [QuranSuraInfo]
    let language: AppLanguage
    let pdfSource: QuranPDFSource
    /// Two-way binding so the parent can sync mode transitions (mushaf page, 1-indexed)
    @Binding var currentMushafPage: Int

    var body: some View {
        switch pdfSource {
        case .pc2web:
            MushafImagePageView(
                suraList: suraList,
                language: language,
                currentMushafPage: $currentMushafPage
            )
        case .diyanet, .kuranschrift2:
            MushafFilePDFView(
                suraList: suraList,
                language: language,
                currentMushafPage: $currentMushafPage,
                resourceName: pdfSource.pdfResourceName ?? "kuranpdfdiyanet",
                bottomLabel: pdfSource.bottomBarLabel
            )
            // Force a fresh PDFKit instance whenever the user switches PDFs;
            // PDFView holds onto its document and won't pick up the new file
            // through updateUIView alone.
            .id(pdfSource.rawValue)
        }
    }
}

// MARK: - File-based PDF viewer (parametric — used for Diyanet & Kuran-Schrift 2)

private struct MushafFilePDFView: View {
    let suraList: [QuranSuraInfo]
    let language: AppLanguage
    @Binding var currentMushafPage: Int
    /// Bundle resource name (without `.pdf`) of the PDF to render.
    let resourceName: String
    /// Subtitle shown in the bottom bar alongside the surah name.
    let bottomLabel: String

    @State private var pdfDocument: PDFDocument?
    @State private var targetIndex: Int
    @State private var sliderValue: Double
    @State private var isLoading = true
    @State private var resetZoomAction: (() -> Void)? = nil

    private static let quranPageCount = 604

    init(suraList: [QuranSuraInfo],
         language: AppLanguage,
         currentMushafPage: Binding<Int>,
         resourceName: String,
         bottomLabel: String) {
        self.suraList = suraList
        self.language = language
        self._currentMushafPage = currentMushafPage
        self.resourceName = resourceName
        self.bottomLabel = bottomLabel
        let mushafPage = max(1, min(currentMushafPage.wrappedValue, Self.quranPageCount))
        self._targetIndex = State(initialValue: mushafPage)
        self._sliderValue = State(initialValue: Double(mushafPage))
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if let doc = pdfDocument {
                ZStack {
                    PDFKitRepresentableView(
                        document: doc,
                        targetPageIndex: $targetIndex,
                        onPageChanged: handlePageChange,
                        onResetZoom: { action in resetZoomAction = action }
                    )
                    .ignoresSafeArea(edges: .horizontal)

                    // Left arrow = next page (RTL: n+1)
                    HStack {
                        Button(action: flipToNextPage) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Theme.textPrimary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Theme.cardBackground.opacity(0.92))
                                        .shadow(color: Theme.shadowColor, radius: 4, y: 2)
                                )
                        }
                        .padding(.leading, 14)
                        .disabled(targetIndex >= Self.quranPageCount)

                        Spacer()

                        // Right arrow = previous page (RTL: n-1)
                        Button(action: flipToPrevPage) {
                            Image(systemName: "chevron.right")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Theme.textPrimary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Theme.cardBackground.opacity(0.92))
                                        .shadow(color: Theme.shadowColor, radius: 4, y: 2)
                                )
                        }
                        .padding(.trailing, 14)
                        .disabled(targetIndex <= 1)
                    }

                    // Reset-zoom button (top-right overlay)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { resetZoomAction?() }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Theme.cardBackground.opacity(0.92))
                                            .shadow(color: Theme.shadowColor, radius: 4, y: 2)
                                    )
                            }
                            .padding(.top, 10)
                            .padding(.trailing, 14)
                        }
                        Spacer()
                    }
                }

                pageSlider
                pdfBottomBar
            } else {
                pdfNotFoundView
            }
        }
        .onAppear {
            loadPDF()
            setPopGestureEnabled(false)
        }
        .onDisappear {
            setPopGestureEnabled(true)
        }
        .onChange(of: currentMushafPage) { _, newPage in
            let clamped = max(1, min(newPage, Self.quranPageCount))
            guard clamped != targetIndex else { return }
            targetIndex = clamped
            sliderValue = Double(clamped)
        }
    }

    // MARK: - Loading / Error Views

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Theme.accent)
            Text("PDF wird geladen…")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private var pdfNotFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("PDF nicht gefunden")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("\(resourceName).pdf konnte nicht geladen werden.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Page Slider

    private var pageSlider: some View {
        VStack(spacing: 2) {
            Text("\(L10n.quranPage(language)) \(targetIndex)")
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundColor(Theme.textSecondary)
            Slider(value: $sliderValue,
                   in: 1...Double(Self.quranPageCount),
                   step: 1)
                .tint(Theme.accent)
                .environment(\.layoutDirection, .rightToLeft)
                .onChange(of: sliderValue) { _, newVal in
                    let page = Int(newVal)   // page == pdfIndex since mapping is 1:1
                    guard page != targetIndex else { return }
                    targetIndex = page
                    currentMushafPage = page
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Theme.background)
    }

    // MARK: - Bottom Bar

    private var pdfBottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(surahLabelForCurrentPage)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(bottomLabel)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Text("\(targetIndex) / \(Self.quranPageCount)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.cardBackground)
    }

    private var surahLabelForCurrentPage: String {
        let match = suraList
            .filter { $0.pageNumber <= targetIndex }
            .max(by: { $0.pageNumber < $1.pageNumber })
        guard let s = match else { return "القرآن الكريم" }
        return "\(s.nameTransliteration) · \(s.nameArabic)"
    }

    // MARK: - Arrow Button Helpers

    private func flipToNextPage() {
        let next = min(targetIndex + 1, Self.quranPageCount)
        guard next != targetIndex else { return }
        targetIndex = next
        sliderValue = Double(next)
        currentMushafPage = next
    }

    private func flipToPrevPage() {
        let prev = max(targetIndex - 1, 1)
        guard prev != targetIndex else { return }
        targetIndex = prev
        sliderValue = Double(prev)
        currentMushafPage = prev
    }

    // MARK: - Page Change Handler

    /// Called by coordinator when the PDF page changes (pdfIndex is 0-based).
    /// pdfIndex == mushafPage (skip index 0 = cover).
    private func handlePageChange(_ pdfIndex: Int) {
        guard pdfIndex >= 1, pdfIndex <= Self.quranPageCount else { return }
        targetIndex = pdfIndex
        sliderValue = Double(pdfIndex)
        currentMushafPage = pdfIndex
    }

    // MARK: - Load PDF

    private func loadPDF() {
        guard pdfDocument == nil else { return }
        let name = resourceName
        Task.detached(priority: .userInitiated) {
            let doc: PDFDocument?
            if let url = Bundle.main.url(forResource: name, withExtension: "pdf") {
                doc = PDFDocument(url: url)
            } else {
                doc = nil
            }
            await MainActor.run {
                pdfDocument = doc
                isLoading = false
            }
        }
    }
}

// MARK: - Image-based Mushaf viewer (pc2-web JPG pages)

struct MushafImagePageView: View {
    let suraList: [QuranSuraInfo]
    let language: AppLanguage
    @Binding var currentMushafPage: Int

    @State private var pageScrollID: Int?
    @State private var sliderValue: Double

    private static let pageCount = 604

    init(suraList: [QuranSuraInfo], language: AppLanguage, currentMushafPage: Binding<Int>) {
        self.suraList = suraList
        self.language = language
        self._currentMushafPage = currentMushafPage
        self._sliderValue = State(initialValue: Double(currentMushafPage.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(1...Self.pageCount, id: \.self) { pageNum in
                            QuranPageImageCell(pageNumber: pageNum)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(pageNum)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $pageScrollID)
                .environment(\.layoutDirection, .rightToLeft)
            }
            .onChange(of: pageScrollID) { _, newID in
                guard let page = newID, page != currentMushafPage else { return }
                currentMushafPage = page
                sliderValue = Double(page)
            }
            .onChange(of: currentMushafPage) { _, newPage in
                guard pageScrollID != newPage else { return }
                sliderValue = Double(newPage)
                withAnimation(.easeInOut(duration: 0.25)) { pageScrollID = newPage }
            }

            imagePageSlider
            imageBottomBar
        }
        .onAppear {
            pageScrollID = currentMushafPage
            sliderValue = Double(currentMushafPage)
            setPopGestureEnabled(false)
        }
        .onDisappear { setPopGestureEnabled(true) }
    }

    private var imagePageSlider: some View {
        VStack(spacing: 2) {
            Text("\(L10n.quranPage(language)) \(currentMushafPage)")
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundColor(Theme.textSecondary)
            Slider(value: $sliderValue, in: 1...Double(Self.pageCount), step: 1)
                .tint(Theme.accent)
                .environment(\.layoutDirection, .rightToLeft)
                .onChange(of: sliderValue) { _, newVal in
                    let page = Int(newVal)
                    guard page != currentMushafPage else { return }
                    currentMushafPage = page
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Theme.background)
    }

    private var imageBottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(surahLabelForCurrentPage)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text("Mushaf-Bilder · PC2")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Text("\(currentMushafPage) / \(Self.pageCount)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.cardBackground)
    }

    private var surahLabelForCurrentPage: String {
        let match = suraList
            .filter { $0.pageNumber <= currentMushafPage }
            .max(by: { $0.pageNumber < $1.pageNumber })
        guard let s = match else { return "القرآن الكريم" }
        return "\(s.nameTransliteration) · \(s.nameArabic)"
    }
}

// MARK: - Single page cell (lazy-loaded JPEG)

private struct QuranPageImageCell: View {
    let pageNumber: Int
    @State private var image: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.white
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView().tint(.gray)
            } else {
                // Shown briefly before load starts or when image is missing
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
        // .task runs after the view update cycle, so state mutations here are safe.
        .task(id: pageNumber) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        guard image == nil else { return }
        isLoading = true
        let loaded: UIImage? = await Task.detached(priority: .userInitiated) { [pageNumber] in
            guard let path = Bundle.main.path(
                forResource: "\(pageNumber)", ofType: "jpg",
                inDirectory: "pc2-web"
            ) else { return nil }
            return UIImage(contentsOfFile: path)
        }.value
        image = loaded
        isLoading = false
    }
}
