---
name: FixCity
description: An Arabic and English interface for reporting and following local repairs.
colors:
  action-teal: "#087F73"
  report-blue: "#164C70"
  navy: "#102D40"
  navy-raised: "#16394D"
  brand-gold: "#D5AD56"
  canvas: "#F5F4EF"
  surface: "#FFFFFF"
  muted: "#586872"
  pending: "#94620E"
  resolved: "#147653"
  error: "#B3261E"
  action-teal-dark: "#7AD7C5"
  canvas-dark: "#0B1C27"
  surface-dark: "#142B38"
  text-dark: "#E8EFF2"
  pending-dark: "#FFD38E"
  in-progress-dark: "#A0CFFF"
  resolved-dark: "#86DCB5"
  muted-dark: "#BAC8CF"
  error-dark: "#FFB4AB"
  primary-container: "#9EF2E4"
  on-primary-container: "#00201C"
  secondary-container: "#CCE8E2"
  on-secondary-container: "#05201C"
  outline: "#6F7977"
  outline-variant: "#BEC9C6"
  on-surface-variant: "#3F4947"
typography:
  headline-large:
    fontFamily: "Cairo"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.4
  headline-small:
    fontFamily: "Cairo"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.4
  title-large:
    fontFamily: "Cairo"
    fontSize: "20px"
    fontWeight: 700
  title-medium:
    fontFamily: "Cairo"
    fontSize: "16px"
    fontWeight: 700
  body-large:
    fontFamily: "Cairo"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.6
  body-medium:
    fontFamily: "Cairo"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.6
  button:
    fontFamily: "Cairo"
    fontSize: "16px"
    fontWeight: 700
  nav-label:
    fontFamily: "Cairo"
    fontSize: "12px"
    fontWeight: 600
rounded:
  chip: "8px"
  control: "12px"
  panel: "16px"
spacing:
  small: "8px"
  gap: "12px"
  inset: "16px"
  form-inset: "20px"
  page-inset: "24px"
  section: "28px"
  page-end: "32px"
components:
  button-primary:
    backgroundColor: "{colors.action-teal}"
    textColor: "{colors.surface}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "12px 24px"
  button-home-report:
    backgroundColor: "{colors.brand-gold}"
    textColor: "{colors.navy}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "12px 24px"
  button-outlined:
    textColor: "{colors.action-teal}"
    rounded: "{rounded.control}"
    padding: "12px 20px"
  button-text:
    textColor: "{colors.action-teal}"
  field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.navy}"
    rounded: "{rounded.control}"
    padding: "16px"
  category-choice:
    rounded: "{rounded.chip}"
    padding: "12px 10px"
  category-choice-selected:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
    rounded: "{rounded.chip}"
    padding: "12px 10px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.control}"
  navigation:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.navy}"
    typography: "{typography.nav-label}"
---

# Design System: FixCity

## Overview

**Creative North Star: "The neighbourhood service desk"**

FixCity uses a compact Material 3 interface for reporting a problem and following a repair. Navy anchors the identity, muted gold marks the street-pin logo and the home reporting action, and teal carries the shared action style. Warm page backgrounds and plain surface panels keep forms and report lists easy to scan.

Cairo covers Arabic and English throughout the app. The public demo states that it uses synthetic data, has no government affiliation and sends no real reports. This is a private student initiative with its own identity. InstaPay supplies partnership context only; its branding is not part of this system.

This document records the shared rules in [theme.dart](app/lib/theme.dart), [brand.dart](app/lib/brand.dart) and the current Flutter screens. Values written as `px` represent Flutter logical pixels. The light Material container and outline colors come from the installed `ColorScheme.fromSeed` implementation; the app still reads those roles from its theme. Dark variants are explicit where the source overrides them. The sidecar translates components to HTML for inspection; its previews use Cairo when the host has that font available.

**Key Characteristics:**

- Report and Track remain visible actions with distinct labels.
- Arabic and English share one type family and follow the locale's direction.
- Flat surfaces, outlined fields and text labels carry the hierarchy.
- Resident navigation stays separate from staff and district role access.

## Colors

The palette combines the team's navy and gold identity with teal actions and warm neutral page surfaces.

### Primary

Action teal is the theme seed and the standard button, link and selected-control color. The dark theme uses its lighter teal override. Material generates the associated containers, outlines and state layers.

**The Action Hierarchy Rule.** Use the shared teal action style by default. The home reporting button uses gold within its navy panel; preserve that local pairing.

### Secondary

Navy is the wordmark tile and home panel background. Report blue is the light theme's secondary color and the in-progress status color. Muted gold appears in the mark, the home reporting button and the dark theme's secondary role.

### Neutral

Warm canvas sits behind white surfaces in light mode. Dark mode uses a deep canvas, a lighter navy surface and pale text. Use `onSurfaceVariant` for supporting text and the generated outline roles for fields and separators.

Pending reports use amber, work in progress uses blue, and resolved reports use green. `statusColor` chooses a separate lighter value for each state in dark mode; its fallback is muted gray. Errors use the theme's error role.

**The Status Text Rule.** Keep a written status beside its color. Call the shared status helpers with the current brightness instead of copying a status hex into a screen.

## Typography

