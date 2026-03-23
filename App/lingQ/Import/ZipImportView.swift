import SwiftUI
import SwiftData
import SharedModels
import UniformTypeIdentifiers

struct ZipImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showFileImporter = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importSuccessTitle: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.brandAccent.opacity(0.18), AppTheme.brandAccentMuted, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 184, height: 184)

                    Image(systemName: "doc.zipper")
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(AppTheme.brandAccent)
                }

                VStack(spacing: 10) {
                    Text("导入 ZIP 课程")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("选择一个 ZIP 文件，里面放入封面图片、音频和字幕。导入后会自动解压到 App 本地。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(alignment: .leading, spacing: 10) {
                    importRequirementRow(icon: "photo", text: "封面：jpg / png / webp，可选")
                    importRequirementRow(icon: "waveform", text: "音频：mp3 / m4a / wav / aac")
                    importRequirementRow(icon: "captions.bubble", text: "字幕：srt")
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Button {
                    showFileImporter = true
                } label: {
                    Label(isImporting ? "正在导入..." : "从文件中选择 ZIP", systemImage: "square.and.arrow.down")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandAccent)
                .disabled(isImporting)

                Spacer()
            }
            .padding(24)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false,
                onCompletion: handleFileSelection
            )
            .alert("导入失败", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
            .alert("导入成功", isPresented: Binding(
                get: { importSuccessTitle != nil },
                set: { if !$0 { importSuccessTitle = nil } }
            )) {
                Button("继续") {
                    dismiss()
                }
            } message: {
                Text(importSuccessTitle.map { "\($0) 已加入课程库。" } ?? "")
            }
        }
    }

    private func importRequirementRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.brandAccent)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            if !isUserCancelled(error) {
                importError = error.localizedDescription
            }

        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let imported = try ZipImporter.importZip(from: url)
                let course = Course(
                    title: imported.title,
                    audioFilePath: imported.audioFilePath,
                    subtitleFilePath: imported.subtitleFilePath,
                    coverImagePath: imported.coverImagePath
                )
                modelContext.insert(course)
                try modelContext.save()
                importSuccessTitle = imported.title
            } catch {
                importError = error.localizedDescription
            }

            isImporting = false
        }
    }

    private func isUserCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }
}
