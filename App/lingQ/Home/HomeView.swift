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

    private var recentNewWordCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return words.filter { $0.createdAt >= sevenDaysAgo }.count
    }

    private var totalListeningMinutes: Int {
        recentCourses.reduce(0) { partial, course in
            partial + Int(course.playbackPosition / 60)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ContinueListeningCard(course: continueCourse)

                if !recentCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            "最近课程",
                            eyebrow: "Library",
                            subtitle: "从封面直接回到最近加入和最近播放的内容。"
                        )
                        RecentCourseStrip(courses: recentCourses)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        "学习节奏",
                        eyebrow: "Progress",
                        subtitle: dueReviewCount == 0
                            ? "今天没有到期词，可以直接回到输入和收听。"
                            : "先清理待复习词，再继续保持听力输入。"
                    )
                    LearningSummaryCard(
                        dueReviewCount: dueReviewCount,
                        recentWordCount: recentNewWordCount,
                        listeningMinutes: totalListeningMinutes
                    )
                }

                if recentCourses.isEmpty {
                    ImportPromptCard(onImportTap: onImportTap)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            "导入新内容",
                            eyebrow: "Library",
                            subtitle: "继续补充新的课程包，首页和课程库会自动更新。"
                        )
                        ImportPromptCard(onImportTap: onImportTap)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
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
}
