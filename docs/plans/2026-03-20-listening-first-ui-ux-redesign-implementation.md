# Listening-First UI/UX Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the app into a listening-first learning experience where users resume playback from home, interact with current subtitles in a focused player, and access reading, vocabulary, and review as supporting workflows.

**Architecture:** Keep the existing data model and playback engine, but reorganize navigation and primary screens around a central playback session. Introduce shared UI primitives for hero cards, player surfaces, and learning sheets so the redesign is structural rather than cosmetic.

**Tech Stack:** SwiftUI, SwiftData, SharedModels, AudioPlayerKit, SubtitleKit, VocabularyKit

---

### Task 1: Add shared redesign primitives

**Files:**
- Create: `App/lingQ/UI/HeroCard.swift`
- Create: `App/lingQ/UI/SectionHeader.swift`
- Create: `App/lingQ/UI/PlayerSurface.swift`
- Create: `App/lingQ/UI/EmptyStateCard.swift`
- Modify: `App/lingQ/Theme/AppTheme.swift`

**Step 1: Write the failing test**

There are no existing SwiftUI snapshot tests in this app. For this task, define compile-level success as the first guardrail and keep components small enough to verify through build integration.

**Step 2: Run targeted build to establish the current baseline**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache xcodebuild -project /Users/yoge/dev/swift/lingQ/lingQ.xcodeproj -scheme lingQ -destination 'generic/platform=iOS' -derivedDataPath /Users/yoge/dev/swift/lingQ/build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Expected: PASS

**Step 3: Write minimal implementation**

- Create reusable card, section header, player container, and empty-state components.
- Expand `AppTheme` into explicit semantic tokens for:
  - brand accent
  - background / surface
  - primary / secondary / tertiary text
  - success / warning / danger
  - vocabulary emphasis
- Keep API simple and local to SwiftUI.

**Step 4: Run targeted build to verify it passes**

Run the same `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/UI App/lingQ/Theme/AppTheme.swift
git commit -m "feat: add shared listening-first UI primitives"
```

### Task 2: Rebuild top-level navigation and home

**Files:**
- Modify: `App/lingQ/ContentView.swift`
- Create: `App/lingQ/Home/HomeView.swift`
- Create: `App/lingQ/Home/ContinueListeningCard.swift`
- Create: `App/lingQ/Home/RecentCourseStrip.swift`
- Create: `App/lingQ/Home/LearningSummaryCard.swift`
- Create: `App/lingQ/Home/ImportPromptCard.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`

**Step 1: Write the failing test**

Create a lightweight view-model or helper test if extracted logic is needed for:
- identifying the most recent course
- formatting listening summary values

If no logic extraction is needed, use build verification only.

**Step 2: Run baseline build**

Run the `xcodebuild` command from Task 1.

Expected: PASS

**Step 3: Write minimal implementation**

- Replace tabs with `首页 / 课程 / 学习`.
- Add `HomeView` as the new default landing screen.
- Populate home with:
  - continue listening hero
  - recent course strip
  - daily summary
  - visible import entry
- Keep `CourseListView` focused on library management rather than being the app home.

**Step 4: Run build to verify it passes**

Run the same `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/ContentView.swift App/lingQ/Home App/lingQ/CourseList/CourseListView.swift
git commit -m "feat: add listening-first home navigation"
```

### Task 3: Turn course cards into resume-oriented content cards

**Files:**
- Modify: `App/lingQ/CourseList/CourseCardView.swift`
- Modify: `App/lingQ/CourseList/EmptyStateView.swift`
- Modify: `App/lingQ/Home/RecentCourseStrip.swift`

**Step 1: Write the failing test**

If formatting helpers are extracted, add unit tests for:
- playback position formatting
- subtitle preview fallback behavior

**Step 2: Run relevant tests or baseline build**

Run extracted helper tests if added; otherwise run the `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Redesign course cards around:
  - title
  - last position
  - subtitle preview
  - review count
  - primary resume action
- Make empty state describe the product as a listening app, not just a file container.

**Step 4: Re-run verification**

Run the same verification command used in Step 2.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/CourseList/CourseCardView.swift App/lingQ/CourseList/EmptyStateView.swift App/lingQ/Home/RecentCourseStrip.swift
git commit -m "feat: redesign course resume cards"
```

### Task 4: Productize the import flow

**Files:**
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Create: `App/lingQ/Import/ImportCourseSheet.swift`
- Modify: `App/lingQ/Import/BookmarkManager.swift`

**Step 1: Write the failing test**

Extract import-step formatting or state mapping into testable helpers if useful. Add tests for:
- displayed subtitle status from import state
- CTA availability based on selected files

**Step 2: Run test/build baseline**

Run helper tests if added; otherwise run the `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Add a custom import sheet that explains the two-step flow.
- Show selected audio and subtitle state before finalizing import.
- Keep system pickers underneath, but frame them as guided actions.
- Add explicit success feedback with actions:
  - play now
  - view later

**Step 4: Re-run verification**

Run the same verification command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/CourseList/CourseListView.swift App/lingQ/Import/ImportCourseSheet.swift App/lingQ/Import/BookmarkManager.swift
git commit -m "feat: guide course import with explicit steps"
```

### Task 5: Rebuild the playback surface around the current line

**Files:**
- Modify: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`
- Modify: `App/lingQ/ImmersiveListening/LyricsCanvasView.swift`
- Modify: `App/lingQ/ImmersiveListening/LyricLineView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift`
- Modify: `App/lingQ/ImmersiveListening/ImmersiveMode.swift`
- Modify: `App/lingQ/IntensiveReading/MiniPlayerView.swift`

**Step 1: Write the failing test**

Add unit tests for any extracted helpers:
- player mode labels
- visible-line selection behavior
- progress formatting helpers if moved into pure functions

**Step 2: Run package tests/build baseline**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache swift test
```

