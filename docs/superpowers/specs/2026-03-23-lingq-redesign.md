# LingQ App Redesign - Design Spec

## Overview

Simplify the existing LingQ listening app: remove intensive reading mode, simplify vocabulary to single "saved" state, redesign import to use zip files, and enhance the playback experience with a clean playback page + immersive subtitle view.

## Changes from Current Design

### Removed
- Intensive reading mode (IntensiveReadingView and related files)
- 4-level vocabulary system (simplify to saved/unsaved)
- Step-by-step audio+subtitle import flow

### Added
- Zip file import (cover image + mp3 + srt)
- Cover image display on course cards and playback page
- Word tapping in immersive subtitle view to save vocabulary
- Enhanced playback controls (A-B repeat, speed, prev/next sentence)

### Modified
- Playback page: cover + controls only, "subtitle" button enters immersive mode
- Course model: add cover image storage
- Vocabulary: single "saved" state instead of 4 levels

## Navigation Structure

```
TabView
├── Playlist (首页)
│   └── CourseListView (audio list with cover images)
│       └── PlaybackDetailView (cover + full player controls)
│           └── ImmersiveListeningView (fullScreenCover)
│               ├── Highlighted subtitle scrolling
│               ├── Tap word → save to vocabulary (system dictionary)
│               └── Player auto-hides after 5s
├── Vocabulary (生词本)
│   └── VocabularyListView (saved words, single state)
├── Review (闪卡复习)
│   └── FlashcardReviewView (SM-2 spaced repetition)
└── Me (设置/导入)
    └── Import from Files (select zip → extract cover + mp3 + srt)
```

## Data Model Changes

### Course
- Add `coverImagePath: String?` — relative path to extracted cover image in app documents
- Keep existing fields (audioBookmark, subtitleBookmark, etc.)
- Store extracted files in app's documents directory (no more security-scoped bookmarks for zip import)

### Word (Simplified)
- Remove `level: WordLevel` (4-level system)
- Keep: id, text, definition, phonetic, contextSentence, courseId, createdAt
- Keep SRS fields: nextReviewAt, reviewCount, easeFactor (for flashcard review)

## Import Flow

1. User taps import in Me tab
2. iOS document picker opens for `.zip` files
3. App extracts zip to `Documents/<courseId>/`
4. Expected zip contents: `cover.jpg` (or .png), `audio.mp3` (or .m4a), `subtitle.srt`
5. App finds files by extension, creates Course record
6. Cover image stored as file, audio/srt stored as local files (no bookmarks needed)

## Playback Page

Layout (top to bottom):
1. Cover image (large, rounded corners)
2. Title + subtitle info
3. Progress bar with time labels
4. Player controls row:
   - Speed button (0.5x ~ 2.0x)
   - Previous sentence
   - Backward 10s
   - Play/Pause (large, center)
   - Forward 10s
   - Next sentence
   - A-B repeat toggle
5. "Subtitle" button → enters immersive view

## Immersive Subtitle View

- Current sentence: highlighted (bold, full opacity)
- Other sentences: dimmed (lower opacity)
- Tap on a word in any visible subtitle → save to vocabulary + show system dictionary
- Player controls at bottom, auto-hide after 5s
- Tap screen to show/hide controls
- Close button (x) returns to playback page

## Flashcard Review

Keep existing SM-2 implementation. Adapt to simplified word model (no levels, just saved words with SRS scheduling).
