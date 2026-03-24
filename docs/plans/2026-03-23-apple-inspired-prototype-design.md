# Apple-Inspired Prototype Design

**Design source:** user-provided low-fidelity prototype covering playlist, playback, immersive subtitles, vocabulary, profile, collections, and import flows.

**Design goal:** transform the prototype into a high-fidelity iOS experience aligned with Apple's product design philosophy: clear hierarchy, generous spacing, restrained color, calm surfaces, and content-first interaction.

**Confirmed decisions:**

- Keep bottom tabs as `Playlist`, `Vocabulary`, `Me`
- Use a light appearance inspired by Apple Music, Journal, and Photos
- Playback opens in a summary-first detail page
- Tapping the subtitle action enters a dedicated immersive playback page
- In immersive playback, controls auto-hide after 5 seconds of inactivity
- In immersive playback, bottom tabs are hidden
- Return from immersive playback uses native left-edge swipe back
- Subtitle rendering in immersive playback uses continuous text with current sentence highlight
- Import flow is `import first, classify later`
- Vocabulary uses grouped white cards with light borders, not colorful blocks

## Design Principles

1. Content leads; chrome stays secondary.
2. One screen should answer one user intention.
3. Motion and transitions should feel native to iOS, not custom-heavy.
4. Visual emphasis comes from spacing, typography, and contrast before color.
5. Management actions stay out of the main learning flow unless needed.

## Visual System

### Tone

The product should feel calm, bright, and quietly premium. It should resemble a native Apple app more than a stylized study tool.

### Color

- Primary background: warm off-white or system grouped background
- Cards: pure white or near-white
- Primary accent: system blue
- Text: use strong grayscale hierarchy
- Status colors: use sparingly for review state, deletion, or success feedback

Avoid large saturated panels, dense outlines, and dark sci-fi gradients.

### Typography

- Large navigation titles for top-level tabs
- Prominent course title on playback detail
- Compact secondary metadata
- Comfortable line height for subtitles and vocabulary examples

Typography should create most of the hierarchy without needing heavy decoration.

### Surfaces

- Rounded cards with soft elevation
- Grouped sections with breathing room between blocks
- Thin material overlays for transient controls in immersive playback
- Toolbar actions placed in standard navigation positions

## Information Architecture

### Bottom Navigation

- `Playlist`
- `Vocabulary`
- `Me`

The immersive playback screen is not a tab destination. It is a pushed detail page that temporarily takes over the interface.

### Tab Roles

#### Playlist

Purpose: answer "what should I play now?"

Content order:

1. Continue card
2. Recently added or recent courses
3. Collections entry

#### Vocabulary

Purpose: review collected words in a calm, scan-friendly format.

Content order:

1. Optional search or filter entry
2. Date-grouped vocabulary sections
3. Word cards with short definitions and examples

#### Me

Purpose: host library-management and personal organization surfaces.

Content order:

1. Collections entry
2. Secondary management entries such as import history or app settings

## Screen Specifications

### 1. Playlist

`Playlist` behaves like a listening home, not a generic list.

#### Structure

- Large title: `Playlist`
- Navigation bar trailing action: `+` for import
- Main continue card at the top
- Recent course section beneath
- Lightweight entry into Collections at the bottom

#### Continue Card

Must show:

- Course artwork
- Course title
- One-line summary or current context
- Progress or last-played indicator
- Primary play action

The card should feel like the main entry point of the product, similar to an Apple Music recommendation card but simpler and more utility-driven.

#### Recent Courses

Display recent items as either:

- horizontally scrolling cards, or
- a compact two-column card grid

Each card should include:

- artwork
- title
- short metadata

Avoid crowded metadata and avoid visible management controls on the card face.

#### Collections Entry

Do not dump full collection management onto the home screen. Use a single clean card or row that opens the dedicated Collections page.

### 2. Playback Detail

This is the default player page after opening a course.

#### Structure

- Large artwork near the top
- Course title and metadata
- Expandable or truncated summary text
- Bottom player region with playback controls
- Subtitle action button leading to immersive playback

#### Behavior

- This page is summary-first
- It should not show the full subtitle transcript inline by default
- The subtitle button is the explicit transition into immersive reading

The visual tone should echo Apple podcast and music detail pages: clear content block, restrained controls, and comfortable spacing.

### 3. Immersive Playback

This is a dedicated full-screen subtitle experience entered from the subtitle action.

#### Layout

