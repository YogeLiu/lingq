# Pure Native UI Redesign — Native + Hero

A complete UI redesign of the lingQ iOS app, replacing all custom styling with iOS system semantics. The goal is an app that feels indistinguishable from a first-party Apple app, with one intentional exception: a Hero card on the home screen for the "Continue Listening" entry point.

## Design Decisions

- Core user scenario: immersive listening is primary; vocabulary and review are secondary
- Visual tone: Podcasts-like utility for main UI, Music-like immersion for the listening page
- Colors: 100% iOS system semantic colors, no custom palette
- Tabs: 4 tabs — Home, Vocabulary, Review, Me
- Immersive page: dark background, push navigation with left-edge swipe back

## Design System

### Colors

All custom colors are removed. `AppTheme.swift` is deleted entirely.

| Usage | Token |
|-------|-------|
| Page background | `Color(.systemGroupedBackground)` |
| Card / group background | `Color(.secondarySystemGroupedBackground)` |
| Immersive background | `Color.black` |
| Accent | `Color.accentColor` (system blue) |
| Primary text | `Color(.label)` |
| Secondary text | `Color(.secondaryLabel)` |
| Tertiary text | `Color(.tertiaryLabel)` |
| Dividers | `Color(.separator)` |
| Destructive | `Color.red` |
| Success | `Color.green` |

### Typography

All system Dynamic Type fonts. No custom sizes, no custom tracking.

| Level | Usage | Font |
|-------|-------|------|
| Page title | Tab large titles | `.largeTitle` (automatic) |
| Section header | Group headers | `.headline` |
| Card title | Course name | `.headline` |
| Body | Descriptions, examples | `.body` |
| Auxiliary | Date, duration | `.caption` |
| Immersive lyrics (current) | Current sentence | `.title2.bold()` |

### Spacing

8pt grid. No odd spacing values.

- Page horizontal padding: handled by system List
- Group spacing: handled by `.insetGrouped` List
- Hero card internal padding: 16pt
- Small element gap: 8pt
- Standard element gap: 16pt

### Corner Radius

- Hero card: 16pt
- Cover thumbnails: 8pt (small), 12pt (large)
- Everything else: system List default

### Shadows

None. Visual hierarchy comes from background color differences between `systemGroupedBackground` and `secondarySystemGroupedBackground`.

## Tab Structure & Navigation

### Tabs

| Tab | Title | Icon | Role |
|-----|-------|------|------|
| Home | 首页 | `house` | Listening entry, continue + recent courses |
| Vocabulary | 词汇 | `character.book.closed` | Saved words browsing |
| Review | 复习 | `rectangle.on.rectangle` | Flashcard review |
| Me | 我的 | `person` | Course library, collections, import |

### Navigation

- All tabs use `NavigationStack` with `.large` display mode
- Immersive listening: push from playback detail, hide tab bar with `.toolbar(.hidden, for: .tabBar)`, hide navigation bar
- Return from immersive: system left-edge swipe back gesture
- Sheets: system default sheet style
- Tab bar: system default `TabView`, no customization

## Screen Specifications

### 1. Home (首页)

`ScrollView` with `VStack`, background `Color(.systemGroupedBackground)`.

#### Hero Card — Continue Listening

The only custom component on the home screen.

- Cover image: full card width, ~200pt height, `contentMode: .fill`, top corners rounded 16pt
- Below cover, 16pt padding:
  - Course title: `.headline`
  - Progress info: `.caption`, `Color(.secondaryLabel)`
  - Play button: system `.borderedProminent` style, "继续播放" with `play.fill` icon
- Card background: `Color(.secondarySystemGroupedBackground)`
- Card corner radius: 16pt
- No custom shadow
- No cover fallback: `Color(.systemFill)` rectangle with `headphones` icon

#### Recent Courses

Standard `.insetGrouped` List Section:

- Section header: "最近课程"
- Each row: 60x60 cover thumbnail (8pt corner radius) + course title + last played time
- Tap pushes to playback detail
- Maximum 5 items

#### Quick Actions

Standard `.insetGrouped` Section:

- "词汇复习" — navigates to Review tab, shows due count badge
- "导入课程" — opens import sheet

#### Empty State

When no courses exist:

- `headphones` icon, `.title`, `Color(.tertiaryLabel)`
- "导入你的第一个课程", `.body`, `Color(.secondaryLabel)`
- `.borderedProminent` import button

### 2. Playback Detail

Pushed from home or course list.

#### Cover & Info

- Cover centered, width = screen width - 40pt, proportional height, 12pt corner radius
- No cover: `Color(.systemFill)` + `music.note` icon
- Below cover, 16pt gap:
  - Title: `.title2.bold()`, `Color(.label)`
  - Subtitle: sentence count + duration, `.caption`, `Color(.secondaryLabel)`

#### Playback Controls

Inside `.insetGrouped` Section:

- Progress: `Slider` with current/total time labels, `.caption.monospacedDigit()`
- Transport buttons, horizontally spaced:
  - `gobackward.15`
  - `backward.end.fill`
  - `play.fill` / `pause.fill` (larger, ~44pt tap area)
  - `forward.end.fill`
  - `goforward.15`
- All buttons `.plain` style, `Color(.label)`
- Play/pause slightly larger, no circular background

#### Feature Entries

Standard `.insetGrouped` Section, standard List Rows:

- "沉浸字幕" — `text.quote` icon, system chevron, pushes to immersive page
- "播放速度" — `speedometer` icon, current speed value on right, Picker on tap
- "A-B 复读" — `repeat` icon, Toggle

#### Navigation Bar

- Standard back arrow (automatic)
- `.inline` display mode, title empty or course name

