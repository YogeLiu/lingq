# LingQ App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify LingQ app — remove intensive reading, simplify vocabulary to saved-only, redesign import to zip files, add word tapping in immersive view, enhance playback controls.

**Architecture:** Modify existing modular Swift Packages + SwiftUI App. Course model changes to store local file paths instead of bookmarks. Import extracts zip to Documents directory. Immersive view gains word-level tapping for vocabulary saving.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation, NaturalLanguage, UIKit (system dictionary), ZIPFoundation (or manual zip via FileManager)

---

## File Map

### Files to Create
- `App/lingQ/Import/ZipImporter.swift` — zip extraction logic, finds cover/mp3/srt by extension
- `App/lingQ/Import/ZipImportView.swift` — new import UI (file picker for .zip, extraction progress)
- `App/lingQ/ImmersiveListening/TappableSubtitleLineView.swift` — word-level tapping in immersive subtitles

### Files to Modify
- `Packages/SharedModels/Sources/SharedModels/Course.swift` — add `coverImagePath`, `audioFilePath`, `subtitleFilePath`; keep legacy bookmark fields temporarily
- `Packages/SharedModels/Sources/SharedModels/WordLevel.swift` — simplify to two cases: `saved`, `known`
- `Packages/VocabularyKit/Sources/VocabularyKit/Word.swift` — remove `level` field, keep SRS fields
- `Packages/VocabularyKit/Sources/VocabularyKit/VocabularyStore.swift` — simplify: `saveWord()` replaces `addWord(level:)`, remove `updateLevel`, keep `gradeReview`
- `App/lingQ/Playback/PlaybackDetailView.swift` — full redesign: cover image, enhanced controls (speed, A-B repeat, prev/next sentence), single "subtitle" button
- `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift` — pass vocabulary saving capability, accept modelContext
- `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift` — add speed button, A-B repeat toggle
- `App/lingQ/ImmersiveListening/LyricsCanvasView.swift` — use TappableSubtitleLineView instead of LyricLineView
- `App/lingQ/ImmersiveListening/LyricLineView.swift` — keep for non-tappable display (ambient mode)
- `App/lingQ/Vocabulary/VocabularyListView.swift` — remove level filter chips, simplify to flat list
- `App/lingQ/Vocabulary/WordCardView.swift` — remove level badge, simplify display
- `App/lingQ/ContentView.swift` — update tab structure
- `App/lingQ/Home/HomeView.swift` — update import flow reference
- `App/lingQ/Home/ContinueListeningCard.swift` — show cover image
- `App/lingQ/Home/RecentCourseStrip.swift` — show cover image
- `App/lingQ/CourseList/CourseCardView.swift` — show cover image
- `App/lingQ/CourseList/CourseListView.swift` — replace import flow with zip import
- `App/lingQ/Profile/MeView.swift` — update import references
- `App/lingQ/Review/FlashcardReviewView.swift` — update description text (remove "精读模式" reference)
- `App/lingQ/Theme/AppTheme.swift` — remove level-specific colors (level1/2/3)

### Files to Delete
- `App/lingQ/IntensiveReading/IntensiveReadingView.swift`
- `App/lingQ/IntensiveReading/MiniPlayerView.swift`
- `App/lingQ/IntensiveReading/SentenceView.swift`
- `App/lingQ/IntensiveReading/TappableWordView.swift`
- `App/lingQ/IntensiveReading/WordLookupPopup.swift`
- `App/lingQ/Import/ImportCourseSheet.swift` — replaced by ZipImportView

---

## Task 1: Simplify Word model and VocabularyStore

Remove the 4-level vocabulary system. Words are either saved or not saved (existence in DB = saved). Keep SRS fields for flashcard review.

**Files:**
- Modify: `Packages/SharedModels/Sources/SharedModels/WordLevel.swift`
- Modify: `Packages/VocabularyKit/Sources/VocabularyKit/Word.swift`
- Modify: `Packages/VocabularyKit/Sources/VocabularyKit/VocabularyStore.swift`
- Modify: `Packages/VocabularyKit/Tests/VocabularyKitTests/VocabularyStoreTests.swift`
- Modify: `Packages/VocabularyKit/Tests/VocabularyKitTests/WordTests.swift`
- Modify: `Packages/SharedModels/Tests/SharedModelsTests/WordLevelTests.swift`

- [ ] **Step 1: Simplify WordLevel enum**

Replace the 5-case enum with a simpler version. Since SwiftData uses this, we keep it as an enum but with only two values.

```swift
// Packages/SharedModels/Sources/SharedModels/WordLevel.swift
import Foundation

public enum WordLevel: Int, Codable, Sendable, CaseIterable {
    case saved = 1
    case known = 4

    public var displayName: String {
        switch self {
        case .saved: "SAVED"
        case .known: "KNOWN"
        }
    }
}
```

