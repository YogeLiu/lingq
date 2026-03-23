import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void

    var body: some View {
        EmptyStateCard(
            icon: "waveform.badge.plus",
            title: "还没有听力课程",
            message: "导入 ZIP 后，封面、音频和字幕会一起整理好，在首页和课程库直接继续播放。",
            actionTitle: "导入课程",
            action: onImport
        )
    }
}
