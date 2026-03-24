# Global Playback & Mini Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make audio playback persist across navigation, play in background, show Now Playing info on lock screen, and display a mini player bar above the tab bar.

**Architecture:** A shared `PlaybackManager` (`@Observable`) created at the app's `ContentView` level and injected via `@Environment`. It owns the `AudioPlayer`, manages course loading/resource lifecycle, auto-saves progress, and drives both the `MiniPlayerBar` and `NowPlayingManager`. Existing views (`PlaybackDetailView`, `ImmersiveListeningView`) are refactored to consume the shared manager instead of creating local players.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation, MediaPlayer (MPNowPlayingInfoCenter, MPRemoteCommandCenter), AudioPlayerKit (existing package)

**Spec:** `docs/superpowers/specs/2026-03-24-global-playback-design.md`

---

### Task 1: Add background audio capability to Info.plist

**Files:**
- Modify: `App/lingQ/Info.plist`

- [ ] **Step 1: Add UIBackgroundModes array with audio**

Add the following key-value pair inside the root `<dict>` in `App/lingQ/Info.plist`, before the closing `</dict>`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

- [ ] **Step 2: Commit**

```bash
git add App/lingQ/Info.plist
git commit -m "feat: enable background audio capability"
```

---

### Task 2: Create PlaybackManager

**Files:**
- Create: `App/lingQ/Playback/PlaybackManager.swift`

This is the central piece. It holds the shared `AudioPlayer`, tracks the current `Course`, handles resource loading/cleanup, and auto-saves progress.

- [ ] **Step 1: Create PlaybackManager.swift**

```swift
import Foundation
import Observation
import SharedModels
import SubtitleKit
import AudioPlayerKit
import UIKit

@MainActor
@Observable
final class PlaybackManager {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    let player = AudioPlayer()
    private(set) var currentCourse: Course?
    private(set) var cues: [SubtitleCue] = []
    private(set) var searcher: CueSearcher?
    private(set) var loadState: LoadState = .idle

    private var audioResourceURL: URL?
    private var hasAudioSecurityScope = false
    private var progressTimer: Timer?

    func play(course: Course) async {
        if currentCourse?.id == course.id {
            if loadState == .ready, !player.isPlaying {
                player.play()
            }
            return
        }

        // Save progress of previous course and release resources
        saveProgress()
        releaseResources()

        currentCourse = course
        loadState = .loading

        do {
            let subtitleURL = try resolveSubtitleURL(for: course)
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try resolveAudioURL(for: course)
            audioResourceURL = audioURL
            try player.load(url: audioURL)

            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }

            player.play()
            loadState = .ready
            startProgressTimer()
        } catch {
            loadState = .failed("文件读取失败，可能是导入文件已移动或权限失效。请确认源文件仍存在后重试。")
        }
    }

    func stop() {
        saveProgress()
        player.pause()
        player.loopRange = nil
        releaseResources()
        currentCourse = nil
        cues = []
        searcher = nil
        loadState = .idle
        stopProgressTimer()
    }

    func saveProgress() {
        guard let currentCourse, loadState == .ready else { return }
        currentCourse.playbackPosition = player.currentTime
        currentCourse.lastPlayedAt = Date()
    }

    // MARK: - Resource Management

    private func releaseResources() {
        if hasAudioSecurityScope, let audioResourceURL {
            audioResourceURL.stopAccessingSecurityScopedResource()
        }
        hasAudioSecurityScope = false
        audioResourceURL = nil
    }

    private func resolveSubtitleURL(for course: Course) throws -> URL {
        if let resolvedSubtitleURL = course.resolvedSubtitleURL,
           FileManager.default.fileExists(atPath: resolvedSubtitleURL.path) {
            return resolvedSubtitleURL
        }
        let url = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
        let hasScope = url.startAccessingSecurityScopedResource()
        defer { if hasScope { url.stopAccessingSecurityScopedResource() } }
        return url
    }

    private func resolveAudioURL(for course: Course) throws -> URL {
        if let resolvedAudioURL = course.resolvedAudioURL,
           FileManager.default.fileExists(atPath: resolvedAudioURL.path) {
            hasAudioSecurityScope = false
            return resolvedAudioURL
        }
        let url = try BookmarkManager.resolveBookmark(course.audioBookmark)
        hasAudioSecurityScope = url.startAccessingSecurityScopedResource()
        return url
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

Add `PlaybackManager.swift` to the `lingQ.xcodeproj/project.pbxproj` under the Playback group, same pattern as existing files.

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/Playback/PlaybackManager.swift lingQ.xcodeproj/project.pbxproj
git commit -m "feat: add PlaybackManager as global playback state"
```

