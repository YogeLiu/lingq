# Apple-Inspired Prototype Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rework the current SwiftUI app into the approved Apple-inspired light design with `Playlist / Vocabulary / Me`, a summary-first playback detail page, and a separate immersive subtitle experience.

**Architecture:** Keep the existing SwiftData models, audio player integration, and import pipeline, but replace the current dark visual system and top-level navigation structure with a lighter Apple-style shell. Build the redesign around a few shared UI primitives plus a dedicated playback-detail route and a full-screen immersive subtitle route that hides the tab bar.

**Tech Stack:** SwiftUI, SwiftData, SharedModels, AudioPlayerKit, SubtitleKit, VocabularyKit, xcodebuild

---

### Task 1: Replace the dark theme with Apple-style semantic tokens

**Files:**
- Modify: `App/lingQ/Theme/AppTheme.swift`
- Modify: `App/lingQ/UI/HeroCard.swift`
- Modify: `App/lingQ/UI/PlayerSurface.swift`
- Modify: `App/lingQ/UI/SectionHeader.swift`
- Modify: `App/lingQ/UI/EmptyStateCard.swift`

**Step 1: Run a baseline build**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache xcodebuild -project /Users/yoge/dev/swift/lingQ/lingQ.xcodeproj -scheme lingQ -destination 'generic/platform=iOS' -derivedDataPath /Users/yoge/dev/swift/lingQ/build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Expected: PASS

**Step 2: Replace `AppTheme` color tokens**

Update `App/lingQ/Theme/AppTheme.swift` to use light semantic tokens such as:

```swift
enum AppTheme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let elevatedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let surface = Color.white
    static let surfaceMuted = Color(uiColor: .tertiarySystemGroupedBackground)

    static let brandAccent = Color(uiColor: .systemBlue)
    static let brandAccentMuted = Color(uiColor: .systemBlue).opacity(0.14)

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
}
```

**Step 3: Update shared UI primitives to match the new surface language**

Adjust the reusable card views to use:

- white or grouped-system backgrounds
- softer shadows
- lighter outlines
- no dark gradients

Concrete checks:

- `HeroCard` should render as a white rounded card, not a dark hero block
- `PlayerSurface` should use a thin-material or soft white panel
- `SectionHeader` should rely on typography instead of heavy decoration

**Step 4: Re-run the build**

Run the same `xcodebuild` command from Step 1.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/Theme/AppTheme.swift App/lingQ/UI/HeroCard.swift App/lingQ/UI/PlayerSurface.swift App/lingQ/UI/SectionHeader.swift App/lingQ/UI/EmptyStateCard.swift
git commit -m "feat: adopt apple-inspired light theme tokens"
```

### Task 2: Rename top-level navigation to `Playlist / Vocabulary / Me`

**Files:**
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/Home/HomeView.swift`
- Modify: `App/lingQ/Learning/LearningView.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Replace the current tab model in `ContentView`**

Update the tab enum to:

```swift
private enum TabSelection: Hashable {
    case playlist
    case vocabulary
    case me
}
```

Update the `TabView` labels to:

- `Playlist`
- `Vocabulary`
- `Me`

Map them to:

- `HomeView`
- `VocabularyListView`
- a management-oriented screen rooted in the current course or learning infrastructure

**Step 3: Align titles and destinations**

Make the page titles and navigation destinations consistent:

- `HomeView` title becomes `Playlist`
- `VocabularyListView` remains the primary root for vocabulary
- `Me` should point to the management hub rather than the current review-first learning page

If `LearningView` is too coupled to review workflows, replace it with a small new `MeView` and keep `LearningView` available for future reuse.

**Step 4: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/ContentView.swift App/lingQ/Home/HomeView.swift App/lingQ/Learning/LearningView.swift App/lingQ/CourseList/CourseListView.swift
git commit -m "feat: switch top-level navigation to playlist vocabulary me"
```

### Task 3: Redesign `Playlist` as a light Apple-style listening home

