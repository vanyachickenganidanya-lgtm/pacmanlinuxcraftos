---
version: alpha
name: ccLinux
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
---

# ccLinux — Style Reference

> Shizuku running on a ComputerCraft monitor

**Theme:** dark
**Density:** settings-list
**Product:** ccLinux — GNU/Linux-like TTY for CC: Tweaked / ComputerCraft

This is not Linear, not Monad, not a SaaS serif. The author writes in **pixel fonts**, steals **Minecraft 16×16 language** (and random internet assets), and wants controls to feel like **Android Settings / Shizuku** — those fat Material 3 switches on the right of a preference row. Open source is the politics, not a badge.

Canvas stays near-black (`#080A09`). Phosphor (`#C8F542`) is the accent that turns a switch ON, same as Android dynamic color — one accent, many levers. Type is pixel, snapped to a 4px grid. Icons are 16×16 (or 32×32) with `image-rendering: pixelated`. Switches are smooth Material, **not** pixelated. That contrast is the brand.

This file is the contract for Cursor / Claude Code / Codex / v0. If a decision is missing, default to *pixel text + M3 switch + original 16² icon*.

## Atmosphere (one sentence)

A Shizuku preference screen rendered on a ComputerCraft monitor: chunky glyphs, stolen-looking blocks, and a single green lever that actually animates like Android.

## Four pillars

1. **Pixel type** — every letter is a bitmap. Sizes 12 / 16 / 24 / 32 / 48 / 64 only.
2. **16×16 assets** — Minecraft inventory language (nearest-neighbor). Recreate, don't ship Mojang files in this repo.
3. **Shizuku levers** — Material 3 switches, 52×32, preference rows, 24px group radius.
4. **Open source** — GPL/MIT/Apache, credits, steal-with-attribution.

## Tokens — Colors

| Name | Value | Token | Role |
|------|-------|-------|------|
| Void | `#080A09` | `--color-void` | Canvas. Never pure `#000`. |
| Chassis | `#101412` | `--color-chassis` | Settings groups, cards. |
| Panel | `#171C19` | `--color-panel` | Nested wells, inner slots. |
| Rule | `#2A332E` | `--color-rule` | Hairlines between preference rows. |
| Dim | `#6E7B73` | `--color-dim` | Subtitles, off-thumb, idle icons. |
| Mist | `#C5CEC4` | `--color-mist` | Body and preference titles. |
| Paper | `#E8EADC` | `--color-paper` | Display type, inverse. |
| Phosphor | `#C8F542` | `--color-phosphor` | **ON state.** Switch track, primary CTA, caret. |
| Track off | `#3A433D` | `--color-track-off` | Unchecked switch outline / off-track. |
| Amber | `#FFB020` | `--color-amber` | Warnings only. |
| Panic | `#FF3B4E` | `--color-panic` | Destructive. Never a switch-on color. |
| Cyan | `#3EE0C8` | `--color-cyan` | Links, info. |

### Color law

1. A switch ON = Phosphor track + Void thumb. That is the brand's "checked".
2. Do not use iOS green `#34C759` or purple Material You. Phosphor only.
3. Panic is never a toggle-on color.
4. Body text is Mist/Paper. No colored paragraphs.

## Tokens — Typography

Pixel fonts only. **No Inter, no Instrument Serif, no IBM Plex, no Roboto, no Google Sans.**

### Preferred — Monocraft (self-host, OFL)

Minecraft-shaped monospace with **Cyrillic**. Use this in-app whenever you can vendor the file. https://github.com/IdreesInc/Monocraft

### Web — Pixelify Sans + Unbounded

- **Pixelify Sans** (Google Fonts) — Latin titles, hex, English UI.
- **Unbounded** (Google Fonts, Cyrillic) — Russian sentences when Pixelify has no glyph.
- Stack: `"Pixelify Sans", "Unbounded", "Monocraft", sans-serif`

### Rendering law