---

### Task 3: Create NowPlayingManager

**Files:**
- Create: `App/lingQ/Playback/NowPlayingManager.swift`

Handles `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` integration.

- [ ] **Step 1: Create NowPlayingManager.swift**

```swift
import Foundation
import MediaPlayer
import SharedModels
import AudioPlayerKit
import UIKit

@MainActor
enum NowPlayingManager {

    static func configure(player: AudioPlayer) {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.removeTarget(nil)
        center.playCommand.addTarget { _ in
            Task { @MainActor in player.play() }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.removeTarget(nil)
        center.pauseCommand.addTarget { _ in
            Task { @MainActor in player.pause() }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in player.toggle() }
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.removeTarget(nil)
        center.skipForwardCommand.addTarget { _ in
            Task { @MainActor in player.skipForward(10) }
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.removeTarget(nil)
        center.skipBackwardCommand.addTarget { _ in
            Task { @MainActor in player.skipBackward(10) }
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.addTarget { event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in player.seek(to: posEvent.positionTime) }
            return .success
        }
    }

    static func update(course: Course, player: AudioPlayer) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: course.title,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? Double(player.playbackRate) : 0.0
        ]

        if let coverURL = course.resolvedCoverImageURL,
           let image = UIImage(contentsOfFile: coverURL.path) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    static func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

Add `NowPlayingManager.swift` to the `lingQ.xcodeproj/project.pbxproj` under the Playback group.

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/Playback/NowPlayingManager.swift lingQ.xcodeproj/project.pbxproj
git commit -m "feat: add NowPlayingManager for lock screen controls"
```

---

### Task 4: Integrate NowPlayingManager into PlaybackManager

**Files:**
- Modify: `App/lingQ/Playback/PlaybackManager.swift`

Wire up Now Playing updates so lock screen and control center reflect current playback state.

- [ ] **Step 1: Add Now Playing calls to PlaybackManager**

In `PlaybackManager.play(course:)`, after `loadState = .ready` and before `startProgressTimer()`:

```swift
NowPlayingManager.configure(player: player)
NowPlayingManager.update(course: course, player: player)
```

In `PlaybackManager.stop()`, after `player.pause()`:

```swift
NowPlayingManager.clear()
```

In `PlaybackManager.saveProgress()`, add Now Playing time update at the end:

```swift
if let currentCourse {
    NowPlayingManager.update(course: currentCourse, player: player)
}
```

Also add a `setupNowPlayingTimer()` approach — the existing progress timer (10s) is too slow for lock screen elapsed time. Instead, add an observation approach. Add to the end of `play(course:)` after `startProgressTimer()`:

```swift
startNowPlayingUpdater()
```

Add these methods:

```swift
private var nowPlayingTimer: Timer?

private func startNowPlayingUpdater() {
    stopNowPlayingUpdater()
    nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            guard let self, let course = self.currentCourse, self.loadState == .ready else { return }
            NowPlayingManager.update(course: course, player: self.player)
        }
    }
}

private func stopNowPlayingUpdater() {
    nowPlayingTimer?.invalidate()
    nowPlayingTimer = nil
}
```

In `stop()`, add `stopNowPlayingUpdater()` before `NowPlayingManager.clear()`.

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add App/lingQ/Playback/PlaybackManager.swift
git commit -m "feat: integrate Now Playing info with PlaybackManager"
```

---

### Task 5: Create MiniPlayerBar

**Files:**
- Create: `App/lingQ/Playback/MiniPlayerBar.swift`

A compact bar showing course title, play/pause button, and a progress indicator. Tapping it triggers navigation to the PlaybackDetailView.

- [ ] **Step 1: Create MiniPlayerBar.swift**

```swift
import SwiftUI
import SharedModels
import UIKit

struct MiniPlayerBar: View {
    let playbackManager: PlaybackManager
    let onTap: () -> Void

    var body: some View {
        if let course = playbackManager.currentCourse, playbackManager.loadState == .ready {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    coverThumbnail(for: course)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text(course.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)

                    Spacer()

                    Button {
                        playbackManager.player.toggle()
                    } label: {
                        Image(systemName: playbackManager.player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    VStack(spacing: 0) {
                        // Progress line at top
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: proxy.size.width * progressFraction)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 2)

                        Spacer()
                    }
                }
                .background(.ultraThinMaterial)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var progressFraction: Double {
        let duration = playbackManager.player.duration
        let time = playbackManager.player.currentTime
        guard duration.isFinite, duration > 0, time.isFinite else { return 0 }
        return min(max(time / duration, 0), 1)
    }

    @ViewBuilder
    private func coverThumbnail(for course: Course) -> some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.systemFill))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
        }
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

