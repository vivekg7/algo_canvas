# UI Improvement Plan — Algo Canvas

Comprehensive audit of the current UI layer with prioritized improvements. All suggestions respect the project philosophy: no new dependencies, Flutter built-ins only, offline-first, educational clarity.

---

## Current State Summary

- **Design system**: Material Design 3, full compliance, no custom components
- **Themes**: 4 modes (System, Light, Dark, AMOLED) + 10 accent colors
- **Typography**: Material 3 defaults only (Roboto/SF Pro) — no custom fonts
- **Animations**: Zero explicit animations — state changes are instant, screen transitions are default `MaterialPageRoute`
- **Cards**: Standard Material cards with plain text, two small badges (category + mode)
- **Painters**: Hard-coded color palettes per algorithm type — do not respect theme accent color
- **Playback controls**: Standard `IconButton` + `Slider`, functional but visually plain
- **Settings**: Vanilla Flutter patterns, no custom design
- **Navigation**: Standard push/pop, no custom transitions

---

## 1. Typography — Custom Font Pairing

**Problem**: Default platform fonts (Roboto/SF Pro) make the app look generic. No visual identity in text.

**Solution**: Bundle 1-2 Google Fonts as static `.ttf` files in `assets/fonts/` (no network calls — stays offline).

**Recommended pairing**:

- **Display / Algorithm titles**: A geometric monospace like **JetBrains Mono** or **Space Mono** — reinforces the code/algorithm identity
- **Body / Descriptions**: **Source Sans 3** or **Nunito Sans** — clean, readable, pairs well with monospace headers

**Implementation**:

- Download `.ttf` files, place in `assets/fonts/`
- Declare in `pubspec.yaml` under `fonts:`
- Override `TextTheme` in `app_theme.dart` with `fontFamily` per style
- Zero dependencies — just asset files and theme config

**Effort**: Low | **Impact**: High — instant personality boost

---

## 2. Painter Colors Synced with Theme Accent

**Problem**: This is the biggest visual inconsistency. Changing the accent color (e.g., Deep Purple to Teal) changes the app chrome but visualizations stay the same hard-coded blue/green/red. The canvas and the UI shell feel disconnected.

**Current hard-coded examples**:

- Sorting: comparing = blue, swapping = red, sorted = green, pivot = amber
- Pathfinding: visited = blue, queued = amber, path = green, start = blue, end = purple
- Graph: visiting = blue, visited = green, highlighted edges = green

**Solution**: Pass theme colors into painters and derive at least the "primary action" color from the accent:

| Visualization state           | Current color    | Proposed source                 |
| ----------------------------- | ---------------- | ------------------------------- |
| Comparing / Visiting / Active | Hard-coded blue  | Theme `primary`                 |
| Sorted / Found / Complete     | Hard-coded green | Keep green (semantic: success)  |
| Swapping / Error / Conflict   | Hard-coded red   | Keep red (semantic: alert)      |
| Pivot / Highlighted / Special | Hard-coded amber | Theme `tertiary` or `secondary` |

**Implementation**:

- Add `ColorScheme` parameter to painter constructors (or pass via a lightweight config)
- Replace hard-coded "action" colors with `colorScheme.primary`, `colorScheme.tertiary`
- Keep semantic colors (green=success, red=alert) unchanged
- Update all 8+ painters

**Effort**: Medium | **Impact**: High — fixes the biggest visual disconnect

---

## 3. Algorithm Card Redesign

**Problem**: Cards are standard Material cards with flat text. No visual grouping by category, no icons, no visual hierarchy beyond text size.

**Improvements**:

### 3a. Category accent stripe

Add a thin (3-4px) colored stripe along the left edge of each card, colored by category. Gives instant visual grouping without reading the badge.

### 3b. Category icons

Add a small icon per category in the card (e.g., bar chart for Sorting, network/tree for Graph, grid for Pathfinding). Currently there are zero visual icons on cards — everything is text-only.

### 3c. Staggered entrance animation

Use `AnimationController` + `SlideTransition` + `FadeTransition` with a ~100-150ms stagger per card when the home screen loads. Even minimal stagger makes the grid feel alive vs. a static wall of cards.

### 3d. Elevation on interaction

Use `AnimatedContainer` for a subtle elevation bump on press/hover via `InkWell` callbacks.

**Effort**: Low | **Impact**: Medium — better visual hierarchy and personality

---

## 4. Page Transitions

**Problem**: Default `MaterialPageRoute` transitions feel generic. No intentional motion design.

**Solution**: Custom `PageRouteBuilder` with fade + slight vertical slide when navigating to the visualizer screen:

```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => VisualizerScreen(...),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  },
)
```

Pure Flutter, no packages. Small change, but makes navigation feel intentional.

**Effort**: Low | **Impact**: Medium

---