- Sizes **only** 12, 16, 24, 32, 48, 64 (multiples of the pixel cell).
- `font-smooth: never; -webkit-font-smoothing: none;` when the face is bitmap.
- No italic, no weight ≥ 700. Pixelify 400/500.
- Never auto-kern like a magazine. Tracking 0 on display; 0.04em on 12px labels.

### Type scale

| Role | Size | Line height | Use |
|------|------|-------------|-----|
| cover | 64px | 1.0 | One word on the cover |
| heading | 32px | 1.2 | Section titles |
| heading-sm | 24px | 1.25 | Card titles, category |
| body / ui | 16px | 1.5 / 1.3 | Reading and preference titles |
| caption | 12px | 1.3 | Subtitles, kbd, licenses |

## Tokens — Spacing & shape

**Base unit:** 4px (and 16px for icons). **Settings row height:** 72px. **Group radius:** 24px (Android). **Icon radius:** 0 (pixel). **Switch radius:** pill.

| Radius | Value | Used on |
|--------|-------|---------|
| pixel | 0px | icons, hotbar slots, badges, GRUB |
| sm | 8px | small buttons, inputs |
| settings | 24px | preference groups, large cards |
| switch | 9999px | **the M3 switch only** |

Do not put 24px radius on a 16×16 icon. Do not pixelate the switch.

## Components

### Material 3 / Shizuku switch (signature)

This is the control the author actually likes. Copy Android, not iOS.

- Hit target 52×32. Track fully pill.
- **OFF:** transparent fill, 2px `Track off` outline, 16×16 Dim thumb at x=8.
- **ON:** Phosphor fill, no outline, 24×24 Void thumb at x=24. Optional pixel check on the thumb.
- Motion: 200ms `cubic-bezier(0.2, 0, 0, 1)` — Material standard, not bounce.
- Never a checkbox. Never an iOS 51×31 fat green pill. Never a pixel-art toggle (the lever is smooth on purpose).

### Preference row (Android Settings)

Left: 32×32 pixel icon (16×16 @ 2×, nearest). Middle: 16px title + 12px Dim subtitle. Right: M3 switch. Row padding 16×20. Divider 1px Rule. Group in a 24px-radius Chassis container. Category header: 12px Phosphor, 16px padding.

This layout is how Shizuku and AOSP Settings present power. Reuse it for any boolean.

### Primary button

Phosphor fill, Void text, 8px radius, 12×16 padding, 16px pixel type. One filled CTA per view. Switches do not count as that CTA.

### Ghost button

1px Rule, Mist text, 8px radius.

### Pixel icon