- [ ] **Step 2: Simplify Word model**

```swift
// Packages/VocabularyKit/Sources/VocabularyKit/Word.swift
import Foundation
import SwiftData
import SharedModels

@Model
public final class Word {
    public var id: UUID
    public var text: String
    public var definition: String?
    public var phonetic: String?
    public var contextSentence: String?
    public var courseId: UUID?
    public var createdAt: Date
    public var nextReviewAt: Date?
    public var reviewCount: Int
    public var easeFactor: Double

    public init(text: String, contextSentence: String?, courseId: UUID? = nil) {
        self.id = UUID()
        self.text = text.lowercased()
        self.definition = nil
        self.phonetic = nil
        self.contextSentence = contextSentence
        self.courseId = courseId
        self.createdAt = Date()
        self.nextReviewAt = Date() // schedule review immediately
        self.reviewCount = 0
        self.easeFactor = 2.5
    }

    public var isDueForReview: Bool {
        guard let nextReviewAt else { return false }
        return nextReviewAt <= Date()
    }
}
```

- [ ] **Step 3: Simplify VocabularyStore**

```swift
// Packages/VocabularyKit/Sources/VocabularyKit/VocabularyStore.swift
import Foundation
import SwiftData
import SharedModels
import SRSKit

@MainActor
public struct VocabularyStore {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Save a word. If it already exists, update context sentence.
    public func saveWord(_ text: String, definition: String? = nil, contextSentence: String?, courseId: UUID?) throws {
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        if let existing = try modelContext.fetch(descriptor).first {
            if let ctx = contextSentence { existing.contextSentence = ctx }
            if let def = definition { existing.definition = def }
            return
        }

        let word = Word(text: text, contextSentence: contextSentence, courseId: courseId)
        word.definition = definition
        modelContext.insert(word)
    }

    /// Check if a word is already saved
    public func isWordSaved(_ text: String) throws -> Bool {
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        return try modelContext.fetchCount(descriptor) > 0
    }

    public func gradeReview(word: Word, grade: ReviewGrade) {
        let schedule = SM2Algorithm.schedule(
            grade: grade,
            repetition: word.reviewCount,
            easeFactor: word.easeFactor,
            interval: currentInterval(for: word)
        )
        word.reviewCount = schedule.repetition
        word.easeFactor = schedule.easeFactor
        word.nextReviewAt = Calendar.current.date(byAdding: .day, value: schedule.interval, to: Date())
    }

    public func wordsForReview() throws -> [Word] {
        let now = Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.nextReviewAt != nil && word.nextReviewAt! <= now
            },
            sortBy: [SortDescriptor(\.nextReviewAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func deleteWord(_ word: Word) {
        modelContext.delete(word)
    }

    private func currentInterval(for word: Word) -> Int {
        guard let nextReview = word.nextReviewAt else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: word.createdAt, to: nextReview).day ?? 0, 0)
    }
}
```

- [ ] **Step 4: Update tests**

Update `WordTests.swift` and `VocabularyStoreTests.swift` to reflect simplified model. Remove `WordLevelTests.swift` content or simplify.

- [ ] **Step 5: Build and verify packages compile**

Run: `cd Packages/VocabularyKit && swift build`
Run: `cd Packages/SharedModels && swift build`

- [ ] **Step 6: Commit**

```bash
git add Packages/SharedModels Packages/VocabularyKit
git commit -m "refactor: simplify vocabulary to saved-only, remove 4-level system"
```

---

## Task 2: Update Course model for local file storage

Add fields for local file paths (cover image, audio, subtitle stored in app Documents). Keep legacy bookmark fields to avoid migration crash, but new import will use file paths.

**Files:**
- Modify: `Packages/SharedModels/Sources/SharedModels/Course.swift`

- [ ] **Step 1: Add local file path fields to Course**

