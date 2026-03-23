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
                VStack {
                    EmptyStateView {
                        showZipImport = true
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
                            subtitle: "课程以 ZIP 包导入，封面、音频和字幕都会保存在本地。"
                        )

                        Button {
                            showZipImport = true
                        } label: {
                            HeroCard {
                                Text("导入新课程")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("选择一个 ZIP，系统会自动提取封面、音频和字幕。")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)

                                Label("开始导入", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.brandAccent, in: Capsule())
                                    .foregroundStyle(Color.white)
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
                                        deleteCourse(course)
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
                    showZipImport = true
                }
            }
        }
        .sheet(isPresented: $showZipImport) {
            ZipImportView()
        }
    }

    private func deleteCourse(_ course: Course) {
        ZipImporter.deleteCourseFiles(
            audioFilePath: course.audioFilePath,
            subtitleFilePath: course.subtitleFilePath,
            coverImagePath: course.coverImagePath
        )
        modelContext.delete(course)
    }
}