16×16 or 32×32 grid. `image-rendering: pixelated` / `crisp-edges`. Scale only by integers (2×, 3×, 4×). No SVG outlines that anti-alias into mush. No 24px Material icons as the default (those are the *fallback* if a block doesn't exist).

### Hotbar slot

32×32 Panel well, 1px Paper highlight on top-left, 1px Void on bottom-right (Minecraft inventory bevel). Radius 0.

### Terminal / GRUB

Still valid for the OS itself. Pixel type inside. Selected GRUB row = Phosphor fill, same as switch ON.

## Asset policy (Minecraft + internet)

The author **does** steal Minecraft assets and random files from the internet. Agents should follow that taste without dumping illegal blobs into git.

**Do**

- Speak vanilla: 16×16 blocks, inventory bevels, hotbar, dirt/stone/grass language, levers as the *idea* of a switch.
- Recreate blocks as original pixel art (grass, dirt, chest, lever, redstone, command block, crafting table).
- Scale with nearest-neighbor only. Never AI-upscale, never bilinear.
- For personal/fan CraftOS skins: vanilla-adjacent is on-brand.
- Internet assets: prefer OSI licenses; if you must use a random PNG, credit the URL under the file.

**Don't**

- Commit official Mojang textures, `Minecraft.ttf`, sounds, or splash from the jar into this public repo.
- Use Steve / Creeper / realistic 3D as the **logo**.
- Mix Faithful/programmer-art with smooth Material icons in the same row (one icon language per list).
- Generate "AI pixel art" that is blurry 64×64 noise.

## Open source

Love of opensource is part of the voice, not a footer afterthought.

- Default license posture: **GPL-3.0-or-later** for the OS, **MIT** for tiny snippets, **Apache-2.0** when matching Shizuku/Android.
- Always keep `LICENSE`, authors, and a Credits line when an asset was taken.
- Name the parents: CC: Tweaked, Arch/pacman, Shizuku (RikkaApps, Apache-2.0), Monocraft (OFL).
- Don't pretend a stolen texture is original. Don't put "all rights reserved" on a GPL tree.

## Voice & copy

- Dry, short, Russian or English. Like a preference subtitle: «Разрешить беспроводную отладку».
- Verbs: boot, mount, grant, toggle, sync, fork.
- Jokes: one line. Never a landing-page paragraph.
- Product name **ccLinux**. Repo `pacmanlinuxcraftos`.

## Motion

- Switch: 200ms Material curve.
- Caret: 1.1s step-end blink.
- No bounce, no elastic, no shimmer gradients.

## External sources — steal list

### Android Settings + [Shizuku](https://github.com/RikkaApps/Shizuku)

**Take:** preference list, 24px grouped cards, 52×32 M3 switch, title+subtitle+toggle, category headers, status at the top ("running").

**Leave:** Roboto/Google Sans, Material purple, FAB, nav rail, iOS toggles.

### Minecraft (language, not the jar)

**Take:** 16×16 grid, inventory bevel, hotbar, block-as-icon, pixel font rhythm.

**Leave:** official textures in git, 3D Steve, hearts HUD as decoration spam.

### [21st.dev](https://21st.dev)

**Take:** ASCII/terminal heroes, dark compact cards. Example: [Hero ASCII one](https://21st.dev/@larsen66/components/hero-ascii-one).

**Leave:** rainbow borders, liquid metal, gradient CTAs, glassmorphism.

### [Refero Styles](https://styles.refero.design)

**Take the method** (DESIGN.md, named colors, Don't list). Linear = one accent. **Do not** take Inter, serif-editorial Monad, or their hex.

## Do

- Pixelify/Monocraft/Unbounded. Sizes 12/16/24/32/48/64.
- M3 switch 52×32, Phosphor when ON, preference rows with 16×16 icons.
- `image-rendering: pixelated` on all bitmaps.
- 24px radius on settings groups, 0px on icons.
- Credit OSS and stolen internet files.
- `@DESIGN.md` + "strictly follow DESIGN.md".

## Don't

- Instrument Serif, Inter, Roboto, IBM Plex, Google Sans.
- iOS switches, checkboxes-as-the-main-boolean, pixelated fake switches.
- Smooth 24dp Material Icons as the only icon set.
- Weight 700+, italic display, magazine tracking.
- Gradients on buttons. AI purple. Liquid metal.
- Bilinear-upscaled Minecraft screenshots as UI icons.

## Agent prompt (paste)

```
Read DESIGN.md at the repo root and follow it strictly.

This brand is: Shizuku running on a ComputerCraft monitor.
- Pixel fonts only (Pixelify Sans / Monocraft / Unbounded). Sizes 12/16/24/32/48/64.
- Icons are 16×16 or 32×32, nearest-neighbor. Recreate Minecraft blocks; do not commit Mojang files.
- Booleans are Material 3 switches (52×32, phosphor ON), in Android Settings preference rows — like Shizuku.
- Canvas #080A09, phosphor #C8F542, settings radius 24px, icon radius 0.
- No Inter, no serif, no iOS toggles, no rainbow, no liquid metal.

Skeletons: 21st.dev ASCII/terminal. Method: Refero DESIGN.md. Controls: AOSP Settings / Shizuku.
Assets: Minecraft language + internet, with credits, OSI licenses preferred.
```

## File map

| File | Who reads it |
|------|----------------|
| `DESIGN.md` | Every coding agent. Source of truth. |
| `AGENTS.md` | Agent bootstrap. |
| `brand/index.html` | Human-readable brand book. |
| `.cursor/rules/design.mdc` | Cursor auto-context. |
