import SwiftUI

struct LearningSummaryCard: View {
    let dueReviewCount: Int
    let recentWordCount: Int
    let listeningMinutes: Int

    var body: some View {
        HStack(spacing: 12) {
            SummaryMetricCard(title: "待复习", value: "\(dueReviewCount)", detail: "今天该回顾的词", tint: AppTheme.warning)
            SummaryMetricCard(title: "新词", value: "\(recentWordCount)", detail: "近 7 天新增", tint: AppTheme.brandAccent)
            SummaryMetricCard(title: "已听", value: "\(listeningMinutes)m", detail: "累计记录位置", tint: AppTheme.success)
        }
    }
}

private struct SummaryMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }
}
