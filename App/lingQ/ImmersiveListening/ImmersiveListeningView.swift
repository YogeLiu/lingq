import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit
import UIKit

struct ImmersiveListeningView: View {
    let course: Course
    let cues: [SubtitleCue]
    let searcher: CueSearcher
    @Bindable var player: AudioPlayer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentIndex: Int?
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var feedbackDismissTask: Task<Void, Never>?
    @State private var savedWords: Set<String> = []
    @State private var abRepeatActive = false
    @State private var feedbackMessage: String?

    private let availableSpeeds: [Float] = [0.75, 1.0, 1.25]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color(red: 0.055, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                LyricsCanvasView(
                    cues: cues,
                    currentIndex: currentIndex,
                    currentTime: player.currentTime,
                    onCueTap: { cue in
                        player.seek(to: cue.startTime)
                        showControlsTemporarily()
                    },
                    savedWords: savedWords,
                    onWordLongPress: { word, contextSentence in
                        saveWordToDictionary(word: word, contextSentence: contextSentence)
                    }
                )
                .padding(.bottom, controlsVisible ? 160 : 60)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        controlsVisible.toggle()
                    }
                    if controlsVisible {
                        scheduleHideControls()
                    }
                }

                if controlsVisible {
                    ImmersivePlayerView(
                        player: player,
                        isABRepeatActive: $abRepeatActive,
                        availableSpeeds: availableSpeeds,
                        onPrevious: {
                            jumpToPreviousCue()
                        },
                        onNext: {
                            jumpToNextCue()
                        },
                        onSkipBackward: {
                            player.skipBackward(10)
                            showControlsTemporarily()
                        },
                        onSkipForward: {
                            player.skipForward(10)
                            showControlsTemporarily()
                        },
                        onToggleABRepeat: {
                            toggleABRepeat()
                            showControlsTemporarily()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                ImmersiveDismissPanArea {
                    dismiss()
                }
                .frame(
                    width: proxy.size.width / 2,
                    height: max(proxy.size.height - (controlsVisible ? 170 : 0), 0)
                )
                .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .topLeading) {
                if controlsVisible {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 12)
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
            .onChange(of: player.currentTime) { _, time in
                let nextIndex = searcher.index(at: time)
                guard nextIndex != currentIndex else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex = nextIndex
                }
            }
            .onAppear {
                currentIndex = searcher.index(at: player.currentTime)
                reloadSavedWords()
                scheduleHideControls()
            }
            .onDisappear {
                hideControlsTask?.cancel()
                feedbackDismissTask?.cancel()
            }
            .environment(\.colorScheme, .dark)
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

        guard let cue = searcher.cue(at: player.currentTime) else { return }
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

        feedbackMessage = wasAlreadySaved ? "“\(normalizedWord)” 已在词典中" : "已添加 “\(normalizedWord)” 到词典"
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

        guard cleaned.rangeOfCharacter(from: .letters) != nil else {
            return nil
        }

        return cleaned
    }

}

private struct ImmersiveDismissPanArea: UIViewRepresentable {
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
            let enoughLeftDistance = translation.x > 44 || velocity.x > 500
            let horizontalDominant = abs(translation.x) > abs(translation.y) * 1.35 || abs(velocity.x) > abs(velocity.y) * 1.35

            guard enoughLeftDistance, horizontalDominant else { return }
            onDismiss()
        }
    }
}
