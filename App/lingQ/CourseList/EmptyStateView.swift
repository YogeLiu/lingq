import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void

    var body: some View {
        EmptyStateCard(
            icon: "waveform.badge.plus",
            title: "还没有听力课程",
            message: "导入音频和字幕后，从课程库管理内容，在首页直接继续播放。",
            actionTitle: "导入课程",
            action: onImport
        )
    }
}
