---
name: ui-review
description: Use when any change touches something the user will SEE, web UI, HTML templates, styles, dashboards, and before claiming a UI change is done. Screenshot-driven verification with Playwright: launch the app, capture desktop + mobile widths, READ the screenshots, fix, re-shoot, and pass only on what the pictures show. Supersedes "the build compiles" for anything visual. Complements the prove-it skill.
---

# ui-review

**You cannot see the page you just built.** You wrote the HTML, the CSS and
the JS, so you know exactly what the page *should* look like, and that is
precisely why you must never judge the result from memory. Code review of a
diff finds the misnamed selector; it cannot find the layout that collapsed,
the font that never loaded, or the button sitting 1200px wide of the form it
belongs to. This skill closes that loop with the only mechanism that works:
render it, look at it, fix it, render it again.

The design bar itself comes from the `frontend-design` skill: distinct
typography, a deliberate palette, spacing rhythm, no generic AI look,
responsive, accessible contrast and focus states. This skill checks the result
against that bar; pair with `frontend-design` when building new visual design.

## When it runs

After any change to something the user will see, and, like the `prove-it`
skill, **before the completion claim**. A UI change is only "done" when a
screenshot of the changed state has been looked at and it passes. The
`council` skill can review a UI diff too, but reviewers reading CSS cannot see
a broken layout either; this skill is the eyes, the council is the lawyer.

When the change is UI-adjacent but not visual (an API the UI calls, a build
config), this skill does not run. Say so in one line rather than
screenshotting everything defensively.

## The loop

### 1. Get the page on the screen

- Static HTML: a `file:///` URL, no server needed.
- Dev server already running: use its URL as-is. Never kill and restart
  someone else's server.
- Otherwise start the repo's own dev command in the background and write down
  the URL and the PID, so you can kill exactly that PID at the end.

### 2. Shoot it

Drive the browser with the `playwright-cli` skill: `playwright-cli open
<url>`, then `playwright-cli resize 1440 900` and `playwright-cli screenshot
--filename=<path>`. Use the `playwright` MCP tools (browser_navigate,
browser_snapshot, browser_take_screenshot, browser_resize) for exploratory
interaction: clicking through states, filling forms, checking hover and focus
behavior that a scripted screenshot will not show.

Two widths, every pass, no exceptions: **desktop 1440px and mobile 390px**.
Those two catch nearly everything a single-width screenshot misses: the
overflow nobody scrolled to see, the nav that fits on desktop and stacks into
oblivion on mobile. Add widths only when the layout changes at a named
breakpoint. Capture the full scrollable page when the change is below the
fold.

Screenshots go to a gitignored scratch directory (`.ui-review/`), never into
the commit. Playwright also writes snapshots and logs to `.playwright-cli/`
and `.playwright-mcp/` in the working directory. If any of the three is not
yet gitignored, add it to `.gitignore`; the PNGs are evidence, not artifacts.

### 3. LOOK at it

This is the step that gets skipped: **read each PNG**, one read per
screenshot, every pass, desktop and mobile both. A screenshot not read is a
screenshot not taken.

Judge against the concrete checklist, not against "looks fine":

- Does the page render as what it claims to be, or as an unstyled HTML wall
  (failed bundle, broken route)?
- Layout: content overflowing its container or the viewport, elements
  overlapping, text clipped, horizontal scroll on mobile.
- Design bar: distinct typography, a deliberate palette, consistent spacing
  rhythm, no generic AI look. Everything readable at WCAG AA contrast;
  visible keyboard focus states.
- State coverage: empty states, error states, loading states, the three
  screens the happy-path screenshot hides.

Check console errors too: `playwright-cli console`. A page full of "failed to
load font" and "Uncaught TypeError" entries under a screenshot that looks fine
is the classic two-signal miss.

### 4. Fix and re-shoot

Fix what the screenshots showed, then re-shoot with a new filename and read
the new PNGs. One fix, one re-shoot: a fix without a re-shoot is a claim
without evidence. `n` fixes mean `n+1` screenshots read.

### 5. Clean up

Kill the dev server PID you wrote down in step 1, and only that PID. If you
attached to someone else's server, leave it running. Close the browser session
(`playwright-cli close`).

### 6. Report with pictures

Hand back findings ranked: what the screenshots showed, what was fixed and
re-verified, what remains. Reference the screenshot paths inline. End with a
prove line in the `prove-it` skill format naming the final, read PNGs and the
console status.

## The pass bar

Rendering correctly is the entry ticket, not the pass. The floor: every
control reachable and usable; visible keyboard focus; readable contrast
(WCAG AA as the working bar); responsive down to 390px without horizontal
scroll; spacing consistent enough that two adjacent cards do not have
different paddings. "The design is meant to look rough" is not an exemption
from a broken layout; it is an exemption from taste complaints.

The bar for iterating on existing UI is deliberately lower than a from-scratch
design brief: this is verification, not art direction. For genuinely new
visual design, run `frontend-design` first and let this skill verify the
result against it.

## Out of scope

- **Non-visual changes.** Say so in one line instead of screenshotting
  defensively.
- **Cross-browser matrices, visual-regression baselines, pixel diffing.**
  Useful, heavier than a hobby repo needs. If pixel diffing is ever needed,
  bolt it onto this loop, don't replace it.
- **Taste round two.** A typography opinion is a design conversation, not a
  gate. The gate is: does it render, does it work at both widths, does it pass
  the quality floor.

## Failure modes worth naming

- "UI done" shipped with a collapsed layout: screenshot taken, never read.
- Fixed, claimed done, still broken: fix made, no re-shoot.
- Page silently broken on mobile: only the desktop width shot.
- Fonts or JS broken, screenshot looked fine: console errors not checked.
- A stray PNG in the diff: screenshots written into the tree instead of the
  gitignored scratch directory.

## Verification

You are done when: the app was on screen at both 1440px and 390px; every
screenshot was read; findings were fixed, re-shot and re-read; console errors
were checked; the browser session is closed and any server you started is
dead; and the handback names the screenshots in a `prove:` line.
