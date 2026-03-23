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

                if recentCourses.isEmpty {
                    ImportPromptCard(onImportTap: onImportTap)
                }

                if !recentCourses.isEmpty {
                    SectionHeader("最近课程")
                    RecentCourseStrip(courses: recentCourses)
                }

                SectionHeader("学习概览")
                LearningSummaryCard(
                    dueReviewCount: dueReviewCount,
                    recentWordCount: recentNewWordCount,
                    listeningMinutes: totalListeningMinutes
                )

                if !recentCourses.isEmpty {
                    ImportPromptCard(onImportTap: onImportTap)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Playlist")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("导入", systemImage: "plus") {
                onImportTap()
            }
        }
    }
}