```swift
// Packages/SharedModels/Sources/SharedModels/Course.swift
import Foundation
import SwiftData

@Model
public final class Course {
    public var id: UUID
    public var title: String
    public var audioBookmark: Data  // legacy, keep for existing data
    public var subtitleBookmark: Data  // legacy
    public var audioFilePath: String?  // new: relative path in Documents
    public var subtitleFilePath: String?  // new: relative path in Documents
    public var coverImagePath: String?  // new: relative path in Documents
    public var createdAt: Date
    public var lastPlayedAt: Date?
    public var playbackPosition: TimeInterval
    public var folder: String?

    public init(
        title: String,
        audioBookmark: Data,
        subtitleBookmark: Data
    ) {
        self.id = UUID()
        self.title = title
        self.audioBookmark = audioBookmark
        self.subtitleBookmark = subtitleBookmark
        self.audioFilePath = nil
        self.subtitleFilePath = nil
        self.coverImagePath = nil
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }

    /// New initializer for zip import
    public init(
        title: String,
        audioFilePath: String,
        subtitleFilePath: String,
        coverImagePath: String?
    ) {
        self.id = UUID()
        self.title = title
        self.audioBookmark = Data()  // empty, not used
        self.subtitleBookmark = Data()  // empty, not used
        self.audioFilePath = audioFilePath
        self.subtitleFilePath = subtitleFilePath
        self.coverImagePath = coverImagePath
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }

    /// Resolve audio URL — prefers local file path, falls back to bookmark
    public var resolvedAudioURL: URL? {
        if let audioFilePath {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(audioFilePath)
        }
        return nil
    }

    /// Resolve subtitle URL — prefers local file path, falls back to bookmark
    public var resolvedSubtitleURL: URL? {
        if let subtitleFilePath {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(subtitleFilePath)
        }
        return nil
    }

    /// Resolve cover image URL
    public var resolvedCoverImageURL: URL? {
        guard let coverImagePath else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(coverImagePath)
    }
}
```

- [ ] **Step 2: Build SharedModels**

Run: `cd Packages/SharedModels && swift build`

- [ ] **Step 3: Commit**

```bash
git add Packages/SharedModels
git commit -m "feat: add local file path fields to Course for zip import"
```

---

## Task 3: Create ZipImporter and ZipImportView

Build the new import flow: user picks a .zip from iOS Files, app extracts to Documents/<courseId>/, finds cover/mp3/srt by extension, creates Course.

**Files:**
- Create: `App/lingQ/Import/ZipImporter.swift`
- Create: `App/lingQ/Import/ZipImportView.swift`

- [ ] **Step 1: Create ZipImporter**

This handles extraction and file discovery. Uses Foundation's built-in zip support via `Process` or `Archive` — but on iOS there's no built-in zip. We'll use a simple approach with `FileManager` and the `compression` framework, or better: just use `UTType.zip` with `fileImporter` and shell out to `unzip` — no, iOS doesn't have that. We need to add a small zip extraction. The simplest approach: use Apple's `Compression` framework or bundle a minimal unzip.

Actually, the simplest iOS approach is to use the `ZIPFoundation` SPM package, or implement minimal zip extraction. Let's use `ZIPFoundation` as it's well-maintained and lightweight.