## 5. Playback Controls — Visual Polish

**Problem**: Playback bar uses standard `IconButton` + `Slider` — functional but plain.

**Improvements**:

### 5a. Animated play/pause icon

Use Flutter's built-in `AnimatedIcon` with `AnimatedIcons.play_pause` for a smooth morph between play and pause states. Zero-effort polish.

### 5b. Custom slider thumb

A small circle with accent color glow, or a pill-shaped thumb showing the current step number.

### 5c. Speed selector as a pill/chip

Replace plain text button with a styled chip/pill — makes it feel tappable and shows current speed more prominently.

### 5d. Thin progress bar below app bar

A `LinearProgressIndicator` showing algorithm progress, visible even when controls are at the bottom.

**Effort**: Medium | **Impact**: Medium — premium feel for the most-used controls

---

## 6. Color Legend Redesign

**Problem**: Simple row of plain circles (10px) + text labels. Functional but visually flat.

**Improvements**:

- Replace circles with **rounded rectangle chips** — more readable, more modern
- Add a **subtle background container** with rounded corners and `surfaceVariant` fill — visually groups the legend as a panel
- **Animate legend items in** when a new algorithm loads — simple fade + scale transition

**Effort**: Low | **Impact**: Low-Medium

---

## 7. Home Screen — Search & Filter Polish

### 7a. Animated search bar

Start as a search icon in the app bar, expand to full-width text field on tap using `AnimatedContainer` or `SizeTransition`.

### 7b. Category chips with icons

Add a small leading icon to each category chip (sorting bars for Sorting, tree for Tree, grid for Pathfinding, etc.).

### 7c. Count badge on filter chips

Show algorithm count on the active chip: "Sorting (10)" — tells users how many are in each category at a glance.

### 7d. Empty state illustration

When search returns no results, show a simple custom-painted illustration instead of plain text.

**Effort**: Low-Medium | **Impact**: Medium

---

## 8. Canvas Area — Micro-improvements

### 8a. Rounded corners on canvas

Clip the `CustomPaint` with `ClipRRect` for a softer, more contained look.

### 8b. Subtle border

1px `surfaceVariant` border around the canvas — visually separates visualization from surrounding UI.

### 8c. Pinch-to-zoom

Wrap applicable visualizations (graph, geometry, tree) with `InteractiveViewer` — built-in Flutter widget, zero dependencies. Especially useful for complex graphs.

**Effort**: Low | **Impact**: Medium (especially pinch-to-zoom)

---

## 9. Settings Screen — Less Generic

### 9a. Animated accent color selection

Scale animation on the selected swatch, smooth background transition when accent changes.

### 9b. Live theme preview

Show a tiny preview card that updates in real-time as you toggle Light/Dark/AMOLED — so users see the effect before leaving settings.

**Effort**: Medium | **Impact**: Low (settings used infrequently)

---

## 10. Splash / App Launch Animation

**Problem**: Static splash screen, no branded animation.

**Solution**: A brief animation on launch — a few bars sorting themselves, or the app icon scaling in with a fade. Sets the tone immediately and reinforces the "algorithm visualization" identity.

**Effort**: Medium | **Impact**: Low-Medium (first impression only, but memorable)

---

## Priority Ranking

| Priority | Improvement                       | Effort  | Impact  | Section |
| -------- | --------------------------------- | ------- | ------- | ------- |
| 1        | Painter colors synced with accent | Medium  | High    | 2       |
| 2        | Custom font pairing               | Low     | High    | 1       |
| 3        | Card category stripe + icons      | Low     | Medium  | 3a, 3b  |
| 4        | Animated play/pause icon          | Low     | Medium  | 5a      |
| 5        | Page transitions                  | Low     | Medium  | 4       |
| 6        | Card stagger animation            | Low     | Medium  | 3c      |
| 7        | Pinch-to-zoom on canvas           | Low     | Medium  | 8c      |
| 8        | Search bar animation + chip icons | Low-Med | Medium  | 7a, 7b  |
| 9        | Playback slider/controls polish   | Medium  | Medium  | 5b, 5c  |
| 10       | Color legend redesign             | Low     | Low-Med | 6       |
| 11       | Canvas rounded corners + border   | Low     | Low     | 8a, 8b  |
| 12       | Settings live preview             | Medium  | Low     | 9       |
| 13       | Splash animation                  | Medium  | Low-Med | 10      |

---

## Implementation Notes

- All improvements use **Flutter built-ins only** — no new packages
- Font files are bundled as assets (offline, no Google Fonts package)
- Animations use `AnimationController`, `AnimatedIcon`, `AnimatedContainer`, `FadeTransition`, `SlideTransition` — all from the Flutter SDK
- Painter color sync requires touching all 8+ painter files but the pattern is mechanical
- Changes are independent — can be implemented in any order without conflicts
