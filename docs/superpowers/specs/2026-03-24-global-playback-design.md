# Global Playback & Mini Player Design

## Problem

Currently `AudioPlayer` is a `@State` inside `PlaybackDetailView`. When the user navigates away, the player is destroyed and audio stops. Users expect:

1. Exiting immersive mode (subtitles) returns to PlaybackDetailView with audio still playing
2. Exiting PlaybackDetailView returns to home with audio still playing
3. A mini player bar appears above the tab bar showing current playback
4. Audio continues in background (like Apple Music)
5. Lock screen / Control Center shows Now Playing info with playback controls
6. Playback progress is persisted and restored on re-entry

## Architecture

### PlaybackManager (`@Observable`, `@MainActor`)

Single source of truth for all playback state. Created at app level, injected via `.environment()`.

**Properties:**
- `player: AudioPlayer` - the existing audio player
- `currentCourse: Course?` - currently loaded course (nil = nothing playing)
- `cues: [SubtitleCue]` - subtitle cues for current course
- `searcher: CueSearcher?` - cue lookup
- `loadState: LoadState` - idle / loading / ready / failed
- `audioResourceURL: URL?` - security-scoped resource tracking
- `hasAudioSecurityScope: Bool`

**Methods:**
- `play(course:)` - loads a course if different from current, starts playback, configures Now Playing
- `stop()` - stops playback, clears current course, clears Now Playing
- `saveProgress()` - writes `currentTime` to `course.playbackPosition` and updates `lastPlayedAt`

**Progress auto-save:** A timer saves progress every 10 seconds while playing. Also saves on pause, seek, and app backgrounding (via `scenePhase` observation or `willResignActive` notification).

**Security-scoped resources:** The manager holds bookmark access for the audio file's lifetime. Released only on `stop()` or when loading a different course.

### Now Playing Integration

New file: `NowPlayingManager` (or integrated into `PlaybackManager`).

Uses `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`:

- **Info displayed:** title, duration, elapsed time, playback rate, artwork (from course cover image)
- **Remote commands:** play, pause, skip forward 10s, skip backward 10s, change playback position (scrubber)
- **Updates:** elapsed time updated on timer tick (same 0.1s timer already in AudioPlayer), info refreshed on track change

Requires: `import MediaPlayer`

### Background Audio

Already partially in place:
- `AudioPlayer.configureAudioSession()` sets `.playback` category - keep this
- **Add:** `UIBackgroundModes: audio` to Info.plist (or via Xcode target capabilities)
- **Add:** Call `configureAudioSession()` at app launch in `lingQApp.init()` instead of lazily
- The combination of active audio session + background mode + AVAudioPlayer is sufficient

### MiniPlayerBar

Displayed in `ContentView`, positioned between content and tab bar.

**Appearance:**
- Height: ~64pt
- Shows: course title (single line), play/pause button, tap to navigate to PlaybackDetailView
- Visible when `playbackManager.currentCourse != nil`
- Smooth appear/disappear animation

**Layout approach:** Wrap the `TabView` content area so MiniPlayerBar sits above the tab bar. Use `.safeAreaInset(edge: .bottom)` on the `TabView` or overlay approach.

**Navigation:** Tapping the mini player navigates to `PlaybackDetailView` for the current course. Uses programmatic `NavigationPath` or `navigationDestination`.

### Modified Views

#### `PlaybackDetailView`
- Remove `@State private var player = AudioPlayer()` and all local player state
- Get `PlaybackManager` from `@Environment`
- On appear: call `playbackManager.play(course:)` if not already playing this course
- On disappear: do NOT pause or clean up (manager owns lifecycle)
- All player controls delegate to `playbackManager.player`

#### `ImmersiveListeningView`
- Remove `@Bindable var player: AudioPlayer` parameter
- Get `PlaybackManager` from `@Environment`
- On disappear: save progress but do NOT pause. Remove the current `player.pause()` (there isn't one, but ensure no stop logic added)
- The existing `onDisappear` already saves position - keep that, but delegate to manager

#### `ContentView`
- Create `PlaybackManager` as `@State`
- Inject via `.environment(playbackManager)`
- Add `MiniPlayerBar` overlay
- Add navigation handling for mini player tap

#### `lingQApp`
- Call `AudioPlayer.configureAudioSession()` in init

### File Changes Summary

| File | Change |
|------|--------|
| `App/lingQ/Playback/PlaybackManager.swift` | **New** - global playback state manager |
| `App/lingQ/Playback/NowPlayingManager.swift` | **New** - MPNowPlayingInfoCenter integration |
| `App/lingQ/Playback/MiniPlayerBar.swift` | **New** - mini player bar view |
| `App/lingQ/Playback/PlaybackDetailView.swift` | **Modify** - use PlaybackManager from environment |
| `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift` | **Modify** - use PlaybackManager from environment |
| `App/lingQ/ContentView.swift` | **Modify** - add PlaybackManager + MiniPlayerBar |
| `App/lingQ/lingQApp.swift` | **Modify** - configure audio session at launch |
| `Info.plist` / Xcode project | **Modify** - add background audio capability |
| `lingQ.xcodeproj/project.pbxproj` | **Modify** - add new files |

### Data Flow

```
lingQApp
  -> ContentView (@State PlaybackManager, .environment())
       -> TabView
            -> HomeView -> PlaybackDetailView (reads @Environment PlaybackManager)
                              -> ImmersiveListeningView (reads @Environment PlaybackManager)
       -> MiniPlayerBar (reads @Environment PlaybackManager)
```

### Edge Cases

- **Switching courses:** If user taps a different course while one is playing, `play(course:)` saves progress of current course, releases resources, loads new course
- **Audio interruptions:** AVAudioSession interruption notification should pause and resume appropriately (phone call, Siri, etc.)
- **App termination:** Progress saved via auto-save timer; also save in `scenePhase .background`
- **Security-scoped bookmarks:** Manager holds access for current audio file only; released on course switch or stop
