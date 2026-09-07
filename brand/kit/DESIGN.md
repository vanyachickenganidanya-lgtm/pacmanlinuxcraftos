---
version: alpha
name: "{{PROJECT}}"
description: Shizuku running on a ComputerCraft monitor. Pixel type, Material levers, 16×16 blocks, open source.
colors:
  void: "#080A09"
  chassis: "#101412"
  panel: "#171C19"
  rule: "#2A332E"
  dim: "#6E7B73"
  mist: "#C5CEC4"
  paper: "#E8EADC"
  phosphor: "#C8F542"
  amber: "#FFB020"
  panic: "#FF3B4E"
  cyan: "#3EE0C8"
  track-off: "#3A433D"
  on-phosphor: "#080A09"
  on-paper: "#080A09"
typography:
  display:
    fontFamily: Pixelify Sans
    fontSize: 64px
    fontWeight: 400
    lineHeight: 1.0
    letterSpacing: 0
  heading:
    fontFamily: Pixelify Sans
    fontSize: 32px
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: 0
  heading-sm:
    fontFamily: Pixelify Sans
    fontSize: 24px
    fontWeight: 400
    lineHeight: 1.25
    letterSpacing: 0
  body:
    fontFamily: Pixelify Sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0
  ui:
    fontFamily: Pixelify Sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0
  caption:
    fontFamily: Pixelify Sans
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0.04em
rounded:
  pixel: 0px
  sm: 8px
  settings: 24px
  switch: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 64px
components:
  button-primary:
    backgroundColor: "{colors.phosphor}"
    textColor: "{colors.on-phosphor}"
    rounded: "{rounded.sm}"
    padding: 12px 16px
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.mist}"
    rounded: "{rounded.sm}"
    padding: 12px 16px
  switch-on:
    backgroundColor: "{colors.phosphor}"
    textColor: "{colors.on-phosphor}"
    rounded: "{rounded.switch}"
    size: 52px 32px
  switch-off:
    backgroundColor: "transparent"
    textColor: "{colors.dim}"
    rounded: "{rounded.switch}"
    size: 52px 32px
  settings-group:
    backgroundColor: "{colors.chassis}"
    rounded: "{rounded.settings}"
    padding: 8px 0
  pref-row:
    backgroundColor: "{colors.chassis}"
    padding: 16px 20px
  card:
    backgroundColor: "{colors.chassis}"
    rounded: "{rounded.settings}"
    padding: 24px
  input:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.paper}"
    rounded: "{rounded.sm}"
    padding: 12px 16px
  badge:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.dim}"
    rounded: "{rounded.pixel}"
    padding: 4px 8px
---

# {{PROJECT}} — Style Reference

> Shizuku running on a ComputerCraft monitor

**Theme:** dark
**Density:** settings-list
**How to use:** copy this file to the **root** of any repo as `DESIGN.md`. Change `{{PROJECT}}` and the «This project» paragraph. Do not change tokens, type, switch, or Don't.

This is the author's visual law for **every** project, not one product. The author writes in **pixel fonts**, steals **Minecraft 16×16 language** (and random internet assets), and wants controls to feel like **Android Settings / Shizuku**. Open source is the politics.

Canvas `#080A09`. Phosphor `#C8F542` = switch ON. Type is pixel on a 4px grid. Icons 16×16 with `image-rendering: pixelated`. Switches are smooth Material, **not** pixelated. That contrast is the brand.

Agents (Cursor, Claude Code, Codex, v0, Lovable): if a decision is missing, default to *pixel text + M3 switch + original 16² icon*.

## This project

{{ONE SENTENCE: what this repo is. Example — «ccLinux, GNU/Linux-like TTY for CC: Tweaked».}}

Do not invent product facts. Do not turn it into a SaaS marketing site unless asked.

## Atmosphere (one sentence)

A Shizuku preference screen rendered on a ComputerCraft monitor: chunky glyphs, stolen-looking blocks, and a green lever that animates like Android.

## Four pillars

1. **Pixel type** — bitmap letters. Sizes 12 / 16 / 24 / 32 / 48 / 64 only.
2. **16×16 assets** — Minecraft inventory language, nearest-neighbor. Recreate; don't ship Mojang files in public git.
3. **Shizuku levers** — Material 3 switches 52×32, preference rows, 24px group radius.
4. **Open source** — GPL/MIT/Apache, credits, steal-with-attribution.

## Tokens — Colors

| Name | Value | Token | Role |
|------|-------|-------|------|
| Void | `#080A09` | `--color-void` | Canvas. Never pure `#000`. |
| Chassis | `#101412` | `--color-chassis` | Settings groups, cards. |
| Panel | `#171C19` | `--color-panel` | Nested wells, slots, inputs. |
| Rule | `#2A332E` | `--color-rule` | Hairlines between preference rows. |
| Dim | `#6E7B73` | `--color-dim` | Subtitles, off-thumb, idle. |
| Mist | `#C5CEC4` | `--color-mist` | Body and preference titles. |
| Paper | `#E8EADC` | `--color-paper` | Display type, inverse. |
| Phosphor | `#C8F542` | `--color-phosphor` | **ON state.** Switch track, primary CTA, caret. |
| Track off | `#3A433D` | `--color-track-off` | Unchecked switch outline. |
| Amber | `#FFB020` | `--color-amber` | Warnings only. Never ON. |
| Panic | `#FF3B4E` | `--color-panic` | Destructive. Never a switch-on color. |
| Cyan | `#3EE0C8` | `--color-cyan` | Links, info. |

