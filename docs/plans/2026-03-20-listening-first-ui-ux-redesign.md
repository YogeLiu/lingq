# Listening-First UI/UX Redesign

**Product direction:** Reference the listening immersion of Apple Books and Spotify Lyrics, but optimize for a hearing-improvement product rather than a generic media player.

**Primary goal:** Rebuild the app so the default user journey is "continue listening -> follow the current line -> deepen into reading/word actions -> review later", instead of splitting users across disconnected functional tabs.

## Product Principles

1. The app opens into a listening decision, not a feature decision.
2. Playback is the primary surface; reading and vocabulary actions are extensions of the playback session.
3. The current line must always feel like the center of the experience.
4. System state must be explicit: loading, importing, matched subtitle, failed file access, review due.
5. Visual design should feel quiet, immersive, and trustworthy rather than flashy.

## Information Architecture

### Bottom Navigation

Replace the current three-way functional split with:

- `首页`
- `课程`
- `学习`

`播放页` should not be a tab. It should open from `首页` or `课程` and take over as the primary learning surface.

### Page Roles

#### 首页

Purpose: answer "what should I listen to now?"

Content order:

1. Continue listening hero card
2. Recent courses carousel or horizontal list
3. Today's learning summary
4. Import entry

#### 课程

Purpose: manage imported listening content.

Content:

- Import button
- All courses
- Sort by recent play, recent import, unfinished
- Course metadata for resuming

#### 学习

Purpose: aggregate vocabulary and review in one place.

Content order:

1. Due review card
2. Recent new words
3. Words grouped by course
4. Full vocabulary list

## Core Experience

### 1. Home

The home screen should feel closer to a focused listening dashboard than a data list.

#### Continue Listening Hero

Must show:

- Course title
- Resume timestamp
- Current subtitle line preview
- Primary CTA: `继续播放`
- Secondary CTA: `进入精读`

#### Recent Courses

Each course card should show:

- Title
- Last listened position
- Total duration or completion progress
- Pending review count

#### Daily Summary

Keep this light. Show only a few high-value metrics:

- Due review count
- New words added recently
- Listening time today

#### Import Entry

Make import visible on the page, not just as a toolbar affordance.

## Listening Player

The player is the product core. It should behave like a listening-first study player, not a generic transcript viewer.

### Layout

Three layers:

1. Main subtitle layer
2. Playback control layer
3. Learning action layer

### Main Subtitle Layer

Default state should emphasize:

- Current line at largest size
- Previous and next lines visible but visually weaker
- Auto-centering while playing
- Tap a line to jump playback

Avoid using a full long scrolling transcript as the default primary mode.

### Playback Control Layer

Pinned bottom control surface:

- Play / pause
- Previous line / next line
- Skip backward 10s / forward 10s
- Progress bar
- Playback speed
- Mode switch

### Listening Modes

Rename abstract internal modes into user-facing behavior:

- `沉浸听`
- `跟句听`
- `精读`

Definitions:

- `沉浸听`: current line emphasized, low interface noise, minimum controls
- `跟句听`: current, previous, and next line visible with quick navigation
- `精读`: denser text interaction with word-level lookup and context

### Learning Action Layer

Learning actions should be contextual to the current line:

- Tap a word to open a half-sheet lookup card
- Lookup card supports pronunciation, definition, save, and level marking
- Current line offers a clear transition into full reading mode when needed

## Course Library

The course library is a content-management page, not the app home.

### Course Cards

Cards should prioritize resume utility:

- Title
- Total duration
- Last playback position
- Subtitle preview
- Pending review count

Default tap action should resume playback from the last position. Reading becomes a secondary action.

## Import Flow

The import flow should be productized as a visible 2-step process, not exposed as a chain of system dialogs.

### Desired Flow

1. Present an import sheet with short explanation
2. Select audio
3. Attempt automatic subtitle match
4. If auto-match fails, explicitly prompt for subtitle selection
5. Confirm success and offer next actions

### Import Sheet Content

Show:

- Selected audio file
- Subtitle status: auto-matched / waiting for selection
- Supported formats
- Final CTA: `完成导入`

### Success Feedback

After import completes, provide explicit confirmation with:

- `立即播放`
- `稍后查看`

## Reading Experience

Reading should be a deepening mode of the same listening session, not a disconnected second product.

### Requirements

- Explicit loading state
- Explicit file access / parsing error state
- Retry action
- Stable reading rhythm
- Current line sync with playback

### Word Interaction

The current level-marking interaction is too abstract. Replace symbolic dots with semantic actions.

Preferred structure inside the lookup card:

- Word
- Pronunciation
- Short definition
- Context sentence
- Action row with clear labels such as:
  - `初识`
  - `熟悉`
  - `掌握`
  - `已会`

## Learning Surface

Vocabulary and review should share one learning workspace.

### Sections

#### 今日复习

Show due count and estimated time to finish.

#### 最近新增

Show newly captured words from recent listening sessions.

#### 按课程查看

Group words by course because listening-based vocabulary is context-dependent.

#### 全部词汇

Keep a full list for management, but not as the primary surface.

### Word Cards

Each word card should include more than the word itself:

- Word
- Short definition
- Source course
- Recent context sentence
- Current level
- Next review time

## Review Experience

Review should feel like a short focused session, not a static flashcard demo.

### Review Session Requirements

- Show remaining count
- Show rough estimated completion time
- Show source course
- Give visible transition after grading
- End with a concise summary and a return path back to listening

## Visual System

### Tone

The app should feel:

- immersive
- calm
- readable
- premium but restrained

Not:

- overly gamified
- overly material-heavy
- dependent on random accent colors

### Color Strategy

Use four layers:

1. Brand accent
2. Semantic status colors
3. Text/content hierarchy colors
4. Optional subtle course atmosphere tint

Word-level colors should be rationalized into a controlled system rather than a set of unrelated raw colors.

### Typography

Use a stable hierarchy:

- Hero / current line
- Section title
- Body text
- Supporting metadata

Rules:

- Avoid all-caps English labels inside a Chinese product
- Keep subtitles highly readable
- Use monospaced digits for time and playback metrics

### Components

Standardize around:

- Hero Card
- Player Surface
- Learning Sheet

Avoid mixing too many ad hoc materials, shadows, and accent treatments per screen.

### Motion

Use motion only where it improves comprehension:

- subtitle recentering
- sheet presentation
- flashcard progression

Avoid decorative animation that competes with listening.

## Copy System

Rename internal concepts into user language:

- `FLOW STATE` -> `沉浸听`
- `FOCUSED` -> `跟句听`
- `AMBIENT` -> `连续听` or remove entirely
- `DEFINITION` -> `释义`
- `LEVEL` -> use direct Chinese labels or Chinese labels with lightweight numeric mapping

## Rollout Strategy

### Phase 1: Structural Redesign

- Navigation
- Home
- Player
- Import flow

### Phase 2: Learning Workflow

- Reading mode
- Word lookup
- Review rhythm
- Learning page consolidation

### Phase 3: Visual Unification

- Color system
- Typography
- Components
- Motion and copy cleanup

## Success Criteria

The redesign succeeds when:

1. The first screen clearly invites the user to continue listening.
2. The player centers the current line and makes listening feel continuous.
3. Importing content feels like a guided flow rather than a debugging sequence.
4. Word marking and review are understandable without memorizing internal terminology.
5. The app feels like one coherent listening-learning product rather than multiple disconnected utilities.
