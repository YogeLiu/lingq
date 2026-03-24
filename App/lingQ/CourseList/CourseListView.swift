import SwiftUI
import SwiftData
import SharedModels

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    @State private var showZipImport = false

    var body: some View {
        Group {
            if courses.isEmpty {
                ContentUnavailableView {
                    Label("还没有课程", systemImage: "waveform.badge.plus")
                } description: {
                    Text("导入 ZIP 后，课程会出现在这里")
                } actions: {
                    Button("导入课程") {
                        showZipImport = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(courses) { course in
                        NavigationLink(value: course) {
                            CourseCardView(course: course)
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("全部课程")
        .navigationDestination(for: Course.self) { course in
            PlaybackDetailView(course: course)
        }
        .toolbar {
            if !courses.isEmpty {
                Button("导入", systemImage: "plus") {
                    showZipImport = true
                }
            }
        }
        .sheet(isPresented: $showZipImport) {
            ZipImportView()
        }
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            let course = courses[index]
            ZipImporter.deleteCourseFiles(
                audioFilePath: course.audioFilePath,
                subtitleFilePath: course.subtitleFilePath,
                coverImagePath: course.coverImagePath
            )
            modelContext.delete(course)
        }
    }
}
