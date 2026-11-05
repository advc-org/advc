# devlog

## 2026-11-05 · advc 0.0.1 — the first light

advc is a compiler for narrative games: point & click adventures, gamebooks,
visual novels. You write scenes, dialogue and UI in **ADVL** — a small
indentation-based language — and `advc --release` hands you **one native
executable plus one packed asset file**. The whole toolchain is that binary.

What the first light includes:

- **A compiler that fails honestly.** Unknown commands, wrong arguments,
  undeclared names, duplicate declarations — each is a located error in your
  source, with a "did you mean" when one fits. An unbalanced `(` fails; a
  comment inside a `var` block doesn't.
- **One way to build: everything.** PNGs bake into BC7 textures, WAVs into
  FLAC, maps into one `.pak`, and the game module links against the runtime's
  bitcode with LLVM. Release builds carry no names — none of your files,
  actors or strings survive into the executable.
- **Games that test themselves.** A game is also its own test runner: a
  `.play` script drives the compiled binary over stdin, heads-down and
  deterministic, and can record an MP4 of itself while it plays. The suite
  runs every publish.
- **Three playable demos.** *The King's Relic* (a painted book with dice
  combat), *Malone: Case #4471* (a noir crime scene with verb panel and
  lip-synced voices — the one in the header video), and *Love is Near* (a
  life-sim visual novel). They live in `demos/` here: `.advf` sources and
  assets only; build them with the same compiler.

Honest limits: **macOS on Apple Silicon only today**, one executable type,
no store, no hot reload, no web or mobile targets yet. Everything above is
in the tree and exercised by tests (285 language + 70 compiler + 174 runtime
unit tests, 3 scripted game playthroughs).

Install, write `func entry`, and print one line — the rest is the language's
job, not yours.
