# Ubundi Meet Design Contract

Ubundi Meet is an operational desktop application. Keep the meeting workspace calm, direct, and useful. Do not change information architecture when you change the brand theme.

## Themes

The application has two brand themes. The active theme is set with `data-brand-theme` on the root `html` element and saved in local storage as `ubundi-meet-brand-theme`.

### Ubundi

- Use a light, quiet workspace with white surfaces and navy interaction hierarchy.
- Use `#2F3498` for the primary action and active navigation.
- Use Manrope for body text and headings.
- Use the canonical Ubundi logo assets in `public/`.

### First Motive

- Use the canonical dark aubergine surface `#433B47`.
- Use warm ivory `#E8E2D7` for primary text.
- Use sage `#9CB89E` for constructive primary actions and active navigation.
- Use steel `#7FA9B8` for links, focus, and information states.
- Use lilac `#9B8FB8` for model and processing states only.
- Use coral `#D89B9F` for warnings and destructive states only.
- Use Manrope for body text and headings. Use Anonymous Pro, with system monospace fallbacks, for navigation and utility labels.
- Use translucent light washes for elevation. Do not add routine drop shadows to cards.
- Use the canonical First Motive mark in `public/first-motive-mark.svg`.

The source contract is `/Users/matthew-schramm-ubundi/Workspace.nosync/Work/Company Media:Assets/First Motive/01_Brand/Guideline-Reference/DESIGN.md`.

## Components

- Add new color decisions as semantic custom properties in `src/app/globals.css`.
- Do not add a brand-specific condition to each component when a token can express the same decision.
- Keep one primary action per view.
- Use visible `:focus-visible` outlines.
- Use short transitions only to explain hover, focus, disclosure, and theme state changes.
- Honor `prefers-reduced-motion`.

## Theme Toggle

Keep the theme toggle in the sidebar footer and provide it in the collapsed sidebar. It must state both choices, identify the active choice, work with a keyboard, and persist between application launches.