Add `MiniPlayerBar.swift` to `lingQ.xcodeproj/project.pbxproj` under the Playback group.

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/Playback/MiniPlayerBar.swift lingQ.xcodeproj/project.pbxproj
git commit -m "feat: add MiniPlayerBar component"
```

---

### Task 6: Wire up ContentView with PlaybackManager and MiniPlayerBar

**Files:**
- Modify: `App/lingQ/ContentView.swift`

Create PlaybackManager at this level, inject into environment, add MiniPlayerBar, add navigation for mini player tap, save progress on background.

- [ ] **Step 1: Rewrite ContentView.swift**

```swift
import SwiftUI
import SharedModels

struct ContentView: View {
    private enum TabSelection: Hashable {
        case playlist
        case vocabulary
        case review
        case me
    }

    @State private var selectedTab: TabSelection = .playlist
    @State private var importRequestID = 0
    @State private var playbackManager = PlaybackManager()
    @State private var navigateToPlayback: Course?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("首页", systemImage: "house.fill", value: .playlist) {
                NavigationStack {
                    HomeView {
                        selectedTab = .me
                        importRequestID += 1
                    }
                    .navigationDestination(for: Course.self) { course in
                        PlaybackDetailView(course: course)
                    }
                }
            }

            Tab("词汇", systemImage: "character.book.closed.fill", value: .vocabulary) {
                NavigationStack {
                    VocabularyListView()
                }
            }

            Tab("复习", systemImage: "rectangle.stack.badge.play", value: .review) {
                NavigationStack {
                    FlashcardReviewView()
                }
            }

            Tab("我的", systemImage: "person.crop.circle", value: .me) {
                NavigationStack {
                    MeView(importRequestID: importRequestID)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            MiniPlayerBar(playbackManager: playbackManager) {
                if let course = playbackManager.currentCourse {
                    navigateToPlayback = course
                    selectedTab = .playlist
                }
            }
        }
        .environment(playbackManager)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                playbackManager.saveProgress()
            }
        }
    }
}
```

Note: The `navigateToPlayback` handling for mini player tap navigation to PlaybackDetailView may need a programmatic `NavigationPath` approach. For now the simplest path: tapping mini player switches to the playlist tab where the course is already in the nav stack, or we use `.navigationDestination(item:)`. This detail will be refined during implementation — the key is the `safeAreaInset` + environment injection structure.

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add App/lingQ/ContentView.swift
git commit -m "feat: wire PlaybackManager and MiniPlayerBar into ContentView"
```

---

### Task 7: Refactor PlaybackDetailView to use PlaybackManager

**Files:**
- Modify: `App/lingQ/Playback/PlaybackDetailView.swift`

Remove all local player state and resource management. Delegate to PlaybackManager from environment.

- [ ] **Step 1: Rewrite PlaybackDetailView**

Key changes:
- Remove `@State private var player = AudioPlayer()` and all resource-related state
- Add `@Environment(PlaybackManager.self) private var playbackManager`
- `task { }` calls `await playbackManager.play(course: course)` instead of local `loadContent()`
- All `player.xxx` references become `playbackManager.player.xxx`
- Remove `onDisappear` cleanup (no more pause, no more resource release)
- `loadState`, `cues`, `searcher` all read from `playbackManager`
- Keep UI layout the same

```swift
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
            if let searcher = playbackManager.searcher {
                ImmersiveListeningView(
                    course: course,
                    isPresented: $showImmersive
                )
            }
        }
    }

    // coverImageSection, titleSection, controlsList — same as before but using
    // `player` computed property instead of local player.
    // All references to `cues` become `playbackManager.cues`.
    // All references to `searcher` become `playbackManager.searcher`.
    // Remove loadContent(), resolveSubtitleURL(), resolveAudioURL() methods entirely.
    // Keep: formatTime(), speedLabel(), jumpToPreviousCue(), jumpToNextCue(),
    //       toggleABRepeat(), progressTotal, progressValue, progressFraction,
    //       subtitleSummary, transportButton(), utilityLabel(), coverImageSection, titleSection
    // Update cues references in jumpToPreviousCue/jumpToNextCue to use playbackManager.cues
}
```

The full file will preserve all existing UI code — only the data source and lifecycle change.

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add App/lingQ/Playback/PlaybackDetailView.swift
git commit -m "refactor: PlaybackDetailView uses shared PlaybackManager"
```

---

### Task 8: Refactor ImmersiveListeningView to use PlaybackManager

**Files:**
- Modify: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`

