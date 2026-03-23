import SwiftUI
import SwiftData
import VocabularyKit
import SharedModels

struct LearningView: View {
    let importRequestID: Int

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.nextReviewAt, order: .forward) private var words: [Word]

    private var dueCount: Int {
        words.filter(\.isDueForReview).count
    }

    private var dueWords: [Word] {
        Array(words.filter(\.isDueForReview).prefix(3))
    }

    private var newWords: [Word] {
        Array(words.sorted { $0.createdAt > $1.createdAt }.prefix(6))
    }

    private var groupedCourseWords: [(title: String, count: Int)] {
        Dictionary(grouping: words.compactMap { word -> String? in
            guard let courseId = word.courseId else { return nil }
            return courseLookup[courseId] ?? "未命名课程"
        }, by: { $0 })
        .map { ($0.key, $0.value.count) }
        .sorted { $0.count > $1.count }
        .prefix(4)
        .map { $0 }
    }

    private var courseLookup: [UUID: String] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.title) })
    }

    private var estimatedReviewMinutes: Int {
        max(1, Int(ceil(Double(dueCount) * 0.3)))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(
                    "学习",
                    eyebrow: "Practice",
                    subtitle: "把复习和词汇管理收拢到一个工作台里。"
                )

                NavigationLink {
                    FlashcardReviewView()
                } label: {
                    HeroCard {
                        Text("今日复习")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.brandAccentMuted)

                        Text("\(dueCount) 个待复习词")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(dueCount == 0 ? "今天可以继续输入，暂时没有到期词。" : "预计 \(estimatedReviewMinutes) 分钟内完成，先清掉到期词，再回到播放保持节奏。")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        Label("开始复习", systemImage: "rectangle.stack.badge.play")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.brandAccent, in: Capsule())
                            .foregroundStyle(Color.black)
                    }
                }
                .buttonStyle(.plain)

                if !dueWords.isEmpty {
                    SectionHeader("待复习预览", subtitle: "先看即将进入复习会话的词。")

                    LazyVStack(spacing: 12) {
                        ForEach(dueWords) { word in
                            WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                        }
                    }
                }

                SectionHeader("最近新增", subtitle: "刚从听力过程中捕获的词。")

                if newWords.isEmpty {
                    EmptyStateCard(
                        icon: "character.book.closed",
                        title: "还没有新增词",
                        message: "在播放或精读过程中点词标记后，这里会出现最近的新词。"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(newWords) { word in
                            WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                        }
                    }
                }

                if !groupedCourseWords.isEmpty {
                    SectionHeader("按课程整理", subtitle: "词汇还是要回到原始听力语境里。")

                    LazyVStack(spacing: 12) {
                        ForEach(groupedCourseWords, id: \.title) { group in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text("\(group.count) 个词来自这门课程")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .padding(16)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }

                NavigationLink("查看全部词汇") {
                    VocabularyListView()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.brandAccent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
