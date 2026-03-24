import SwiftUI

struct LearningSummaryCard: View {
    let dueReviewCount: Int
    let recentWordCount: Int
    let listeningMinutes: Int

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                dueMetric
                newWordMetric
                listeningMetric
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    dueMetric
                    newWordMetric
                }

                listeningMetric
            }
        }
    }

    private var dueMetric: some View {
        SummaryMetricCard(
            title: "待复习",
            value: "\(dueReviewCount)",
            detail: dueReviewCount == 0 ? "今天暂时清空" : "今天该回顾的词",
            tint: AppTheme.warning,
            symbol: "clock.arrow.circlepath"
        )
    }

    private var newWordMetric: some View {
        SummaryMetricCard(
            title: "新词",
            value: "\(recentWordCount)",
            detail: recentWordCount == 0 ? "近 7 天还没新增" : "近 7 天新增",
            tint: AppTheme.brandAccent,
            symbol: "character.book.closed"
        )
    }

    private var listeningMetric: some View {
        SummaryMetricCard(
            title: "已听",
            value: "\(listeningMinutes)m",
            detail: listeningMinutes == 0 ? "从第一门课程开始" : "累计记录位置",
            tint: AppTheme.success,
            symbol: "waveform"
        )
    }
}

private struct SummaryMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous)
                .stroke(AppTheme.borderSubtle.opacity(0.68), lineWidth: 1)
        }
        .shadow(color: AppTheme.shadow, radius: 10, y: 6)
    }
}
