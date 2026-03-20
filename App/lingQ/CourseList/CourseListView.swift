import SwiftUI
import SwiftData
import SharedModels

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    @State private var showAudioImporter = false
    @State private var showSubtitleImporter = false
    @State private var pendingAudioBookmark: Data?
    @State private var pendingAudioName: String?

    var body: some View {
        Group {
            if courses.isEmpty {
                EmptyStateView { showAudioImporter = true }
            } else {
                List {
                    ForEach(courses) { course in
                        NavigationLink(value: course) {
                            CourseCardView(course: course)
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("我的课程")
        .navigationDestination(for: Course.self) { course in
            IntensiveReadingView(course: course)
        }
        .toolbar {
            if !courses.isEmpty {
                Button("导入", systemImage: "plus") {
                    showAudioImporter = true
                }
            }
        }
        .fileImporter(isPresented: $showAudioImporter, allowedContentTypes: [.audio]) { result in
            handleAudioImport(result)
        }
        .fileImporter(isPresented: $showSubtitleImporter, allowedContentTypes: [.plainText]) { result in
            handleSubtitleImport(result)
        }
    }

    private func handleAudioImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            pendingAudioBookmark = try BookmarkManager.createBookmark(for: url)
            pendingAudioName = url.deletingPathExtension().lastPathComponent

            // Try to auto-find matching SRT file
            let srtURL = url.deletingPathExtension().appendingPathExtension("srt")
            if FileManager.default.fileExists(atPath: srtURL.path) {
                guard srtURL.startAccessingSecurityScopedResource() else {
                    showSubtitleImporter = true
                    return
                }
                defer { srtURL.stopAccessingSecurityScopedResource() }
                let srtBookmark = try BookmarkManager.createBookmark(for: srtURL)
                if let audioBookmark = pendingAudioBookmark, let title = pendingAudioName {
                    createCourse(audioBookmark: audioBookmark, subtitleBookmark: srtBookmark, title: title)
                }
            } else {
                showSubtitleImporter = true
            }
        } catch {
            print("[LingQ] Audio import failed: \(error)")
        }
    }

    private func handleSubtitleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result,
              let audioBookmark = pendingAudioBookmark,
              let name = pendingAudioName
        else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let srtBookmark = try BookmarkManager.createBookmark(for: url)
            createCourse(audioBookmark: audioBookmark, subtitleBookmark: srtBookmark, title: name)
        } catch {
            print("[LingQ] Subtitle import failed: \(error)")
        }
        pendingAudioBookmark = nil
        pendingAudioName = nil
    }

    private func createCourse(audioBookmark: Data, subtitleBookmark: Data, title: String) {
        let course = Course(title: title, audioBookmark: audioBookmark, subtitleBookmark: subtitleBookmark)
        modelContext.insert(course)
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}
