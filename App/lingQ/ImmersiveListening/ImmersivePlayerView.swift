import SwiftUI
import AudioPlayerKit

struct ImmersivePlayerView: View {
    @Bindable var player: AudioPlayer
    @Binding var mode: ImmersiveMode
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 进度条
            VStack(spacing: 4) {
                ProgressView(value: player.currentTime, total: max(player.duration, 1))
                    .tint(Color.accentColorColor)
                HStack {
                    Text(formatTime(player.currentTime))
                    Spacer()
                    Text(formatTime(player.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            // 控制按钮
            HStack(spacing: 20) {
                Button { player.skipBackward(10) } label: {
                    Image(systemName: "gobackward.10")
                }

                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                }

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(width: 64, height: 64)
                .background(Color.accentColorColor, in: Circle())
                .foregroundStyle(.white)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                }

                Button { player.skipForward(10) } label: {
                    Image(systemName: "goforward.10")
                }
            }
            .font(.title3)

            // 模式切换标签
            HStack(spacing: 32) {
                ForEach(ImmersiveMode.allCases, id: \.self) { m in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(m == mode ? Color.accentColor : .clear)
                            .frame(width: 4, height: 4)
                        Text(m.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(m == mode ? .primary : .secondary)
                    }
                    .onTapGesture { mode = m }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