**Files:**
- Modify: `App/lingQ/Home/HomeView.swift`
- Modify: `App/lingQ/Home/ContinueListeningCard.swift`
- Modify: `App/lingQ/Home/RecentCourseStrip.swift`
- Modify: `App/lingQ/Home/LearningSummaryCard.swift`
- Modify: `App/lingQ/Home/ImportPromptCard.swift`
- Modify: `App/lingQ/CourseList/CourseCardView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Rebuild the `Playlist` hierarchy**

Update `HomeView` so its content order is:

1. Continue card
2. Recent courses
3. Collections entry

Remove the current dark-dashboard tone and avoid overloading the page with metrics.

**Step 3: Convert the continue card into a summary-first course hero**

In `ContinueListeningCard.swift`, make sure the card includes:

- artwork
- title
- one-line description or context
- progress metadata
- primary play action

The card should navigate to a playback detail page rather than directly opening a dense reading screen.

**Step 4: Simplify the secondary sections**

Adjust `RecentCourseStrip`, `LearningSummaryCard`, `ImportPromptCard`, and `CourseCardView` to match the approved direction:

- cleaner metadata
- lighter cards
- navigation-bar import emphasis rather than a mid-page CTA
- no heavy borders or dark fills

**Step 5: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 6: Commit**

```bash
git add App/lingQ/Home/HomeView.swift App/lingQ/Home/ContinueListeningCard.swift App/lingQ/Home/RecentCourseStrip.swift App/lingQ/Home/LearningSummaryCard.swift App/lingQ/Home/ImportPromptCard.swift App/lingQ/CourseList/CourseCardView.swift
git commit -m "feat: redesign playlist home for apple-style listening"
```

### Task 4: Introduce a summary-first playback detail page

**Files:**
- Create: `App/lingQ/Playback/PlaybackDetailView.swift`
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/Home/HomeView.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Modify: `App/lingQ/IntensiveReading/IntensiveReadingView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Create the new detail route**

Create `App/lingQ/Playback/PlaybackDetailView.swift` with a layout like:

```swift
struct PlaybackDetailView: View {
    let course: Course

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                artwork
                titleBlock
                summaryBlock
                playerControls
                subtitleButton
            }
            .padding(20)
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Step 3: Route course taps to the new page**

Update home and course-library navigation so the default tap action opens `PlaybackDetailView(course:)` instead of immediately dropping the user into the existing reading/transcript-heavy flow.

**Step 4: Keep reading and immersive routes as secondary transitions**

From the new detail page:

- a primary play action should resume playback
- a subtitle action should push the immersive subtitle page
- any deep reading route should stay secondary

Do not remove existing reading code yet; just stop making it the default landing surface.

**Step 5: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 6: Commit**

```bash
git add App/lingQ/Playback/PlaybackDetailView.swift App/lingQ/ContentView.swift App/lingQ/Home/HomeView.swift App/lingQ/CourseList/CourseListView.swift App/lingQ/IntensiveReading/IntensiveReadingView.swift
git commit -m "feat: add summary-first playback detail page"
```

### Task 5: Rebuild immersive playback around highlighted continuous subtitles

**Files:**
- Modify: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`
- Modify: `App/lingQ/ImmersiveListening/LyricsCanvasView.swift`
- Modify: `App/lingQ/ImmersiveListening/LyricLineView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersiveMode.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Change the subtitle presentation model**

Replace the current center-weighted lyric-card feel with continuous reading text that highlights the current sentence.

Concrete implementation target:

- current sentence uses accent emphasis and highest contrast
- upcoming text uses standard body color
- past text uses slightly reduced contrast
- no bottom tab bar appears while this page is visible

**Step 3: Add overlay auto-hide behavior**

In `ImmersiveListeningView.swift`, introduce state like:

```swift
@State private var controlsVisible = true
@State private var hideControlsTask: Task<Void, Never>?
```

Add helpers that:

- show controls on appear
- reset the timer on tap or player interaction
- hide top and bottom overlays after 5 seconds of inactivity

**Step 4: Preserve native navigation behavior**

Ensure immersive playback is pushed through `NavigationStack` so native left-edge swipe back remains active. Do not fake dismissal with a custom full-screen cover unless absolutely necessary.

**Step 5: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 6: Commit**

```bash
git add App/lingQ/ImmersiveListening/ImmersiveListeningView.swift App/lingQ/ImmersiveListening/LyricsCanvasView.swift App/lingQ/ImmersiveListening/LyricLineView.swift App/lingQ/ImmersiveListening/ImmersivePlayerView.swift App/lingQ/ImmersiveListening/ImmersiveMode.swift
git commit -m "feat: redesign immersive playback with highlighted subtitles"
```

### Task 6: Redesign vocabulary into grouped white cards

**Files:**
- Modify: `App/lingQ/Vocabulary/VocabularyListView.swift`
- Modify: `App/lingQ/Vocabulary/WordCardView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Group vocabulary by date**

