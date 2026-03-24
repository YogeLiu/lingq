import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.lastPlayedAt, order: .reverse) private var recentlyPlayedCourses: [Course]
    @Query(sort: \Course.createdAt, order: .reverse) private var recentCourses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]

    let onImportTap: () -> Void

    private var continueCourse: Course? {
        recentlyPlayedCourses.first(where: { $0.lastPlayedAt != nil }) ?? recentCourses.first
    }

    private var dueReviewCount: Int {
        words.filter(\.isDueForReview).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero card
                ContinueListeningCard(course: continueCourse, onImportTap: onImportTap)
                    .padding(.horizontal, 16)

                if !recentCourses.isEmpty {
                    recentCoursesSection
                }

                quickActionsSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("导入", systemImage: "plus") {
                    onImportTap()
                }
            }
        }
    }

    private var recentCoursesSection: some View {
        List {
            Section("最近课程") {
                ForEach(recentCourses.prefix(5)) { course in
                    NavigationLink(value: course) {
                        HStack(spacing: 12) {
                            coverThumbnail(for: course)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.title)
                                    .font(.headline)
                                    .lineLimit(1)

                                if let lastPlayed = course.lastPlayedAt {
                                    Text("上次播放 \(lastPlayed, format: .dateTime.month().day().hour().minute())")
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
            }
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
        .frame(height: CGFloat(min(recentCourses.count, 5)) * 76 + 56)
    }

    private var quickActionsSection: some View {
        List {
            Section {
                HStack {
                    Label("词汇复习", systemImage: "rectangle.stack.badge.play")
                    Spacer()
                    if dueReviewCount > 0 {
                        Text("\(dueReviewCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                    }
                }

                Button {
                    onImportTap()
                } label: {
                    Label("导入课程", systemImage: "square.and.arrow.down")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
        .frame(height: 132)
    }

    @ViewBuilder
    private func coverThumbnail(for course: Course) -> some View {
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
}