```swift
// App/lingQ/Import/ZipImporter.swift
import Foundation
import UniformTypeIdentifiers
import OSLog

enum ZipImporter {
    private static let logger = Logger(subsystem: "com.lingq.lingQ", category: "ZipImport")

    struct ImportResult {
        let title: String
        let audioFilePath: String
        let subtitleFilePath: String
        let coverImagePath: String?
    }

    enum ImportError: LocalizedError {
        case noAudioFile
        case noSubtitleFile
        case extractionFailed(String)

        var errorDescription: String? {
            switch self {
            case .noAudioFile: return "ZIP 中未找到音频文件 (.mp3, .m4a, .wav, .aac)"
            case .noSubtitleFile: return "ZIP 中未找到字幕文件 (.srt)"
            case .extractionFailed(let msg): return "解压失败: \(msg)"
            }
        }
    }

    static func importZip(from sourceURL: URL) throws -> ImportResult {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let courseId = UUID().uuidString
        let courseDir = docs.appendingPathComponent("courses/\(courseId)")

        // Create course directory
        try fileManager.createDirectory(at: courseDir, withIntermediateDirectories: true)

        // Extract zip
        do {
            try extractZip(at: sourceURL, to: courseDir)
        } catch {
            // Clean up on failure
            try? fileManager.removeItem(at: courseDir)
            throw ImportError.extractionFailed(error.localizedDescription)
        }

        // Find files by extension
        let contents = try fileManager.contentsOfDirectory(at: courseDir, includingPropertiesForKeys: nil)

        // Also check one level deep (zip might contain a folder)
        var allFiles = contents
        for item in contents {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                let subContents = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)
                allFiles.append(contentsOf: subContents)
            }
        }

        let audioExtensions = Set(["mp3", "m4a", "wav", "aac"])
        let imageExtensions = Set(["jpg", "jpeg", "png", "webp"])

        let audioFile = allFiles.first { audioExtensions.contains($0.pathExtension.lowercased()) }
        let subtitleFile = allFiles.first { $0.pathExtension.lowercased() == "srt" }
        let coverFile = allFiles.first { imageExtensions.contains($0.pathExtension.lowercased()) }

        guard let audioFile else {
            try? fileManager.removeItem(at: courseDir)
            throw ImportError.noAudioFile
        }
        guard let subtitleFile else {
            try? fileManager.removeItem(at: courseDir)
            throw ImportError.noSubtitleFile
        }

        // Move files to predictable names in course dir
        let audioDest = courseDir.appendingPathComponent("audio.\(audioFile.pathExtension)")
        let subtitleDest = courseDir.appendingPathComponent("subtitle.srt")

        if audioFile != audioDest {
            try? fileManager.moveItem(at: audioFile, to: audioDest)
        }
        if subtitleFile != subtitleDest {
            try? fileManager.moveItem(at: subtitleFile, to: subtitleDest)
        }

        var coverRelPath: String?
        if let coverFile {
            let coverDest = courseDir.appendingPathComponent("cover.\(coverFile.pathExtension)")
            if coverFile != coverDest {
                try? fileManager.moveItem(at: coverFile, to: coverDest)
            }
            coverRelPath = "courses/\(courseId)/cover.\(coverFile.pathExtension)"
        }

        // Derive title from zip filename
        let title = sourceURL.deletingPathExtension().lastPathComponent

        logger.info("Successfully imported: \(title, privacy: .public) -> \(courseId, privacy: .public)")

        return ImportResult(
            title: title,
            audioFilePath: "courses/\(courseId)/audio.\(audioFile.pathExtension)",
            subtitleFilePath: "courses/\(courseId)/subtitle.srt",
            coverImagePath: coverRelPath
        )
    }

    private static func extractZip(at sourceURL: URL, to destinationURL: URL) throws {
        // Use Process/NSFileCoordinator approach or a lightweight unzip
        // On iOS, we use Archive from the Compression framework
        // For simplicity, we'll use the built-in approach via FileManager
        // Actually iOS doesn't have a built-in zip API — we need ZIPFoundation or manual implementation

        // Minimal approach: copy zip, use posix functions
        // Best approach for production: add ZIPFoundation SPM dependency

        // For now, use Apple's newer approach with FileManager (iOS 16+: no native zip)
        // We'll implement using the Compression framework's Archive type
        // Actually the cleanest approach: just import the file as-is and use a small helper

        // PLACEHOLDER: This will use ZIPFoundation. Add to Package.swift:
        // .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")

        // Using ZIPFoundation:
        try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
    }

    /// Delete course files from disk
    static func deleteCourseFiles(audioFilePath: String?, subtitleFilePath: String?, coverImagePath: String?) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        // Find the course directory from any file path
        if let audioFilePath {
            let audioURL = docs.appendingPathComponent(audioFilePath)
            let courseDir = audioURL.deletingLastPathComponent()
            try? fileManager.removeItem(at: courseDir)
        }
    }
}
```

- [ ] **Step 2: Add ZIPFoundation dependency**

Add to the Xcode project's package dependencies:
- Package URL: `https://github.com/weichsel/ZIPFoundation.git`
- Version: `0.9.19` or later
- Link `ZIPFoundation` framework to the App target

- [ ] **Step 3: Create ZipImportView**

```swift
// App/lingQ/Import/ZipImportView.swift
import SwiftUI
import SwiftData
import SharedModels
import UniformTypeIdentifiers

struct ZipImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "doc.zipper")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.brandAccent)

                VStack(spacing: 8) {
                    Text("导入听力课程")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("选择一个 ZIP 文件，包含音频 (.mp3)、字幕 (.srt)，以及可选的封面图片。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    showFilePicker = true
                } label: {
                    Label(isImporting ? "正在导入..." : "选择 ZIP 文件", systemImage: "folder")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandAccent)
                .disabled(isImporting)
                .padding(.horizontal, 32)

                Spacer()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.zip],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("导入失败", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
            .alert("导入成功", isPresented: $importSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text("课程已添加到你的播放列表。")
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError { return }
            importError = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true

            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let importResult = try ZipImporter.importZip(from: url)
                let course = Course(
                    title: importResult.title,
                    audioFilePath: importResult.audioFilePath,
                    subtitleFilePath: importResult.subtitleFilePath,
                    coverImagePath: importResult.coverImagePath
                )
                modelContext.insert(course)
                isImporting = false
                importSuccess = true
            } catch {
                isImporting = false
                importError = error.localizedDescription
            }
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/Import/ZipImporter.swift App/lingQ/Import/ZipImportView.swift
git commit -m "feat: add zip import flow for course content"
```

---

## Task 4: Redesign PlaybackDetailView

Remove "immersive" and "intensive reading" buttons. Add full playback controls: speed, A-B repeat, prev/next sentence. Show cover image. Single "subtitle" button enters immersive view.

**Files:**
- Modify: `App/lingQ/Playback/PlaybackDetailView.swift`