Extract date-grouping logic in `VocabularyListView.swift` so the list renders sections by day rather than a single uninterrupted list.

Target structure:

```swift
struct VocabularySection: Identifiable {
    let id: String
    let title: String
    let words: [Word]
}
```

**Step 3: Redesign the word card**

Update `WordCardView.swift` so each card shows:

- word
- pronunciation or part of speech
- short meaning
- example sentence
- optional source label

Use a white card with subtle border or shadow. Remove any visually loud color blocks.

**Step 4: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/Vocabulary/VocabularyListView.swift App/lingQ/Vocabulary/WordCardView.swift
git commit -m "feat: redesign vocabulary as grouped apple-style cards"
```

### Task 7: Create a dedicated `Me` hub and collections management flow

**Files:**
- Create: `App/lingQ/Profile/MeView.swift`
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Modify: `App/lingQ/CourseList/EmptyStateView.swift`
- Create: `App/lingQ/Profile/CollectionsView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Add the `Me` root page**

Create `MeView.swift` with:

- large title `Me`
- a primary `Collections` entry card
- secondary grouped rows for lower-priority management items

Keep the page intentionally sparse.

**Step 3: Add the collections page**

Create `CollectionsView.swift` with:

- grouped list layout
- navigation-bar `+` action
- native swipe-to-delete
- collection sections that contain course rows

If no collection model exists yet, scaffold the view structure and use placeholder or existing course-grouping data until the model work is scheduled.

**Step 4: Rewire navigation**

Hook `Me` in `ContentView`, and update any existing library-management links so collection management no longer lives on the `Playlist` surface.

**Step 5: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 6: Commit**

```bash
git add App/lingQ/Profile/MeView.swift App/lingQ/Profile/CollectionsView.swift App/lingQ/ContentView.swift App/lingQ/CourseList/CourseListView.swift App/lingQ/CourseList/EmptyStateView.swift
git commit -m "feat: add me hub and collections management"
```

### Task 8: Simplify import into `import first, classify later`

**Files:**
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Modify: `App/lingQ/Import/ImportCourseSheet.swift`
- Modify: `App/lingQ/Import/BookmarkManager.swift`
- Modify: `App/lingQ/Playback/PlaybackDetailView.swift`
- Modify: `App/lingQ/Profile/CollectionsView.swift`

**Step 1: Run the baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Remove premature collection thinking from import UX**

Make sure `ImportCourseSheet.swift` only communicates:

1. choose audio
2. confirm subtitle
3. finish import

Do not ask the user to select or create a collection during import.

**Step 3: Add post-import hooks**

After successful import:

- offer immediate playback
- keep collection assignment available later from playback detail or collections management

If needed, add a lightweight “Add to Collection” affordance in `PlaybackDetailView.swift`, but only after course creation succeeds.

**Step 4: Re-run the build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/CourseList/CourseListView.swift App/lingQ/Import/ImportCourseSheet.swift App/lingQ/Import/BookmarkManager.swift App/lingQ/Playback/PlaybackDetailView.swift App/lingQ/Profile/CollectionsView.swift
git commit -m "feat: simplify import then classify workflow"
```

### Task 9: Final visual and behavioral polish pass

**Files:**
- Modify: `App/lingQ/Home/HomeView.swift`
- Modify: `App/lingQ/Playback/PlaybackDetailView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`
- Modify: `App/lingQ/Vocabulary/VocabularyListView.swift`
- Modify: `App/lingQ/Profile/MeView.swift`
- Modify: `App/lingQ/Profile/CollectionsView.swift`

**Step 1: Run the full app build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 2: Perform a consistency pass**

Verify and fix:

- spacing between sections
- title casing and tab labels
- card radii
- tint usage
- navigation title modes
- sheet and overlay material consistency
- immersive control fade timing

**Step 3: Re-run the full app build**

Run the same `xcodebuild` command.

Expected: PASS

**Step 4: Commit**

```bash
git add App/lingQ/Home/HomeView.swift App/lingQ/Playback/PlaybackDetailView.swift App/lingQ/ImmersiveListening/ImmersiveListeningView.swift App/lingQ/Vocabulary/VocabularyListView.swift App/lingQ/Profile/MeView.swift App/lingQ/Profile/CollectionsView.swift
git commit -m "chore: polish apple-inspired prototype redesign"
```
