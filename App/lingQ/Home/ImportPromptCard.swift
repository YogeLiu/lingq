import SwiftUI

struct ImportPromptCard: View {
    let onImportTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                "导入听力课程",
                subtitle: "现在改成 ZIP 导入，一次带上封面、音频和字幕。"
            )

            HStack(spacing: 12) {
                Label("ZIP 资源包", systemImage: "doc.zipper")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                Label("本地解压", systemImage: "internaldrive")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Button {
                onImportTap()
            } label: {
                Label("导入课程", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandAccent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
    }
}
