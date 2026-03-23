import SwiftUI
import SwiftData
import SharedModels
import UniformTypeIdentifiers
import OSLog

struct CourseListView: View {
    private let logger = Logger(subsystem: "com.lingq.lingQ", category: "CourseImport")
    let importRequestID: Int

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    @State private var showImporter = false
    @State private var showImportSheet = false
    @State private var importStep: ImportStep = .audio
    @State private var pendingAudioBookmark: Data?
    @State private var pendingSubtitleBookmark: Data?
    @State private var pendingAudioName: String?
    @State private var selectedAudioFilename: String?
    @State private var selectedSubtitleFilename: String?
    @State private var subtitleWasAutoMatched = false
    @State private var importError: String?
    @State private var importSuccessTitle: String?

    private enum ImportStep {
        case audio
        case subtitle
    }

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    var body: some View {
        Group {
            if courses.isEmpty {
                VStack {
                    EmptyStateView {
                        logger.info("Import tapped from empty state")
                        presentImportSheet()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .background(AppTheme.background.ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionHeader(
                            "课程库",
                            eyebrow: "Library",
                            subtitle: "管理听力内容，从任一课程恢复播放。"
                        )

                        Button {
                            logger.info("Import tapped from library hero")
                            presentImportSheet()
                        } label: {
                            HeroCard {
                                Text("导入新课程")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("选择音频后，系统会先尝试自动匹配同名字幕。")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)

                                Label("开始导入", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.brandAccent, in: Capsule())
                                    .foregroundStyle(Color.black)
                            }
                        }
                        .buttonStyle(.plain)

                        LazyVStack(spacing: 14) {
                            ForEach(courses) { course in
                                NavigationLink(value: course) {
                                    CourseCardView(course: course)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(course)
                                    } label: {
                                        Label("删除课程", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
        .navigationTitle("课程")
        .navigationDestination(for: Course.self) { course in
            PlaybackDetailView(course: course)
        }
        .toolbar {
            if !courses.isEmpty {
                Button("导入", systemImage: "plus") {
                    logger.info("Import tapped from toolbar")
                    presentImportSheet()
                }
            }
        }
        .onChange(of: importRequestID) { _, _ in
            if importRequestID > 0 {
                logger.info("Import requested from external navigation")
                presentImportSheet()
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportCourseSheet(
                audioFilename: selectedAudioFilename,
                subtitleFilename: selectedSubtitleFilename,
                isAutoMatchedSubtitle: subtitleWasAutoMatched,
                canFinish: pendingAudioBookmark != nil && pendingSubtitleBookmark != nil && pendingAudioName != nil,
                isImporting: false,
                onSelectAudio: {
                    presentAudioImporter()
                },
                onSelectSubtitle: {
                    importStep = .subtitle
                    showImporter = true
                },
                onFinish: {
                    finishImport()
                }
            )
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: importStep == .subtitle ? subtitleContentTypes : [.audio]
        ) { result in
            logger.info("fileImporter completed for step: \(self.importStep == .audio ? "audio" : "subtitle", privacy: .public)")

            switch importStep {
            case .audio:
                handleAudioImport(result)
            case .subtitle:
                handleSubtitleImport(result)
            }
        }
        .alert("导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .alert("导入完成", isPresented: Binding(
            get: { importSuccessTitle != nil },
            set: { if !$0 { importSuccessTitle = nil } }
        )) {
            Button("继续") {}
        } message: {
            Text(importSuccessTitle.map { "\($0) 已加入课程库，并会出现在首页继续播放。" } ?? "")
        }
    }

    private func handleAudioImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            logger.error("Audio import failed before selection completed: \(error.localizedDescription)")
            if !isUserCancelled(error) {
                importError = error.localizedDescription
            }
            return
        case .success(let url):
            logger.info("Audio selected: \(url.lastPathComponent, privacy: .public)")
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                pendingAudioBookmark = try BookmarkManager.createBookmark(for: url)
                pendingAudioName = url.deletingPathExtension().lastPathComponent
                selectedAudioFilename = url.lastPathComponent
                pendingSubtitleBookmark = nil
                selectedSubtitleFilename = nil
                subtitleWasAutoMatched = false
                logger.info("Audio bookmark created for title: \(self.pendingAudioName ?? "-", privacy: .public)")
            } catch {
                logger.error("Audio bookmark creation failed: \(error.localizedDescription)")
                importError = "音频书签创建失败：\(error.localizedDescription)"
                return
            }

            // Try to auto-find matching SRT file
            let srtURL = url.deletingPathExtension().appendingPathExtension("srt")
            logger.info("Trying auto-match subtitle: \(srtURL.lastPathComponent, privacy: .public)")
            if FileManager.default.fileExists(atPath: srtURL.path),
               srtURL.startAccessingSecurityScopedResource() {
                defer { srtURL.stopAccessingSecurityScopedResource() }
                if let srtBookmark = try? BookmarkManager.createBookmark(for: srtURL),
                   pendingAudioBookmark != nil,
                   pendingAudioName != nil {
                    logger.info("Auto-matched subtitle succeeded: \(srtURL.lastPathComponent, privacy: .public)")
                    pendingSubtitleBookmark = srtBookmark
                    selectedSubtitleFilename = srtURL.lastPathComponent
                    subtitleWasAutoMatched = true
                    return
                }
                logger.error("Auto-matched subtitle exists but bookmark creation failed")
            }

            // No matching SRT found — show subtitle picker after picker fully dismisses
            logger.info("No usable auto-matched subtitle, presenting subtitle picker")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                logger.info("Subtitle picker presented")
                importStep = .subtitle
                showImporter = true
            }
        }
    }

    private func handleSubtitleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            logger.error("Subtitle import failed before selection completed: \(error.localizedDescription)")
            if !isUserCancelled(error) {
                importError = error.localizedDescription
            }
            return
        case .success(let url):
            logger.info("Subtitle selected: \(url.lastPathComponent, privacy: .public)")
            guard pendingAudioBookmark != nil, pendingAudioName != nil else { return }

            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                pendingSubtitleBookmark = try BookmarkManager.createBookmark(for: url)
                selectedSubtitleFilename = url.lastPathComponent
                subtitleWasAutoMatched = false
                logger.info("Subtitle bookmark created and stored for pending course")
            } catch {
                logger.error("Subtitle bookmark creation failed: \(error.localizedDescription)")
                importError = "字幕书签创建失败：\(error.localizedDescription)"
            }
        }
    }

    private func createCourse(audioBookmark: Data, subtitleBookmark: Data, title: String) {
        logger.info("Inserting course: \(title, privacy: .public)")
        let course = Course(title: title, audioBookmark: audioBookmark, subtitleBookmark: subtitleBookmark)
        modelContext.insert(course)
    }

    private var subtitleContentTypes: [UTType] {
        var types: [UTType] = [.plainText]
        if let srtType = UTType(filenameExtension: "srt") {
            types.insert(srtType, at: 0)
        }
        return types
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }

    private func presentAudioImporter() {
        importStep = .audio
        showImporter = true
    }

    private func presentImportSheet() {
        clearPendingImportState()
        showImportSheet = true
    }

    private func finishImport() {
        guard let audioBookmark = pendingAudioBookmark,
              let subtitleBookmark = pendingSubtitleBookmark,
              let title = pendingAudioName else { return }

        createCourse(audioBookmark: audioBookmark, subtitleBookmark: subtitleBookmark, title: title)
        importSuccessTitle = title
        showImportSheet = false
        clearPendingImportState()
    }

    private func clearPendingImportState() {
        pendingAudioBookmark = nil
        pendingSubtitleBookmark = nil
        pendingAudioName = nil
        selectedAudioFilename = nil
        selectedSubtitleFilename = nil
        subtitleWasAutoMatched = false
    }

    private func isUserCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }
}
