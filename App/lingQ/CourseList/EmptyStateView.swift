import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("暂无课程", systemImage: "square.and.arrow.down")
        } description: {
            Text("导入 MP3 音频和 SRT 字幕文件开始学习")
        } actions: {
            Button("导入文件", action: onImport)
                .buttonStyle(.borderedProminent)
        }
    }
}