- Full-screen continuous subtitle canvas
- Minimal top overlay with back affordance and course title
- Floating bottom playback controls on translucent material

#### Subtitle Rendering

Use continuous text layout with sentence-level highlight.

- Current sentence: highlighted with stronger contrast and accent emphasis
- Upcoming text: standard body color
- Past text: slightly lower contrast if needed

Do not present subtitle content as a dense scrolling transcript list. It should read more like a live reading surface.

#### Control Visibility

- Controls appear when the page opens
- After 5 seconds of no interaction, top and bottom controls fade out
- A tap anywhere restores them

#### Navigation Rules

- Bottom tab bar is hidden on this screen
- Return behavior follows native iOS left-edge swipe back
- Any visible back button should be visually lightweight and secondary

#### Scrolling Rules

- Auto-follow current sentence while playing
- If the user manually scrolls, temporarily suspend auto-follow
- Restore follow when the user taps the current sentence or equivalent resume-follow action

### 4. Vocabulary

`Vocabulary` should feel like a native grouped reading list.

#### Structure

- Large title: `Vocabulary`
- Optional trailing filter action
- Content grouped by date

#### Section Design

Each date becomes a section with:

- small gray date label
- vertically stacked white cards

#### Word Card Content

Each card contains:

- word or phrase
- pronunciation or part of speech
- short definition
- one example sentence
- optional source label if the word belongs to a course

#### Visual Style

- white card background
- light border or soft shadow
- rounded corners
- minimal color usage

The page should resemble Apple's note-like information grouping rather than a gamified flashcard wall.

### 5. Me

`Me` is a simple management hub.

#### Structure

- Large title: `Me`
- Primary entry card for `Collections`
- Secondary grouped rows for lower-priority management features

Avoid turning this page into a dense settings index.

### 6. Collections

Collections are managed in their own dedicated page under `Me`.

#### Structure

- Standard navigation title
- Trailing `+` action to create a collection
- Grouped list layout

#### Collection Presentation

Each collection is shown as a section card with:

- collection title
- contained courses as rows

Course rows may include:

- artwork thumbnail
- course title
- optional subtitle

#### Actions

- Create collection from navigation bar
- Delete via native swipe actions
- Avoid persistent red delete buttons in the default layout

Creating a collection should use a native-feeling sheet or alert with a single text field.

### 7. Import Flow

Import should feel like a standard iOS document workflow, not a setup wizard.

#### Entry Points

- `Playlist` navigation bar `+`
- possibly secondary import entry from library-related areas

#### Flow

1. User selects audio
2. System attempts to auto-match subtitle and artwork
3. If auto-match fails, prompt for manual selection
4. Show a concise confirmation view
5. Complete import and offer immediate playback

#### Post-Import Rule

The course is created first.

Classification into a collection happens later from:

- course detail, or
- `Me > Collections`

This keeps first-run friction low and matches Apple's tendency to defer optional structure until after content creation.

## Interaction Notes

### Gestures

- Left-edge swipe back is the primary return gesture from immersive playback
- Swipe actions are preferred for destructive collection management
- Tap gestures should be reserved for clear transitions and playback control visibility

### Motion

- Use native navigation transitions where possible
- Subtitle highlight changes should animate softly
- Control fade in and fade out should be subtle and quick

### Empty States

Empty states should stay light and instructional:

- explain what will appear here
- offer one primary next step
- avoid illustration-heavy or overly playful treatments

## Apple-Aligned Design Translation of the Prototype

Compared with the original wireframe, the upgraded design intentionally changes the following:

- replace mid-screen import buttons with navigation-bar actions
- separate summary playback and immersive subtitle playback into two distinct screens
- remove bottom tabs from immersive mode
- replace exposed delete buttons with native swipe actions
- reduce visual clutter by consolidating management tasks into `Me`
- transform colorful vocabulary blocks into restrained grouped cards

## Success Criteria

The design is successful if:

1. A first-time user can import and start playback without needing to understand collections first.
2. The user can move from summary playback into immersive subtitle reading in one obvious action.
3. Immersive playback feels distraction-free and native on iPhone.
4. Vocabulary remains easy to scan across dates without visual fatigue.
5. Collections and deletion flows feel like normal iOS management patterns.

## Recommended Next Step

Translate this design into a SwiftUI implementation plan covering:

- theme migration from dark to light Apple-style surfaces
- tab and navigation restructuring
- playback detail redesign
- immersive playback overlays and auto-hide behavior
- vocabulary grouped-card redesign
- collections and import flow cleanup
