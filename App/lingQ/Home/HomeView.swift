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
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(
                    "继续听",
                    eyebrow: "Listening",
                    subtitle: continueCourse == nil ? "先导入第一门课程，建立你的听力节奏。" : "从上次停下的位置继续，保持输入不中断。"
                )

                ContinueListeningCard(course: continueCourse)

                SectionHeader(
                    "最近课程",
                    subtitle: recentCourses.isEmpty ? "你的课程会出现在这里。" : "从最近导入或最近播放的课程中继续。"
                )

                RecentCourseStrip(courses: recentCourses)

                SectionHeader(
                    "今日学习",
                    subtitle: "听力、词汇和复习都围绕当前会话组织。"
                )

                LearningSummaryCard(
                    dueReviewCount: dueReviewCount,
                    recentWordCount: recentNewWordCount,
                    listeningMinutes: totalListeningMinutes
                )

                ImportPromptCard(onImportTap: onImportTap)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Playlist")
        .navigationBarTitleDisplayMode(.large)
    }
}
