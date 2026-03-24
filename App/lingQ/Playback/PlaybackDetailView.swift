import SwiftUI
import SharedModels
import SubtitleKit
import AudioPlayerKit
import UIKit

struct PlaybackDetailView: View {
    let course: Course

    @Environment(PlaybackManager.self) private var playbackManager

    @State private var abRepeatActive = false
    @State private var showImmersive = false

    private let availableSpeeds: [Float] = [0.75, 1.0, 1.25]

    private var player: AudioPlayer { playbackManager.player }
    private var cues: [SubtitleCue] { playbackManager.cues }

    var body: some View {
        Group {
            switch playbackManager.loadState {
            case .idle, .loading:
                ProgressView("正在载入课程")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                ContentUnavailableView {
                    Label("课程暂时无法打开", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重试") {
                        Task { await playbackManager.play(course: course) }
                    }
                }

            case .ready:
                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    coverImageSection
                        .padding(.horizontal, 20)

                    titleSection
                        .padding(.top, 12)

                    Spacer(minLength: 16)

                    controlsList

                    Spacer(minLength: 8)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await playbackManager.play(course: course)
        }
        .navigationDestination(isPresented: $showImmersive) {
            if playbackManager.searcher != nil {
                ImmersiveListeningView(
                    course: course,
                    isPresented: $showImmersive
                )
            }
        }
    }

    private var coverImageSection: some View {
        Group {
            if let coverURL = course.resolvedCoverImageURL,
               let coverImage = UIImage(contentsOfFile: coverURL.path) {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemFill))
                    .frame(height: 240)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text(course.title)
                .font(.title2.bold())
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.center)

            Text(subtitleSummary)
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var controlsList: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemFill))

                        Capsule()
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.22))
                            .frame(width: max(proxy.size.width * progressFraction, 4))
                    }
                    .frame(height: 6)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let percent = min(max(gesture.location.x / proxy.size.width, 0), 1)
                                player.seek(to: progressTotal * percent)
                            }
                    )
                }
                .frame(height: 28)

                HStack {
                    Text(formatTime(progressValue))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color(.secondaryLabel))
            }

            // Transport buttons
            HStack(spacing: 0) {
                transportButton(systemImage: "gobackward.10") { player.skipBackward(10) }
                Spacer()
                transportButton(systemImage: "backward.end.fill", action: jumpToPreviousCue)
                Spacer()

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.22), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()
                transportButton(systemImage: "forward.end.fill", action: jumpToNextCue)
                Spacer()
                transportButton(systemImage: "goforward.10") { player.skipForward(10) }
            }

            // Divider
            Divider()

            // Utility row: subtitle, speed, loop
            HStack(spacing: 0) {
                if !cues.isEmpty {
                    Button { showImmersive = true } label: {
                        utilityLabel(systemImage: "text.quote", title: "字幕")
                    }
                }

                Spacer()

                Menu {
                    ForEach(availableSpeeds, id: \.self) { rate in
                        Button(speedLabel(for: rate)) {
                            player.playbackRate = rate
                        }
                    }
                } label: {
                    utilityLabel(systemImage: "speedometer", title: speedLabel(for: player.playbackRate))
                }

                Spacer()

                Button {
                    toggleABRepeat()
                } label: {
                    utilityLabel(systemImage: "repeat", title: "循环", isActive: abRepeatActive)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func utilityLabel(systemImage: String, title: String, isActive: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(isActive ? Color.accentColor : Color(.secondaryLabel))
    }

    private func toggleABRepeat() {
        if abRepeatActive {
            player.loopRange = nil
            abRepeatActive = false
            return
        }
        guard let cue = playbackManager.searcher?.cue(at: player.currentTime) else { return }
        player.loopRange = cue.startTime...cue.endTime
        abRepeatActive = true
    }

    private func transportButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private var progressTotal: Double {
        let duration = player.duration
        guard duration.isFinite, duration > 0 else { return 1 }
        return duration
    }

    private var progressValue: Double {
        let time = player.currentTime
        guard time.isFinite else { return 0 }
        return min(max(time, 0), progressTotal)
    }

    private var progressFraction: Double {
        progressValue / progressTotal
    }

    private var subtitleSummary: String {
        if let lastPlayedAt = course.lastPlayedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "共 \(cues.count) 句 · 上次 \(formatter.localizedString(for: lastPlayedAt, relativeTo: Date()))"
        }
        return "共 \(cues.count) 句字幕"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func speedLabel(for rate: Float) -> String {
        if rate == Float(Int(rate)) { return "\(Int(rate))x" }
        return String(format: "%.2gx", Double(rate))
    }

    private func jumpToPreviousCue() {
        let currentTime = player.currentTime
        if let cue = cues.last(where: { $0.startTime < max(currentTime - 0.2, 0) }) {
            player.seek(to: cue.startTime)
        } else {
            player.seek(to: 0)
        }
    }

    private func jumpToNextCue() {
        let currentTime = player.currentTime
        if let cue = cues.first(where: { $0.startTime > currentTime + 0.2 }) {
            player.seek(to: cue.startTime)
        }
    }
}
