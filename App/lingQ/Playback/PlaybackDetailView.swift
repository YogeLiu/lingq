import SwiftUI
import SharedModels
import SubtitleKit
import AudioPlayerKit
import UIKit

struct PlaybackDetailView: View {
    let course: Course

    @State private var player = AudioPlayer()
    @State private var cues: [SubtitleCue] = []
    @State private var searcher: CueSearcher?
    @State private var audioResourceURL: URL?
    @State private var hasAudioSecurityScope = false
    @State private var loadState: LoadState = .idle
    @State private var showImmersive = false
    @State private var abRepeatActive = false

    private let availableSpeeds: [Float] = [0.75, 1.0, 1.25]

    private enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
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
                        coverImageSection
                        titleSection
                        controlsSection
                    }
                    .padding(20)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
        .onDisappear {
            course.playbackPosition = player.currentTime
            course.lastPlayedAt = Date()
            player.pause()
            player.loopRange = nil
            if hasAudioSecurityScope, let audioResourceURL {
                audioResourceURL.stopAccessingSecurityScopedResource()
            }
            hasAudioSecurityScope = false
            audioResourceURL = nil
        }
    }

    private var coverImageSection: some View {
        Group {
            if let coverURL = course.resolvedCoverImageURL,
               let coverImage = UIImage(contentsOfFile: coverURL.path) {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.brandAccent.opacity(0.26), AppTheme.surfaceMuted, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "headphones")
                            .font(.system(size: 58, weight: .semibold))
                            .foregroundStyle(AppTheme.brandAccent)
                    }
            }
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

    private var controlsSection: some View {
        PlaybackControlCard(
            player: player,
            availableSpeeds: availableSpeeds,
            isLoopActive: abRepeatActive,
            onSubtitleTap: cues.isEmpty ? nil : { showImmersive = true },
            onPrevious: jumpToPreviousCue,
            onNext: jumpToNextCue,
            onSkipBackward: { player.skipBackward(10) },
            onSkipForward: { player.skipForward(10) },
            onToggleLoop: toggleABRepeat
        )
    }

    private var subtitleSummary: String {
        if let lastPlayedAt = course.lastPlayedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "共 \(cues.count) 句字幕，上次播放于 \(formatter.localizedString(for: lastPlayedAt, relativeTo: Date()))"
        }
        return "共 \(cues.count) 句字幕，刚导入，准备开始第一遍输入"
    }

    private func toggleABRepeat() {
        if abRepeatActive {
            player.loopRange = nil
            abRepeatActive = false
            return
        }

        guard let cue = searcher?.cue(at: player.currentTime) else { return }
        player.loopRange = cue.startTime...cue.endTime
        abRepeatActive = true
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

    private func loadContent() async {
        loadState = .loading
        do {
            let subtitleURL = try resolveSubtitleURL()
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try resolveAudioURL()
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

    private func resolveSubtitleURL() throws -> URL {
        if let resolvedSubtitleURL = course.resolvedSubtitleURL,
           FileManager.default.fileExists(atPath: resolvedSubtitleURL.path) {
            return resolvedSubtitleURL
        }

        let url = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
        let hasScope = url.startAccessingSecurityScopedResource()
        defer {
            if hasScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return url
    }

    private func resolveAudioURL() throws -> URL {
        if let resolvedAudioURL = course.resolvedAudioURL,
           FileManager.default.fileExists(atPath: resolvedAudioURL.path) {
            hasAudioSecurityScope = false
            return resolvedAudioURL
        }

        let url = try BookmarkManager.resolveBookmark(course.audioBookmark)
        hasAudioSecurityScope = url.startAccessingSecurityScopedResource()
        return url
    }
}