Remove player parameter, get from environment. On disappear, only save progress — no pause.

- [ ] **Step 1: Update ImmersiveListeningView**

Key changes:
- Remove `let cues: [SubtitleCue]` parameter
- Remove `let searcher: CueSearcher` parameter
- Remove `@Bindable var player: AudioPlayer` parameter
- Add `@Environment(PlaybackManager.self) private var playbackManager`
- Add computed properties: `private var player: AudioPlayer { playbackManager.player }`, `private var cues: [SubtitleCue] { playbackManager.cues }`, `private var searcher: CueSearcher { playbackManager.searcher! }`
- `onDisappear`: keep `course.playbackPosition = player.currentTime` and `course.lastPlayedAt = Date()`, remove nothing else (no player.pause — it should keep playing)
- Update the signature — callers pass only `course` and `isPresented`

```swift
struct ImmersiveListeningView: View {
    let course: Course
    @Binding var isPresented: Bool

    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.modelContext) private var modelContext

    // ... all existing @State properties unchanged ...

    private var player: AudioPlayer { playbackManager.player }
    private var cues: [SubtitleCue] { playbackManager.cues }

    // body and all methods remain the same, just using computed `player` and `cues`
    // searcher usage: replace `searcher.index(at:)` with `playbackManager.searcher?.index(at:)` etc.

    // onDisappear stays the same (saves progress, cancels tasks, does NOT pause)
}
```

- [ ] **Step 2: Update PlaybackDetailView's navigationDestination call**

The call site in `PlaybackDetailView` already updated in Task 7 to:
```swift
ImmersiveListeningView(
    course: course,
    isPresented: $showImmersive
)
```
Verify this matches the new init signature.

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/ImmersiveListening/ImmersiveListeningView.swift
git commit -m "refactor: ImmersiveListeningView uses shared PlaybackManager"
```

---

### Task 9: Handle audio interruptions and mini player navigation

**Files:**
- Modify: `App/lingQ/Playback/PlaybackManager.swift`
- Modify: `App/lingQ/ContentView.swift`

- [ ] **Step 1: Add audio interruption handling to PlaybackManager**

Add to `PlaybackManager`:

```swift
private var interruptionObserver: Any?

func observeInterruptions() {
    interruptionObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        Task { @MainActor in
            guard let self else { return }
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .began {
                self.player.pause()
            } else if type == .ended {
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self.player.play()
                    }
                }
            }
        }
    }
}
```

Add `import AVFoundation` to PlaybackManager imports.

Call `observeInterruptions()` in `init()` of PlaybackManager.

- [ ] **Step 2: Refine mini player navigation in ContentView**

Update ContentView to use `NavigationPath` for the playlist tab so mini player can push programmatically:

```swift
@State private var playlistPath = NavigationPath()

// In the playlist tab:
NavigationStack(path: $playlistPath) {
    HomeView { ... }
    .navigationDestination(for: Course.self) { course in
        PlaybackDetailView(course: course)
    }
}

// MiniPlayerBar onTap:
MiniPlayerBar(playbackManager: playbackManager) {
    if let course = playbackManager.currentCourse {
        selectedTab = .playlist
        // Only push if not already showing this course
        playlistPath = NavigationPath([course])
    }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add App/lingQ/Playback/PlaybackManager.swift App/lingQ/ContentView.swift
git commit -m "feat: add audio interruption handling and mini player navigation"
```

---

### Task 10: Final integration test and cleanup

**Files:**
- Possibly modify: `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift` (can delete — it's already a placeholder)

- [ ] **Step 1: Build the project**

```bash
cd /Users/yoge/dev/swift/lingQ && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20
```

Fix any compilation errors.

- [ ] **Step 2: Verify all navigation flows**

Manual test checklist:
1. Open a course from Home → PlaybackDetailView loads and plays
2. Tap subtitle button → ImmersiveListeningView opens, audio continues
3. Exit immersive (X or swipe) → back to PlaybackDetailView, audio still playing
4. Navigate back to Home → MiniPlayerBar visible, audio still playing
5. Tap MiniPlayerBar → navigates to PlaybackDetailView for current course
6. MiniPlayerBar play/pause button works
7. Lock screen shows Now Playing with correct title, artwork, progress
8. Lock screen controls (play/pause/skip) work
9. Background playback continues when app is minimized
10. Switch to different course → previous progress saved, new course loads
11. Kill and relaunch app → progress restored when re-opening the course

- [ ] **Step 3: Clean up ImmersivePlayerView placeholder**

Delete `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift` and remove from Xcode project if no longer referenced.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete global playback with mini player and Now Playing"
```