- [ ] **Step 1: Rewrite PlaybackDetailView**

```swift
// App/lingQ/Playback/PlaybackDetailView.swift
import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit

struct PlaybackDetailView: View {
    let course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var player = AudioPlayer()
    @State private var cues: [SubtitleCue] = []
    @State private var searcher: CueSearcher?
    @State private var loadState: LoadState = .idle
    @State private var showImmersive = false
    @State private var abRepeatActive = false
    @State private var showSpeedPicker = false

    private let availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    private enum LoadState: Equatable {
        case idle, loading, ready, failed(String)
    }

    var body: some View {
        Group {
            switch loadState {
            case .idle, .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppTheme.brandAccent)
                    Text("Loading...")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                EmptyStateCard(
                    icon: "exclamationmark.triangle",
                    title: "Unable to open",
                    message: message,
                    actionTitle: "Retry"
                ) {
                    Task { await loadContent() }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready:
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        coverImageSection
                        titleSection
                        progressSection
                        controlsSection
                        subtitleButton
                    }
                    .padding(20)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadContent() }
        .fullScreenCover(isPresented: $showImmersive) {
            if let searcher {
                ImmersiveListeningView(
                    course: course,
                    cues: cues,
                    searcher: searcher,
                    player: player
                )
            }
        }
        .onDisappear {
            course.playbackPosition = player.currentTime
            course.lastPlayedAt = Date()
            player.pause()
        }
    }

    // MARK: - Sections

    private var coverImageSection: some View {
        Group {
            if let coverURL = course.resolvedCoverImageURL,
               let uiImage = UIImage(contentsOfFile: coverURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.surfaceMuted)
                    .frame(height: 240)
                    .overlay {
                        Image(systemName: "headphones")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(course.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("\(cues.count) sentences")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { progressValue },
                    set: { player.seek(to: $0) }
                ),
                in: 0...progressTotal
            )
            .tint(AppTheme.brandAccent)

            HStack {
                Text(formatTime(progressValue))
                Spacer()
                Text(formatTime(progressTotal))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Main controls
            HStack(spacing: 20) {
                // Speed button
                Button {
                    cycleSpeed()
                } label: {
                    Text(speedLabel)
                        .font(.caption.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surfaceMuted, in: Circle())
                }

                // Previous sentence
                Button {
                    if let prev = searcher?.previousCue(before: player.currentTime) {
                        player.seek(to: prev.startTime)
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                }

                // Backward 10s
                Button { player.skipBackward(10) } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                }

                // Play/Pause
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(width: 64, height: 64)
                .background(AppTheme.brandAccent, in: Circle())
                .foregroundStyle(.white)

                // Forward 10s
                Button { player.skipForward(10) } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                }

                // Next sentence
                Button {
                    if let next = searcher?.nextCue(after: player.currentTime) {
                        player.seek(to: next.startTime)
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                }

                // A-B repeat
                Button {
                    toggleABRepeat()
                } label: {
                    Image(systemName: "repeat")
                        .font(.caption.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(abRepeatActive ? AppTheme.brandAccent.opacity(0.2) : AppTheme.surfaceMuted, in: Circle())
                        .foregroundStyle(abRepeatActive ? AppTheme.brandAccent : AppTheme.textPrimary)
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
    }

    private var subtitleButton: some View {
        Button {
            showImmersive = true
        } label: {
            Label("Subtitles", systemImage: "captions.bubble")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.brandAccent)
        .disabled(cues.isEmpty)
    }

    // MARK: - Helpers

    private var speedLabel: String {
        let rate = player.playbackRate
        if rate == Float(Int(rate)) {
            return "\(Int(rate))x"
        }
        return String(format: "%.1fx", rate)
    }

    private func cycleSpeed() {
        let current = player.playbackRate
        if let idx = availableSpeeds.firstIndex(of: current) {
            let next = availableSpeeds[(idx + 1) % availableSpeeds.count]
            player.playbackRate = next
        } else {
            player.playbackRate = 1.0
        }
    }

    private func toggleABRepeat() {
        if abRepeatActive {
            player.loopRange = nil
            abRepeatActive = false
        } else if let currentCue = searcher?.cue(at: player.currentTime) {
            player.loopRange = currentCue.startTime...currentCue.endTime
            abRepeatActive = true
        }
    }

    private var progressTotal: TimeInterval {
        let duration = player.duration
        guard duration.isFinite, duration > 0 else { return 1 }
        return duration
    }

    private var progressValue: TimeInterval {
        let time = player.currentTime
        guard time.isFinite else { return 0 }
        return min(max(time, 0), progressTotal)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func loadContent() async {
        loadState = .loading
        do {
            // Try new file path approach first, fall back to bookmarks
            let subtitleURL: URL
            let audioURL: URL

            if let resolvedSubtitle = course.resolvedSubtitleURL,
               FileManager.default.fileExists(atPath: resolvedSubtitle.path) {
                subtitleURL = resolvedSubtitle
            } else {
                subtitleURL = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
                _ = subtitleURL.startAccessingSecurityScopedResource()
            }

            if let resolvedAudio = course.resolvedAudioURL,
               FileManager.default.fileExists(atPath: resolvedAudio.path) {
                audioURL = resolvedAudio
            } else {
                audioURL = try BookmarkManager.resolveBookmark(course.audioBookmark)
                _ = audioURL.startAccessingSecurityScopedResource()
            }

            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)
            try player.load(url: audioURL)
            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }
            loadState = .ready
        } catch {
            loadState = .failed("Failed to load. The file may have been moved or deleted.")
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add App/lingQ/Playback/PlaybackDetailView.swift
git commit -m "feat: redesign playback page with cover, speed, A-B repeat, subtitle button"
```

