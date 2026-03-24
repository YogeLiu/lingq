import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit
import UIKit

struct ImmersiveListeningView: View {
    let course: Course
    @Binding var isPresented: Bool

    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.modelContext) private var modelContext

    @State private var currentIndex: Int?
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var feedbackDismissTask: Task<Void, Never>?
    @State private var savedWords: Set<String> = []
    @State private var abRepeatActive = false
    @State private var feedbackMessage: String?

    private let availableSpeeds: [Float] = [0.75, 1.0, 1.25]

    private var player: AudioPlayer { playbackManager.player }
    private var cues: [SubtitleCue] { playbackManager.cues }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            LyricsCanvasView(
                cues: cues,
                currentIndex: currentIndex,
                currentTime: player.currentTime,
                onCueTap: { cue in
                    player.seek(to: cue.startTime)
                    showControlsTemporarily()
                },
                onBackgroundTap: {
                    toggleControls()
                },
                savedWords: savedWords,
                onWordLongPress: { word, contextSentence in
                    saveWordToDictionary(word: word, contextSentence: contextSentence)
                }
            )
            .padding(.bottom, controlsVisible ? 120 : 60)

            if controlsVisible {
                bottomControls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .leading) {
            ImmersiveDismissPanArea {
                isPresented = false
            }
            .frame(width: 44)
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .topLeading) {
            if controlsVisible {
                topBar
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.15), in: Capsule())
                    .padding(.top, controlsVisible ? 64 : 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .statusBarHidden(true)
        .onChange(of: player.currentTime) { _, time in
            let nextIndex = playbackManager.searcher?.index(at: time)
            guard nextIndex != currentIndex else { return }
            guard nextIndex != nil else { return }
            currentIndex = nextIndex
        }
        .onAppear {
            currentIndex = playbackManager.searcher?.index(at: player.currentTime)
            reloadSavedWords()
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
            feedbackDismissTask?.cancel()
            playbackManager.saveProgress()
        }
        .environment(\.colorScheme, .dark)
    }

    private var topBar: some View {
        HStack {
            BackButton { isPresented = false }

            Spacer()

            Text(course.title)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var bottomControls: some View {
        VStack(spacing: 8) {
            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))

                        Capsule()
                            .fill(.white)
                            .frame(width: max(proxy.size.width * progressFraction, 4))
                    }
                    .frame(height: 4)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let percent = min(max(gesture.location.x / proxy.size.width, 0), 1)
                                player.seek(to: progressTotal * percent)
                                showControlsTemporarily()
                            }
                    )
                }
                .frame(height: 22)

                HStack {
                    Text(formatTime(player.currentTime))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
            }

            // All controls in one row
            HStack(spacing: 0) {
                // Speed
                Menu {
                    ForEach(availableSpeeds, id: \.self) { rate in
                        Button(speedLabel(for: rate)) {
                            player.playbackRate = rate
                            showControlsTemporarily()
                        }
                    }
                } label: {
                    Text(speedLabel(for: player.playbackRate))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 44, height: 40)
                }

                Spacer()

                // Back 10s
                controlButton(systemImage: "gobackward.10") {
                    player.skipBackward(10)
                    showControlsTemporarily()
                }

                Spacer()

                // Play/Pause
                Button {
                    player.toggle()
                    showControlsTemporarily()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(.white, in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Forward 10s
                controlButton(systemImage: "goforward.10") {
                    player.skipForward(10)
                    showControlsTemporarily()
                }

                Spacer()

                // Loop
                Button {
                    toggleABRepeat()
                    showControlsTemporarily()
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(abRepeatActive ? .white : .white.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .background(abRepeatActive ? Color.accentColor : .white.opacity(0.15), in: Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func controlButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private var progressTotal: Double {
        let d = player.duration
        guard d.isFinite, d > 0 else { return 1 }
        return d
    }

    private var progressFraction: Double {
        let t = player.currentTime
        guard t.isFinite, progressTotal > 0 else { return 0 }
        return min(max(t / progressTotal, 0), 1)
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

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            controlsVisible.toggle()
        }
        if controlsVisible {
            scheduleHideControls()
        } else {
            hideControlsTask?.cancel()
        }
    }

    private func showControlsTemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            controlsVisible = true
        }
        scheduleHideControls()
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    controlsVisible = false
                }
            }
        }
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

    private func reloadSavedWords() {
        let descriptor = FetchDescriptor<Word>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let words = (try? modelContext.fetch(descriptor)) ?? []
        savedWords = Set(words.map { $0.text.lowercased() })
    }

    private func saveWordToDictionary(word: String, contextSentence: String) {
        guard let normalizedWord = normalizedLookupWord(from: word) else { return }
        let wasAlreadySaved = savedWords.contains(normalizedWord)
        if !wasAlreadySaved {
            let store = VocabularyStore(modelContext: modelContext)
            try? store.saveWord(normalizedWord, contextSentence: contextSentence, courseId: course.id)
            savedWords.insert(normalizedWord)
        }
        feedbackMessage = wasAlreadySaved ? "\u{201C}\(normalizedWord)\u{201D} 已在词典中" : "已添加 \u{201C}\(normalizedWord)\u{201D} 到词典"
        scheduleFeedbackDismissal()
        showControlsTemporarily()
    }

    private func scheduleFeedbackDismissal() {
        feedbackDismissTask?.cancel()
        feedbackDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    feedbackMessage = nil
                }
            }
        }
    }

    private func normalizedLookupWord(from rawWord: String) -> String? {
        let cleaned = rawWord
            .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines))
            .lowercased()
        guard cleaned.rangeOfCharacter(from: .letters) != nil else { return nil }
        return cleaned
    }
}

private struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(12)
                .background(.white.opacity(0.12), in: Circle())
        }
    }
}

struct ImmersiveDismissPanArea: UIViewRepresentable {
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDismiss = onDismiss
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = panGesture.velocity(in: panGesture.view)
            return velocity.x > 40 && abs(velocity.x) > abs(velocity.y) * 1.2
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .ended else { return }

            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            let enoughDistance = translation.x > 44 || velocity.x > 500
            let horizontalDominant = abs(translation.x) > abs(translation.y) * 1.35 || abs(velocity.x) > abs(velocity.y) * 1.35

            guard enoughDistance, horizontalDominant else { return }
            onDismiss()
        }
    }
}
