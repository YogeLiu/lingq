import SwiftUI

struct ReviewSummaryView: View {
    let totalReviewed: Int
    let againCount: Int
    let hardCount: Int
    let goodCount: Int
    let easyCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("今日复习完成")
                .font(.title2.bold())

            Text("共复习 \(totalReviewed) 个词汇")
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))

            VStack(spacing: 8) {
                summaryRow(title: "忘了", count: againCount, color: .red)
                summaryRow(title: "模糊", count: hardCount, color: .orange)
                summaryRow(title: "记得", count: goodCount, color: .green)
                summaryRow(title: "简单", count: easyCount, color: .blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Button("返回首页", action: onDone)
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func summaryRow(title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .bold()
        }
    }
}