---

## Task 5: Add word tapping to ImmersiveListeningView

Add the ability to tap individual words in subtitle lines during immersive playback. Tapping saves the word and shows a quick popup with system dictionary.

**Files:**
- Create: `App/lingQ/ImmersiveListening/TappableSubtitleLineView.swift`
- Modify: `App/lingQ/ImmersiveListening/LyricsCanvasView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift`

- [ ] **Step 1: Create TappableSubtitleLineView**

A version of LyricLineView where each word is individually tappable.

```swift
// App/lingQ/ImmersiveListening/TappableSubtitleLineView.swift
import SwiftUI
import NaturalLanguage
import SharedModels

struct TappableSubtitleLineView: View {
    let text: String
    let state: LyricLineView.LyricState
    let mode: ImmersiveMode
    let onLineTap: () -> Void
    let onWordTap: (String, String) -> Void  // (word, contextSentence)

    var body: some View {
        FlowLayout(spacing: wordSpacing) {
            ForEach(tokenize(text), id: \.self) { word in
                Text(word)
                    .font(font)
                    .foregroundStyle(foregroundColor)
                    .onTapGesture {
                        onWordTap(word, text)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, state.isCurrent ? 8 : 2)
        .opacity(state.opacity(for: mode))
        .animation(.easeInOut(duration: 0.4), value: state.isCurrent)
        .contentShape(Rectangle())
    }

    private var wordSpacing: CGFloat { state.isCurrent ? 6 : 4 }

    private var font: Font {
        state.isCurrent ? .title3.weight(.bold) : .body
    }

    private var foregroundColor: Color {
        switch state {
        case .current: AppTheme.brandAccent
        case .future: AppTheme.textPrimary
        case .past: AppTheme.textTertiary
        }
    }

    private func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }
}

// Reuse FlowLayout from SentenceView — we'll move it to a shared location
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 2: Update LyricsCanvasView to support word tapping**

```swift
// App/lingQ/ImmersiveListening/LyricsCanvasView.swift
import SwiftUI
import SharedModels

struct LyricsCanvasView: View {
    let cues: [SubtitleCue]
    let currentIndex: Int?
    let mode: ImmersiveMode
    let onCueTap: (SubtitleCue) -> Void
    let onWordTap: (String, String) -> Void  // (word, contextSentence)