### Color law

1. Switch ON = Phosphor track + Void thumb.
2. No iOS green `#34C759`, no Material You purple `#8b5cf6`. Phosphor only.
3. Panic is never toggle-on.
4. Body text is Mist/Paper. No colored paragraphs.

## Tokens — Typography

Pixel fonts only. **No Inter, Instrument Serif, IBM Plex, Roboto, Google Sans, Arial, system-ui as the voice.**

### Preferred — Monocraft (self-host, OFL)

Minecraft-shaped monospace **with Cyrillic**. Vendor when you can. https://github.com/IdreesInc/Monocraft

### Web stack

`"Pixelify Sans", "Unbounded", "Monocraft", sans-serif`

- Pixelify Sans — Latin titles, hex, English UI (Google Fonts).
- Unbounded — Russian when Pixelify has no glyph (Google Fonts, Cyrillic).
- Monocraft — in-app / Electron / games.

Google Fonts link:

```html
<link href="https://fonts.googleapis.com/css2?family=Pixelify+Sans:wght@400;500&family=Unbounded:wght@400;500&display=swap" rel="stylesheet">
```

### Rendering law

- Sizes **only** 12, 16, 24, 32, 48, 64.
- `font-smooth: never; -webkit-font-smoothing: none;` on bitmap faces.
- No italic. No weight ≥ 700. 400/500 only.
- Tracking 0 on display; 0.04em on 12px labels.

### Type scale

| Role | Size | Line height | Use |
|------|------|-------------|-----|
| cover | 64px | 1.0 | One word |
| heading | 32px | 1.2 | Sections |
| heading-sm | 24px | 1.25 | Cards, categories |
| body / ui | 16px | 1.5 / 1.3 | Reading, pref titles |
| caption | 12px | 1.3 | Subtitles, kbd, licenses |

## Tokens — Spacing & shape

**Base:** 4px (icons 16px). **Pref row:** 72px tall. **Group radius:** 24px. **Icon radius:** 0. **Switch:** pill.

| Radius | Value | Used on |
|--------|-------|---------|
| pixel | 0px | icons, hotbar, badges, selected list |
| sm | 8px | buttons, inputs |
| settings | 24px | preference groups, large cards |
| switch | 9999px | **M3 switch only** |

Do not round a 16×16 icon. Do not pixelate the switch.

## Components

### Material 3 / Shizuku switch (signature)

Copy Android, not iOS.

- 52×32, fully pill track.
- **OFF:** transparent, 2px Track-off outline, 16×16 Dim thumb at x=8.
- **ON:** Phosphor fill, 24×24 Void thumb at x=24.
- 200ms `cubic-bezier(0.2, 0, 0, 1)`.
- Never checkbox as the main boolean. Never iOS pill. Never a pixel-art toggle.

CSS (drop `tokens.css` or paste):

```css
.m3 {
  appearance: none;
  width: 52px; height: 32px;
  border-radius: 999px;
  border: 2px solid #3A433D;
  background: transparent;
  position: relative;
  cursor: pointer;
  transition: background 200ms cubic-bezier(0.2, 0, 0, 1),
              border-color 200ms cubic-bezier(0.2, 0, 0, 1);
}
.m3::after {
  content: "";
  position: absolute;
  width: 16px; height: 16px; border-radius: 99px;
  background: #6E7B73;
  left: 6px; top: 50%; transform: translateY(-50%);
  transition: 200ms cubic-bezier(0.2, 0, 0, 1);
}
.m3.on, .m3[aria-checked="true"] {
  background: #C8F542;
  border-color: #C8F542;
}
.m3.on::after, .m3[aria-checked="true"]::after {
  width: 24px; height: 24px;
  left: 22px;
  background: #080A09;
}
```

### Preference row (Android Settings)

Any boolean in any app uses this row: 32×32 pixel icon | 16px title + 12px Dim subtitle | M3 switch. Padding 16×20. Divider 1px Rule. Group in Chassis + 24px radius. Category header: 12px Phosphor.

### Primary button

Phosphor, Void text, 8px radius, 12×16 pad, 16px pixel type. **One** filled CTA per view. Switches do not count.

### Ghost button

1px Rule, Mist text, 8px radius.

### Input

Panel fill, 8px radius, 12×16 pad, 1px Rule. Focus: Rule → Phosphor, no fat ring.

### Pixel icon

16×16 or 32×32. `image-rendering: pixelated`. Scale ×2 ×3 ×4 only. `shape-rendering: crispEdges` on SVG.