### 3. Immersive Listening

Pushed from playback detail. Tab bar and navigation bar hidden. Status bar hidden.

#### Background

`Color.black`, full screen.

#### Subtitle Canvas

Full-screen `ScrollView`, vertical sentence layout.

- Current sentence: `.title2.bold()`, `Color.white`, full opacity
- Previous sentence: `.body`, `Color.white.opacity(0.4)`
- Older sentences: `Color.white.opacity(0.15)`, fading out
- Next sentence: `.body`, `Color.white.opacity(0.5)`
- Further future: `Color.white.opacity(0.2)`
- Sentence spacing: 24pt
- Current sentence auto-scrolls to vertical center
- Manual scroll suspends auto-follow; tapping current sentence resumes

#### Word Interaction

- Tap any word: system `.popover` or small bottom sheet
  - Word text: `.headline`
  - Definition (if available)
  - "保存到词汇" button
- Saved words: `Color.accentColor` underline

#### Control Overlay (Auto-hide)

Top and bottom bars overlaid on subtitle canvas, background `.ultraThinMaterial`.

**Top bar:**
- Left: close button `xmark`, standard system style
- Center: course title, `.caption`, white

**Bottom bar:**
- Progress: white-tinted Slider
- Transport buttons: same layout as playback detail, all white
- Safe area bottom inset

**Auto-hide logic:**
- Controls visible on entry
- 5 seconds no interaction: fade out with `withAnimation(.easeOut(duration: 0.3))`
- Tap any blank area in subtitle region: restore controls
- Interacting with controls resets 5-second timer

### 4. Vocabulary (词汇)

Standard `List(.insetGrouped)`, large title "词汇".

#### Search

`.searchable(text:)` in navigation bar.

#### Grouping

By save date. Each date is a Section with system default header (e.g., "今天", "3月24日").

#### Word Row

Standard List Row:

- Line 1: word text, `.body`, `Color(.label)`
- Line 2: definition, `.caption`, `Color(.secondaryLabel)`, 1-line truncation
- Line 3 (optional): source course name, `.caption2`, `Color(.tertiaryLabel)`
- System chevron

#### Swipe Actions

- Left swipe: delete (system destructive style)

#### Empty State

`ContentUnavailableView`:
- Icon: `character.book.closed`
- Title: "还没有保存的词汇"
- Description: "在沉浸听力中点击单词即可保存"

### 5. Review (复习)

Background `Color(.systemGroupedBackground)`, large title "复习".

#### State: Words Due

**Progress:** "3 / 12", `.caption`, `Color(.secondaryLabel)`, top of screen.

**Flashcard:**
- Background: `Color(.secondarySystemGroupedBackground)`
- Corner radius: 16pt
- Horizontal margin: 20pt
- Minimum height: 280pt
- Front: word centered, `.title.bold()`
- Back: definition + example, `.body`, top-aligned
- Tap to flip: `rotation3DEffect` animation

**Grade buttons** (appear after flip), four equal horizontal buttons:
- 忘了: `.bordered` tinted `Color.red`
- 模糊: `.bordered` tinted `Color.orange`
- 记得: `.bordered` tinted `Color.green`
- 简单: `.bordered` tinted `Color.blue`

#### State: Review Complete

- `checkmark.circle` icon, `Color.green`
- "今日复习完成"
- Stats: count + accuracy, `.caption`, `Color(.secondaryLabel)`
- "返回首页" button, `.bordered`

#### State: Nothing to Review

`ContentUnavailableView`:
- Icon: `rectangle.on.rectangle`
- Title: "没有需要复习的词汇"
- Description: "保存的词汇会按照记忆曲线安排复习"

### 6. Me (我的)

Standard `List(.insetGrouped)`, large title "我的".

#### Section 1: Library

- "全部课程" — `headphones` icon, course count badge + chevron, push to course list
- "收藏夹" — `folder` icon, chevron, push to collections

#### Section 2: Import

- "导入课程" — `square.and.arrow.down` icon, chevron, opens import sheet

#### Section 3: About

- "版本" — version number on right, not tappable

### 7. Course List (from Me)

Standard `List(.insetGrouped)`, title "全部课程".

- Each row: 60x60 cover (8pt radius) + title + sentence count
- Tap pushes to playback detail
- Left swipe: delete

### 8. Collections (from Me)

Standard `List(.insetGrouped)`, title "收藏夹".

- Navigation bar trailing `+` button: `.alert` with text field for new collection name
- Each collection is a Section with collection name as header
- Course rows within each section: cover thumbnail + title
- Swipe to delete on both collections and courses

### 9. Import Sheet

System `.sheet`:

- Title: "导入课程", `.headline`
- Description: supported formats, `.caption`, `Color(.secondaryLabel)`
- `.borderedProminent` "选择文件" button → system file picker
- Auto-dismiss on success, navigate to playback detail

## Components to Delete

The following custom UI components become unnecessary:

- `AppTheme.swift` — replaced by system colors
- `ThemeManager.swift` — no theme management needed
- `HeroCard.swift` — replaced by inline Hero implementation in HomeView
- `EmptyStateCard.swift` — replaced by `ContentUnavailableView`
- `SectionHeader.swift` — replaced by system List section headers
- `EmptyStateView.swift` — replaced by `ContentUnavailableView`

## Success Criteria

1. No custom color definitions anywhere in the project
2. Every List uses `.insetGrouped` style
3. The app looks and feels like a first-party Apple app
4. Immersive listening is the standout experience — dark, focused, distraction-free
5. All navigation follows standard iOS patterns (push, sheet, swipe back)
6. Dynamic Type works correctly throughout