In:

```bash
/Users/yoge/dev/swift/lingQ/Packages/AudioPlayerKit
```

Then run the app `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Make the current line the visual center.
- Visually demote surrounding lines.
- Rename modes into user-facing Chinese labels.
- Add clearer playback speed and line navigation affordances.
- Unify mini player and immersive player styling around the same control grammar.

**Step 4: Re-run verification**

Run `swift test` in `Packages/AudioPlayerKit` and the app `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/ImmersiveListening App/lingQ/IntensiveReading/MiniPlayerView.swift Packages/AudioPlayerKit
git commit -m "feat: redesign listening player around current line"
```

### Task 6: Add reading-state feedback and contextual actions

**Files:**
- Modify: `App/lingQ/IntensiveReading/IntensiveReadingView.swift`
- Modify: `App/lingQ/IntensiveReading/SentenceView.swift`
- Modify: `App/lingQ/IntensiveReading/TappableWordView.swift`
- Modify: `App/lingQ/IntensiveReading/WordLookupPopup.swift`

**Step 1: Write the failing test**

Extract and test:
- loading/error/ready state mapping if modeled outside the view
- word action labels or level-display helpers

**Step 2: Run baseline build**

Run the app `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Add explicit loading, empty, and error states to reading.
- Keep the current line readable while preserving word tap affordances.
- Replace abstract level circles with clearer labeled actions.
- Localize copy into consistent Chinese product language.

**Step 4: Re-run verification**

Run the app `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/IntensiveReading
git commit -m "feat: add readable states and contextual word actions"
```

### Task 7: Consolidate vocabulary and review into a learning workspace

**Files:**
- Modify: `App/lingQ/Vocabulary/VocabularyListView.swift`
- Modify: `App/lingQ/Vocabulary/WordCardView.swift`
- Modify: `App/lingQ/Review/FlashcardReviewView.swift`
- Modify: `App/lingQ/Review/FlashcardView.swift`
- Modify: `App/lingQ/Review/ReviewSummaryView.swift`
- Optionally create: `App/lingQ/Learning/LearningView.swift`

**Step 1: Write the failing test**

Add store/helper tests for any extracted logic:
- due-summary formatting
- estimated review duration
- grouping words by course if a helper is introduced

Use existing `VocabularyKit` tests if logic lands there.

**Step 2: Run baseline tests**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache swift test
```

In:

```bash
/Users/yoge/dev/swift/lingQ/Packages/VocabularyKit
```

Then run the app `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Merge review and vocabulary surfaces under `学习`.
- Promote due review to the top of the page.
- Enrich word cards with course, context, and schedule metadata.
- Add more session rhythm to review:
  - remaining count
  - estimated time
  - source course
  - clearer summary completion state

**Step 4: Re-run verification**

Run `swift test` in `Packages/VocabularyKit` and the app `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ/Vocabulary App/lingQ/Review App/lingQ/Learning Packages/VocabularyKit
git commit -m "feat: unify vocabulary and review into learning workspace"
```

### Task 8: Unify copy, spacing, and visual rhythm across the app

**Files:**
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/Home/*.swift`
- Modify: `App/lingQ/CourseList/*.swift`
- Modify: `App/lingQ/ImmersiveListening/*.swift`
- Modify: `App/lingQ/IntensiveReading/*.swift`
- Modify: `App/lingQ/Vocabulary/*.swift`
- Modify: `App/lingQ/Review/*.swift`

**Step 1: Write the failing test**

No direct unit-test target is likely useful here. Use build and manual UI inspection as the acceptance path.

**Step 2: Run baseline build**

Run the app `xcodebuild` command.

Expected: PASS

**Step 3: Write minimal implementation**

- Replace mixed English/internal labels with consistent Chinese copy.
- Normalize spacing, paddings, corner radii, and section rhythm.
- Remove ad hoc uses of system material and accent where they conflict with the new visual system.

**Step 4: Re-run verification**

Run the app `xcodebuild` command.

Expected: PASS

**Step 5: Commit**

```bash
git add App/lingQ
git commit -m "feat: unify listening-first visual language"
```

### Task 9: Final verification and cleanup

**Files:**
- Modify only as needed based on verification failures

**Step 1: Run package tests**

Run in `Packages/VocabularyKit`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache swift test
```

Run in `Packages/AudioPlayerKit`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache swift test
```

Expected: PASS

**Step 2: Run final app build**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH=/Users/yoge/dev/swift/lingQ/build/ModuleCache xcodebuild -project /Users/yoge/dev/swift/lingQ/lingQ.xcodeproj -scheme lingQ -destination 'generic/platform=iOS' -derivedDataPath /Users/yoge/dev/swift/lingQ/build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Expected: PASS

**Step 3: Manual verification checklist**

Verify:

1. App opens to `首页`
2. Continue listening card resumes the right course
3. Import flow explains the audio/subtitle sequence
4. Playback screen centers the current line
5. Reading screen shows explicit loading/error states
6. Word actions are understandable without internal terminology
7. `学习` combines review and vocabulary coherently

**Step 4: Commit**

```bash
git add App/lingQ Packages/VocabularyKit Packages/AudioPlayerKit lingQ.xcodeproj/project.pbxproj
git commit -m "feat: complete listening-first UI and UX redesign"
```
