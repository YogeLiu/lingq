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
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "doc.zipper")
                    .font(.system(size: 56))
                    .foregroundStyle(Color(.tertiaryLabel))

                VStack(spacing: 8) {
                    Text("导入课程")
                        .font(.headline)

                    Text("选择一个 ZIP 文件，包含音频和字幕。封面图片可选。")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label(isImporting ? "正在导入..." : "选择文件", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
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
                Button("继续") { dismiss() }
            } message: {
                Text(importSuccessTitle.map { "\($0) 已加入课程库。" } ?? "")
            }
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
                if hasAccess { url.stopAccessingSecurityScopedResource() }
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
