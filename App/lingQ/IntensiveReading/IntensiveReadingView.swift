import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit

struct IntensiveReadingView: View {
    let course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var player = AudioPlayer()
    @State private var cues: [SubtitleCue] = []
    @State private var searcher: CueSearcher?
    @State private var selectedWord: String?
    @State private var showLookup = false
    @Query private var words: [Word]

    private var wordLevels: [String: WordLevel] {
        Dictionary(uniqueKeysWithValues: words.map { ($0.text, $0.level) })
    }

    private var currentCueIndex: Int? {
        searcher?.index(at: player.currentTime)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cues) { cue in
                            SentenceView(
                                cue: cue,
                                isCurrentlyPlaying: searcher?.cue(at: player.currentTime)?.id == cue.id,
                                wordLevels: wordLevels,
                                onWordTap: { word in
                                    selectedWord = word
                                    showLookup = true
                                }
                            )
                            .id(cue.id)
                            .onTapGesture {
                                player.seek(to: cue.startTime)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .onChange(of: currentCueIndex) { _, newIndex in
                    if let newIndex, !cues.isEmpty, newIndex < cues.count {
                        withAnimation {
                            proxy.scrollTo(cues[newIndex].id, anchor: .center)
                        }
                    }
                }
            }

            MiniPlayerView(
                player: player,
                onPrevious: {
                    if let prev = searcher?.previousCue(before: player.currentTime) {
                        player.seek(to: prev.startTime)
                    }
                },
                onNext: {
                    if let next = searcher?.nextCue(after: player.currentTime) {
                        player.seek(to: next.startTime)
                    }
                }
            )
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLookup) {
            if let word = selectedWord {
                // TODO: Task 10 - WordLookupPopup
                Text("Looking up: \(word)")
                    .presentationDetents([.medium])
            }
        }
        .task {
            await loadContent()
        }
        .onDisappear {
            course.playbackPosition = player.currentTime
            course.lastPlayedAt = Date()
            player.pause()
        }
    }

    private func loadContent() async {
        do {
            let subtitleURL = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try BookmarkManager.resolveBookmark(course.audioBookmark)
            try player.load(url: audioURL)
            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }
        } catch {
            print("[LingQ] Failed to load course content: \(error)")
        }
    }
}
