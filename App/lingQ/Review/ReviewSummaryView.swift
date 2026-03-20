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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("复习完成")
                .font(.title.bold())

            Text("共复习 \(totalReviewed) 个单词")
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                SummaryRow(title: "重来", count: againCount, color: .red)
                SummaryRow(title: "困难", count: hardCount, color: .orange)
                SummaryRow(title: "良好", count: goodCount, color: .green)
                SummaryRow(title: "简单", count: easyCount, color: .blue)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("完成", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SummaryRow: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .bold()
        }
    }
}
