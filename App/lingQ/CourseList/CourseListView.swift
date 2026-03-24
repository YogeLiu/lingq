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
                            subtitle: courses.count == 1
                                ? "目前有 1 门本地课程，封面、音频和字幕都会保存在设备里。"
                                : "目前有 \(courses.count) 门本地课程，封面、音频和字幕都会保存在设备里。"
                        )

                        Button {
                            showZipImport = true
                        } label: {
                            HeroCard {
                                HStack(alignment: .top, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("导入新课程")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(AppTheme.textPrimary)

                                        Text("选择一个 ZIP，系统会自动提取封面、音频和字幕，并整理进本地课程库。")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()

                                    Image(systemName: "square.and.arrow.down.on.square.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(AppTheme.brandAccent)
                                        .frame(width: 48, height: 48)
                                        .background(AppTheme.brandAccentMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }

                                HStack(spacing: 8) {
                                    featureTag("ZIP")
                                    featureTag("自动解压")
                                    featureTag("离线收听")
                                }

                                HStack {
                                    Text("开始导入")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.brandAccent)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
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

    private func featureTag(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.surfaceMuted, in: Capsule())
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
