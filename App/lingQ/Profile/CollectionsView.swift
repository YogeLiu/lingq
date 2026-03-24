import SwiftUI
import SwiftData
import SharedModels

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    var body: some View {
        Group {
            if courses.isEmpty {
                ContentUnavailableView {
                    Label("还没有课程", systemImage: "folder.badge.plus")
                } description: {
                    Text("导入课程后，可以在这里整理和管理内容")
                }
            } else {
                List {
                    ForEach(courses) { course in
                        NavigationLink(value: course) {
                            HStack(spacing: 12) {
                                courseThumbnail(for: course)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.title)
                                        .font(.headline)
                                        .lineLimit(1)

                                    if let lastPlayed = course.lastPlayedAt {
                                        Text(lastPlayed, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(Color(.secondaryLabel))
                                    } else {
                                        Text("尚未播放")
                                            .font(.caption)
                                            .foregroundStyle(Color(.secondaryLabel))
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("收藏夹")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Course.self) { course in
            PlaybackDetailView(course: course)
        }
    }

    @ViewBuilder
    private func courseThumbnail(for course: Course) -> some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color(.systemFill))
                .overlay {
                    Image(systemName: "headphones")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
        }
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}