    init(
        cues: [SubtitleCue],
        currentIndex: Int?,
        mode: ImmersiveMode,
        onCueTap: @escaping (SubtitleCue) -> Void,
        onWordTap: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.cues = cues
        self.currentIndex = currentIndex
        self.mode = mode
        self.onCueTap = onCueTap
        self.onWordTap = onWordTap
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Spacer(minLength: 120)

                    ForEach(Array(cues.enumerated()), id: \.element.id) { index, cue in
                        TappableSubtitleLineView(
                            text: cue.text,
                            state: lyricState(for: index),
                            mode: mode,
                            onLineTap: { onCueTap(cue) },
                            onWordTap: onWordTap
                        )
                        .id(cue.id)
                    }

                    Spacer(minLength: 300)
                }
                .padding(.horizontal, 24)
            }
            .onChange(of: currentIndex) { _, newIndex in
                if let id = newIndex.flatMap({ cues[safe: $0]?.id }) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func lyricState(for index: Int) -> LyricLineView.LyricState {
        guard let current = currentIndex else { return .future(distance: 0) }
        if index == current { return .current }
        if index < current { return .past(distance: current - index) }
        return .future(distance: index - current)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

- [ ] **Step 3: Update ImmersiveListeningView to handle word saves**

Add `@Environment(\.modelContext)`, word save handling, and a simple confirmation toast.

```swift
// App/lingQ/ImmersiveListening/ImmersiveListeningView.swift
import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit
import UIKit

struct ImmersiveListeningView: View {
    let course: Course
    let cues: [SubtitleCue]
    let searcher: CueSearcher
    @Bindable var player: AudioPlayer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var mode: ImmersiveMode = .focused
    @State private var currentIndex: Int?
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var savedWordToast: String?
    @State private var showDictionaryWord: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()

            LyricsCanvasView(
                cues: cues,
                currentIndex: currentIndex,
                mode: mode,
                onCueTap: { cue in
                    player.seek(to: cue.startTime)
                    showControlsTemporarily()
                },
                onWordTap: { word, sentence in
                    saveWord(word, contextSentence: sentence)
                }
            )
            .padding(.bottom, controlsVisible ? 200 : 60)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    controlsVisible.toggle()
                }
                if controlsVisible {
                    scheduleHideControls()
                }
            }

            if controlsVisible {
                ImmersivePlayerView(
                    player: player,
                    mode: $mode,
                    onPrevious: {
                        if let prev = searcher.previousCue(before: player.currentTime) {
                            player.seek(to: prev.startTime)
                        }
                    },
                    onNext: {
                        if let next = searcher.nextCue(after: player.currentTime) {
                            player.seek(to: next.startTime)
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Saved word toast
            if let word = savedWordToast {
                VStack {
                    Spacer()
                    Text("Saved: \(word)")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, controlsVisible ? 220 : 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if controlsVisible {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .padding(12)
                        .background(.thinMaterial, in: Circle())
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.leading, 20)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if controlsVisible {
                VStack(spacing: 2) {
                    Text(mode.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(mode.description)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
        .animation(.easeInOut(duration: 0.3), value: savedWordToast != nil)
        .onChange(of: player.currentTime) { _, time in
            currentIndex = searcher.index(at: time)
        }
        .onAppear {
            currentIndex = searcher.index(at: player.currentTime)
            scheduleHideControls()
        }
        .sheet(item: Binding(
            get: { showDictionaryWord.map { DictionaryItem(word: $0) } },
            set: { showDictionaryWord = $0?.word }
        )) { item in
            DictionaryLookupView(term: item.word)
        }
    }

    private func saveWord(_ word: String, contextSentence: String) {
        let store = VocabularyStore(modelContext: modelContext)
        try? store.saveWord(word, contextSentence: contextSentence, courseId: course.id)

        // Show toast
        withAnimation {
            savedWordToast = word
        }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation { savedWordToast = nil }
            }
        }

        // Show system dictionary
        showDictionaryWord = word
    }

    private func showControlsTemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            controlsVisible = true
        }
        scheduleHideControls()
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    controlsVisible = false
                }
            }
        }
    }
}

private struct DictionaryItem: Identifiable {
    let word: String
    var id: String { word }
}

/// Wraps UIReferenceLibraryViewController for system dictionary lookup
struct DictionaryLookupView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
```

- [ ] **Step 4: Add speed and A-B repeat to ImmersivePlayerView**

```swift
// App/lingQ/ImmersiveListening/ImmersivePlayerView.swift
// Add speed button and A-B repeat toggle to the existing player controls
// (Full rewrite shown in the implementation — add speed cycling button on left,
//  A-B repeat button on right of the controls row)
```

The ImmersivePlayerView should have speed and A-B repeat buttons matching the PlaybackDetailView controls.

- [ ] **Step 5: Commit**

```bash
git add App/lingQ/ImmersiveListening/
git commit -m "feat: add word tapping and vocabulary saving in immersive view"
```

---

## Task 6: Update navigation, tabs, and import references

Wire up the new zip import, remove intensive reading references, update tab structure and home view.

**Files:**
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/Home/HomeView.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Modify: `App/lingQ/CourseList/CourseCardView.swift`
- Modify: `App/lingQ/Home/ContinueListeningCard.swift`
- Modify: `App/lingQ/Home/RecentCourseStrip.swift`
- Modify: `App/lingQ/Profile/MeView.swift`

- [ ] **Step 1: Update CourseListView to use ZipImportView**

Replace the old multi-step import flow with a sheet presenting `ZipImportView`. Remove all `pendingAudioBookmark`, `pendingSubtitleBookmark`, `ImportStep`, `fileImporter`, `ImportCourseSheet` references. The import button now presents `ZipImportView` as a sheet.

- [ ] **Step 2: Update CourseCardView to show cover image**

Add cover image thumbnail on the left side of the card. Use `course.resolvedCoverImageURL` to load image.

```swift
// In CourseCardView, add before the title VStack:
if let coverURL = course.resolvedCoverImageURL,
   let uiImage = UIImage(contentsOfFile: coverURL.path) {
    Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
} else {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(AppTheme.surfaceMuted)
        .frame(width: 56, height: 56)
        .overlay {
            Image(systemName: "headphones")
                .foregroundStyle(AppTheme.textTertiary)
        }
}
```

- [ ] **Step 3: Update ContinueListeningCard to show cover image**

Add cover image at the top of the card.

- [ ] **Step 4: Update RecentCourseStrip to show cover image**

Add small cover image thumbnail in each strip card.

- [ ] **Step 5: Update HomeView import flow**

Change the import action to present ZipImportView instead of navigating to MeView.

- [ ] **Step 6: Update MeView**

Replace import navigation with direct ZipImportView sheet. Keep flashcard review and vocabulary links.

- [ ] **Step 7: Commit**

```bash
git add App/lingQ/ContentView.swift App/lingQ/Home/ App/lingQ/CourseList/ App/lingQ/Profile/
git commit -m "feat: wire up zip import, add cover images to course cards"
```

---

## Task 7: Simplify VocabularyListView and WordCardView

Remove level filter chips and level badges. Show a flat list of saved words.

**Files:**
- Modify: `App/lingQ/Vocabulary/VocabularyListView.swift`
- Modify: `App/lingQ/Vocabulary/WordCardView.swift`
- Modify: `App/lingQ/Theme/AppTheme.swift`

- [ ] **Step 1: Simplify VocabularyListView**

Remove `filterLevel` state, remove `FilterChip` section. Keep search, date grouping, and delete.

- [ ] **Step 2: Simplify WordCardView**

Remove level badge. Show: word, definition, context sentence, course source.

- [ ] **Step 3: Clean up AppTheme**

Remove `level1Color`, `level2Color`, `level3Color`, `newColor`. Keep `knownColor` for any remaining use.

- [ ] **Step 4: Update FlashcardReviewView description text**

Change "在精读模式中标记生词后" to "保存生词后" in the empty state.

- [ ] **Step 5: Commit**

```bash
git add App/lingQ/Vocabulary/ App/lingQ/Theme/ App/lingQ/Review/
git commit -m "refactor: simplify vocabulary UI, remove level system from views"
```

---

## Task 8: Delete intensive reading files and clean up

Remove all IntensiveReading files and the old ImportCourseSheet. Clean up any remaining references.

**Files:**
- Delete: `App/lingQ/IntensiveReading/IntensiveReadingView.swift`
- Delete: `App/lingQ/IntensiveReading/MiniPlayerView.swift`
- Delete: `App/lingQ/IntensiveReading/SentenceView.swift`
- Delete: `App/lingQ/IntensiveReading/TappableWordView.swift`
- Delete: `App/lingQ/IntensiveReading/WordLookupPopup.swift`
- Delete: `App/lingQ/Import/ImportCourseSheet.swift`

- [ ] **Step 1: Delete IntensiveReading directory**

```bash
rm -rf App/lingQ/IntensiveReading/
```

- [ ] **Step 2: Delete old ImportCourseSheet**

```bash
rm App/lingQ/Import/ImportCourseSheet.swift
```

- [ ] **Step 3: Remove references from Xcode project**

Open Xcode and remove the deleted files from the project navigator, or verify the project builds without them (if using folder references).

- [ ] **Step 4: Search for any remaining references**

Grep for `IntensiveReading`, `MiniPlayerView`, `SentenceView`, `TappableWordView`, `WordLookupPopup`, `ImportCourseSheet` across the project and remove any imports or references.

- [ ] **Step 5: Build the project**

Open in Xcode, build for iOS Simulator, fix any compilation errors.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: remove intensive reading mode and old import sheet"
```

---

## Task 9: Final integration test and polish

Verify the full flow works end-to-end.

- [ ] **Step 1: Test zip import**

Create a test zip with a cover.jpg, audio.mp3, and subtitle.srt. Import via the app. Verify course appears with cover image.

- [ ] **Step 2: Test playback page**

Open the imported course. Verify cover image displays, all playback controls work (play/pause, skip, speed, A-B repeat, prev/next sentence).

- [ ] **Step 3: Test immersive subtitle view**

Enter immersive view via "Subtitles" button. Verify:
- Current sentence highlights
- Other sentences are dimmed
- Controls auto-hide after 5s
- Tap to show/hide controls
- Tap a word → saves to vocabulary + shows dictionary

- [ ] **Step 4: Test vocabulary list**

Check saved words appear in vocabulary tab. Verify simplified UI (no level badges).

- [ ] **Step 5: Test flashcard review**

Verify saved words appear for review and SM-2 grading works.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete app redesign - zip import, simplified vocab, immersive word saving"
```
