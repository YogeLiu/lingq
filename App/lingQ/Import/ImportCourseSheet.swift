import SwiftUI

struct ImportCourseSheet: View {
    let audioFilename: String?
    let subtitleFilename: String?
    let isAutoMatchedSubtitle: Bool
    let canFinish: Bool
    let isImporting: Bool
    let onSelectAudio: () -> Void
    let onSelectSubtitle: () -> Void
    let onFinish: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("先选音频，再确认字幕。完成后课程立即可用。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(spacing: 14) {
                        ImportStepCard(
                            index: 1,
                            title: "选择音频",
                            detail: audioFilename ?? "选择一段要练习的音频文件。",
                            buttonTitle: audioFilename == nil ? "选择音频文件" : "重新选择",
                            accent: AppTheme.brandAccent,
                            statusText: audioFilename == nil ? "等待选择" : "已选择",
                            action: onSelectAudio
                        )

                        ImportStepCard(
                            index: 2,
                            title: "确认字幕",
                            detail: subtitleDetail,
                            buttonTitle: subtitleFilename == nil ? "选择字幕文件" : "重新选择",
                            accent: isAutoMatchedSubtitle ? AppTheme.success : AppTheme.brandAccent,
                            statusText: subtitleStatusText,
                            action: onSelectSubtitle
                        )
                        .disabled(audioFilename == nil)
                        .opacity(audioFilename == nil ? 0.5 : 1)
                    }

                    Button {
                        onFinish()
                    } label: {
                        Label(isImporting ? "正在导入..." : "完成导入", systemImage: "checkmark.circle.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.brandAccent)
                    .disabled(!canFinish || isImporting)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("导入课程")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var subtitleStatusText: String {
        if isAutoMatchedSubtitle, subtitleFilename != nil {
            return "已自动匹配"
        }
        if subtitleFilename != nil {
            return "已选择"
        }
        return "等待选择"
    }

    private var subtitleDetail: String {
        if let subtitleFilename {
            if isAutoMatchedSubtitle {
                return "已自动匹配同名字幕：\(subtitleFilename)"
            }
            return "已手动选择字幕：\(subtitleFilename)"
        }
        return "优先尝试同名自动匹配；若未命中，再手动选择。"
    }
}

private struct ImportStepCard: View {
    let index: Int
    let title: String
    let detail: String
    let buttonTitle: String
    let accent: Color
    let statusText: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(accent, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }

            Button(buttonTitle, action: action)
                .buttonStyle(.bordered)
                .tint(accent)
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }
}