Cairo is bundled in [app/assets/fonts/Cairo.ttf](app/assets/fonts/Cairo.ttf) and registered in [pubspec.yaml](app/pubspec.yaml). The app uses it for headings, body copy and controls in both languages. There is no separate display or monospace family.

| Role | Use |
| --- | --- |
| Headline large | The demo's introductory heading. |
| Headline small | Page introductions and the home action panel. |
| Title large | Section headings and shared app bar titles. |
| Title medium | Category names and role choices. |
| Body large | Introductory copy that needs more room. |
| Body medium | Descriptions and form guidance. |
| Button | Shared elevated-button labels. |
| Navigation label | The phone navigation bar. |

Weights and sizes are recorded above. Unspecified metrics inherit Material 3. The wordmark is a local treatment at 25 logical pixels and weight 800; it stays left to right even in an Arabic screen. The shared full-width `FixGreenButton` uses a 15-pixel label and larger vertical padding.

**The Bilingual Type Rule.** Keep Cairo and the locale's text direction. Let content wrap and grow with the user's text scale; do not force labels into a fixed text height.

## Layout

The resident shell has four destinations: Home, Reports, Alerts and Account. Below 700 logical pixels it uses a bottom `NavigationBar`. At 700 and above it uses a labelled `NavigationRail` with a minimum width of 96. Staff and district access sits in Account in normal mode and in the demo's role choices.

The demo entry is centered with a maximum width of 720. The demo banner constrains routed content to 1120; this width cap does not apply to normal mode. Home and Account use 24-pixel page insets. Forms and Settings use 20-pixel insets. Gaps mostly follow the recorded spacing values, with 28 pixels between home sections.

Home categories wrap into two columns, then three when the category area reaches 600 logical pixels. Action buttons and form choice chips wrap across rows. Report lists use the available width and let the title and supporting status carry the reading order.

## Elevation & Depth

App bars, shared cards and elevated buttons have zero elevation. Their surface color, spacing and occasional outline separate them from the page. The app keeps Material's state layers, dialogs and modal sheets; those controls can still use framework elevation. There is no shared custom shadow scale.

**The Flat Surface Rule.** Keep resting page panels flat. Preserve the framework's focus, hover and pressed feedback when reusing Material controls.

## Shapes

Shared buttons, cards and fields use the control radius. Choice chips inherit Material 3's smaller radius. Home's navy panel, demo notices, Settings groups and several report containers use the panel radius. Dialogs and sheets retain local corner values; they do not establish another shared scale.

The logo is a gold location pin with a street-shaped opening on a navy rounded square. [brand.dart](app/lib/brand.dart) draws it on a 48-unit square with a 12-unit corner radius. The wordmark uses a 44-pixel mark and a 12-pixel text gap. [Logo options](docs/brand/index.html) contain the implemented street-pin SVG and two alternatives for review.

## Components

### Buttons

Elevated buttons use the primary action style, a minimum size of 48 by 52 logical pixels, and the shared control radius. Outlined and text buttons have a minimum size of 48 by 48. Material handles disabled, hover, focus and pressed states. The gold home action overrides the fill and text colors; its outlined Track companion uses white text on navy.

`FixGreenButton` fills its available width and adds 16-pixel vertical and 12-pixel horizontal padding. Reuse it for the existing full-width form actions. Do not replace its theme roles with fixed light-mode colors.

### Chips

The report form uses `ChoiceChip` for its six categories, with icons and written labels. Selected chips use Material's secondary container, checkmark and selected text role. Category chip padding is 12 pixels vertically and 10 horizontally. Staff status filters use the same control with 10-pixel vertical and 8-pixel horizontal padding.

### Cards / Containers

Shared cards have zero outer margin and zero elevation; their contents set the padding. Home category tiles use a surface-colored `Material` and `InkWell`, with a 16-pixel inset. Report rows retain their status text and open the corresponding detail or tracking route when tapped.

### Inputs / Fields

Fields have a surface fill, an outline and a 16-pixel inset. Focus changes the outline to the theme primary color at two logical pixels. `FixField` adds the existing label, optional prefix icon and text-input configuration. Keep validation messages and disabled states in the Material control instead of drawing a separate decorative input.

### Navigation

The navigation bar and rail share surface backgrounds and a primary-container selection indicator. Phone labels remain visible. The rail shows all labels and uses the primary color and bold text for the selected destination. Alerts can carry an unread-count badge.

### Demo identity

Every demo route sits beneath a banner with the demo notice, a route back to the role menu and a language switch. The entry screen states the absence of government affiliation and real report delivery before the visitor starts. Keep the original project and team attribution in the demo's credits.

## Do's and Don'ts

### Do:

- Do reuse the shared theme and Material controls before adding a local style.
- Do keep Arabic and English labels, direction and text scaling intact.
- Do pair report status colors with text and choose the correct dark variant.
- Do keep the demo notice and original team attribution visible in their existing places.

### Don't:

- Don't use government emblems or imply endorsement, affiliation or real report delivery.
- Don't copy InstaPay's visual identity or describe it as a FixCity partner.
- Don't turn local gray literals, small legacy captions or dialog radii into shared tokens.
- Don't describe the source review or screenshots as a complete accessibility audit.
