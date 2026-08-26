---
name: eli5
description: Creates a beginner-first visual explanation as one self-contained HTML file with large diagrams and few words. Use when the user invokes /eli5 <topic>, asks for a picture explainer, or wants a complex technical concept, code path, Agent, MCP, protocol, or system explained visually for a newcomer. Do not use for exhaustive reference documentation, production UI, or slide decks.
license: MIT; see LICENSE.upstream
compatibility: Requires file-write access. Browser preview is optional.
metadata:
  upstream-repository: anthropics/claude-plugins-community
  upstream-commit: 794af9e63d07fad17087dcab61f21f44cb48effd
  upstream-blob: ff6b33c9b3277c493e03e47fad327c6ad318e1d5
  upstream-author: Thariq Shihipar
---

# ELI5

Turn the topic from the invoking user message into a visual explanation for someone with no prior knowledge. Use large pictures and few words without sacrificing factual accuracy.

## Procedure

1. **Establish the topic and truth sources.**
   - Use the topic from the invoking user message; do not rely on a `$ARGUMENTS` placeholder.
   - If the invoking message contains no non-empty topic, ask for the topic and stop without creating an HTML file.
   - For repository-specific topics, inspect the smallest relevant code, configuration, tests, and documentation before drawing the system.
   - For claims that may be current or version-dependent, prefer official primary sources. Mark remaining uncertainty instead of inventing detail.

2. **Choose the teaching path.**
   - Write one plain-language mental model, then split it into 3–6 one-idea scenes.
   - Give every scene a visual that carries the idea: a flow, comparison, timeline, layered system, annotated object, or concrete analogy.
   - Introduce useful jargon only after showing what it does. Keep labels short enough to scan at a glance.

3. **Allocate the output path before writing.**
   - Use an explicit user-specified destination when provided.
   - Otherwise treat unique temporary-directory creation as a fail-closed preflight, not an example. On POSIX, first run `tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/eli5.XXXXXX")`, require a non-empty absolute result, and use only `$tmp_dir/eli5-<topic-slug>.html`.
   - On a non-POSIX host, use the native API that creates and returns a unique absolute temporary directory. If no unique absolute directory can be created, stop and report the failure without writing HTML.
   - Never use the current working directory, repository, or a fixed `eli5-*` directory as the default.

4. **Write one self-contained HTML file.**
   - Inline all CSS, SVG, and data. Do not use CDNs, remote fonts, external images, build steps, or runtime network requests.
   - Include a data-URI favicon such as `<link rel="icon" href="data:,">` so local preview does not request `/favicon.ico`.
   - Prefer HTML and inline SVG. Add JavaScript only when a small interaction materially improves understanding.
   - Include a one-sentence takeaway, the visual scenes, one simple example or analogy, and a short “remember this” ending.
   - Set document `lang`, a useful `title`, and a responsive viewport. Use semantic headings, high contrast, at least 16px body text, and visible focus styles.
   - Use native interactive controls with full keyboard operation. Do not rely on color alone. Give informative SVGs `role="img"` and an accessible name via `aria-label`, `aria-labelledby`, or `<title>`; a visible caption may supplement but not replace that name.
   - Preserve exact commands, paths, protocol names, error strings, and code tokens when they matter. Do not trade factual accuracy for simplicity.

5. **Verify the artifact.**
   - When browser tools are available, open the file and inspect narrow and wide layouts, console errors, clipped labels, broken connectors, unreadable contrast, keyboard Tab order, and the accessibility tree.
   - Confirm the artifact works offline and contains no unintended external `src`, `href`, `srcset`, CSS `url(...)`, or `@import` references. Same-page anchors are allowed.
   - If browser tools are unavailable, inspect the generated HTML directly and disclose that visual rendering was not verified.

6. **Deliver.**
   - Give one short sentence describing the explainer, then return the absolute HTML path.
   - Mention material uncertainty or an unavailable browser check. Do not paste the full HTML into the response.

## Provenance

Portable adaptation of Anthropic community marketplace `eli5`, originally authored by Thariq Shihipar. Upstream source: <https://github.com/anthropics/claude-plugins-community/blob/794af9e63d07fad17087dcab61f21f44cb48effd/eli5/skills/eli5/SKILL.md>.
