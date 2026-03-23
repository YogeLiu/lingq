import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit

struct PlaybackDetailView: View {
    let course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var player = AudioPlayer()
    @State private var cues: [SubtitleCue] = []
    @State private var searcher: CueSearcher?
    @State private var audioResourceURL: URL?
    @State private var hasAudioSecurityScope = false
    @State private var loadState: LoadState = .idle
    @State private var showImmersive = false
    @State private var showReading = false

    private enum LoadState: Equatable {
        case idle, loading, ready, failed(String)
    }

    var body: some View {
        Group {
            switch loadState {
            case .idle, .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppTheme.brandAccent)
                    Text("正在载入课程")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                EmptyStateCard(
                    icon: "exclamationmark.triangle",
                    title: "课程暂时无法打开",
                    message: message,
                    actionTitle: "重试"
                ) {
                    Task { await loadContent() }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready:
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        artworkSection
                        titleSection
                        summarySection
                        playerControls
                        actionButtons
                    }
                    .padding(20)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
        .fullScreenCover(isPresented: $showImmersive) {
            if let searcher {
                ImmersiveListeningView(
                    course: course,
                    cues: cues,
                    searcher: searcher,
                    player: player
                )
            }
        }
        .navigationDestination(isPresented: $showReading) {
            IntensiveReadingView(course: course)
        }
        .onDisappear {
            course.playbackPosition = player.currentTime
            course.lastPlayedAt = Date()
            player.pause()
            if hasAudioSecurityScope, let audioResourceURL {
                audioResourceURL.stopAccessingSecurityScopedResource()
            }
            hasAudioSecurityScope = false
            audioResourceURL = nil
        }
    }

    // MARK: - Sections

    private var artworkSection: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(AppTheme.surfaceMuted)
            .frame(height: 200)
            .overlay {
                Image(systemName: "headphones")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textTertiary)
            }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(course.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitleSummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var summarySection: some View {
        HStack(spacing: 16) {
            MetricPill(label: "字幕", value: "\(cues.count) 句")
            MetricPill(label: "进度", value: formatTime(course.playbackPosition))
        }
        .frame(maxWidth: .infinity)
    }

    private var playerControls: some View {
        VStack(spacing: 12) {
            if loadState == .ready {
                ProgressView(value: progressValue, total: progressTotal)
                    .tint(AppTheme.brandAccent)

                HStack {
                    Text(formatTime(progressValue))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 24) {
                Button { player.skipBackward(10) } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                }

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(width: 64, height: 64)
                .background(AppTheme.brandAccent, in: Circle())
                .foregroundStyle(.white)

                Button { player.skipForward(10) } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showImmersive = true
            } label: {
                Label("沉浸字幕", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandAccent)

            Button {
                showReading = true
            } label: {
                Label("精读模式", systemImage: "book")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.brandAccent)
        }
    }

    // MARK: - Helpers

    private var subtitleSummary: String {
        if let lastPlayedAt = course.lastPlayedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "上次播放于 \(formatter.localizedString(for: lastPlayedAt, relativeTo: Date()))"
        }
        return "刚导入，准备开始第一遍输入"
    }

    private var progressTotal: TimeInterval {
        let duration = player.duration
        guard duration.isFinite, duration > 0 else { return 1 }
        return duration
    }

    private var progressValue: TimeInterval {
        let time = player.currentTime
        guard time.isFinite else { return 0 }
        return min(max(time, 0), progressTotal)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func loadContent() async {
        loadState = .loading
        do {
            let subtitleURL = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
            let hasSubtitleScope = subtitleURL.startAccessingSecurityScopedResource()
            defer { if hasSubtitleScope { subtitleURL.stopAccessingSecurityScopedResource() } }
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try BookmarkManager.resolveBookmark(course.audioBookmark)
            hasAudioSecurityScope = audioURL.startAccessingSecurityScopedResource()
            audioResourceURL = audioURL
            try player.load(url: audioURL)
            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }
            loadState = .ready
        } catch {
            loadState = .failed("文件读取失败，可能是导入文件已移动或权限失效。请确认源文件仍存在后重试。")
        }
    }
}

private struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