### Hotbar slot

32–40px well, Minecraft bevel: light on top-left, dark on bottom-right. Radius 0.

### Selected list / GRUB / nav

Selected row = Phosphor fill + Void text. Same as switch ON.

## Asset policy (Minecraft + internet)

The author **does** steal Minecraft assets and random internet files. Follow that taste. Don't dump illegal blobs into public git.

**Do**

- 16×16 blocks, inventory bevel, hotbar, lever-as-idea.
- Recreate grass, dirt, chest, lever, redstone, command block, crafting table.
- Nearest-neighbor only. Never AI-upscale, never bilinear.
- Internet PNG: prefer OSI; else put the source URL under the file.

**Don't**

- Official Mojang textures, `Minecraft.ttf`, sounds from the jar in a public repo.
- Steve / Creeper / 3D as the **logo**.
- Mix programmer-art and smooth Material icons in one list.
- Blurry «AI pixel art».

## Open source

- Default: **MIT** for apps/libs, **GPL-3.0-or-later** for OS-like things, **Apache-2.0** when matching Android/Shizuku.
- Always `LICENSE` + Credits when an asset was taken.
- Don't put «all rights reserved» on a GPL/MIT tree.
- Don't pretend a stolen texture is original.

## Voice & copy

- Dry, short, Russian or English. Preference-subtitle energy: «Разрешить беспроводную отладку».
- Verbs: boot, mount, grant, toggle, sync, fork.
- Jokes: one line. No landing-page English («unlock», «reimagine», «seamless»).

## Motion

- Switch 200ms Material curve.
- Caret 1.1s step-end.
- No bounce, elastic, shimmer, auto-playing loops.

## Layout

- Settings-first: grouped lists, not 3-column SaaS icon grids.
- If the product is a TTY: one column, ~80 characters in the head.
- Web: max ~1120px. Section gap 64px.

## External sources — steal list (every project)

### Android Settings + [Shizuku](https://github.com/RikkaApps/Shizuku)

**Take:** preference list, 24px groups, 52×32 M3 switch, title+sub+toggle, category headers.

**Leave:** Roboto/Google Sans, Material purple, FAB, iOS toggles.

### Minecraft (language, not the jar)

**Take:** 16×16, inventory bevel, hotbar, block-as-icon, pixel rhythm.

**Leave:** official textures in git, 3D Steve, hearts HUD spam.

### Internet

**Take:** pixel PNGs, OSI fonts, credited screenshots as *reference*.

**Leave:** uncredited dumps into public git.

### [21st.dev](https://21st.dev)

**Take:** ASCII/terminal heroes, dark compact cards. [Hero ASCII one](https://21st.dev/@larsen66/components/hero-ascii-one).

**Leave:** rainbow borders, liquid metal, gradient CTAs, glassmorphism.

### [Refero Styles](https://styles.refero.design)

**Take:** DESIGN.md method, named colors, Don't list, one accent.

**Leave:** Inter, Monad serif, Linear `#e4f222`, their hex.

## Do

- Pixelify / Monocraft / Unbounded. Sizes 12/16/24/32/48/64.
- M3 switch 52×32, Phosphor ON, preference rows + 16×16 icons.
- `image-rendering: pixelated` on bitmaps.
- 24px radius on groups, 0px on icons.
- Credit OSS and stolen files.
- `@DESIGN.md` + «strictly follow DESIGN.md».

## Don't

- Inter, Roboto, Instrument Serif, IBM Plex, Google Sans.
- iOS switches, checkbox-as-main-boolean, pixelated fake switches.
- Smooth 24dp Material Icons as the only set.
- Weight 700+, italic display, magazine tracking.
- Gradients on buttons. AI purple. Liquid metal.
- Bilinear-upscaled Minecraft screenshots as UI icons.

## Agent prompt (paste into any project)

```
Read DESIGN.md at the repo root and follow it strictly.

This brand is: Shizuku running on a ComputerCraft monitor.
- Pixel fonts only (Pixelify Sans / Monocraft / Unbounded). Sizes 12/16/24/32/48/64.
- Icons 16×16 or 32×32, nearest-neighbor. Recreate Minecraft blocks; do not commit Mojang files.
- Booleans are Material 3 switches (52×32, phosphor ON), Android Settings rows — like Shizuku.
- Canvas #080A09, phosphor #C8F542, settings radius 24px, icon radius 0.
- No Inter, no serif, no iOS toggles, no rainbow, no liquid metal.

Skeletons: 21st.dev ASCII/terminal. Method: Refero DESIGN.md. Controls: AOSP Settings / Shizuku.
Assets: Minecraft language + internet, with credits, OSI preferred.
```

## Install in another repo

1. Copy this file to `DESIGN.md` in that repo's root.
2. Copy `AGENTS.md` next to it.
3. Copy `design.mdc` → `.cursor/rules/design.mdc`.
4. Optional: `tokens.css`.
5. Replace `{{PROJECT}}` and «This project».
6. First message to the agent: the prompt above.
