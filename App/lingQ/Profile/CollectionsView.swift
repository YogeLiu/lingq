import SwiftUI
import SwiftData
import SharedModels

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    var body: some View {
        Group {
            if courses.isEmpty {
                EmptyStateCard(
                    icon: "folder.badge.plus",
                    title: "还没有合集",
                    message: "导入课程后，可以在这里整理和管理内容。"
                )
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(courses) { course in
                        NavigationLink(value: course) {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppTheme.surfaceMuted)
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                        Image(systemName: "headphones")
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(1)

                                    if let lastPlayed = course.lastPlayedAt {
                                        Text(lastPlayed, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    } else {
                                        Text("尚未播放")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("我的合集")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Course.self) { course in
            PlaybackDetailView(course: course)
        }
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}
