import SwiftUI

struct ImportPromptCard: View {
    let onImportTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("导入新课程")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("把封面、音频和字幕一次性带进来，课程库会自动整理成可离线继续播放的资料。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.brandAccent)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.brandAccentMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 8) {
                featureTag("封面")
                featureTag("音频")
                featureTag("字幕")
            }

            Button {
                onImportTap()
            } label: {
                HStack {
                    Text("从文件导入 ZIP")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(AppTheme.brandAccent, in: RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.borderSubtle.opacity(0.68), lineWidth: 1)
        }
    }

    private func featureTag(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.surface, in: Capsule())
    }
}
