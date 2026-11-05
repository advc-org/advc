# advc

**A compiler for narrative games. Compiler and engine, in one.**

advc compiles point & click adventures, gamebooks and visual novels written
in its own language, **ADVL**: indented text that reads the way the game
plays. The output is **one native executable plus one packed asset file**.
No VM, no interpreter, no engine project to open: your game is a folder of
`.advf` files you can diff, grep, review and merge.

- **Threads that wait on the world.** Every scene runs as coroutines:
  `wait`, `say`, `walkto`, sounds and clicks park and resume. No callback
  sand, no state machine to hand-maintain.
- **Reactive UI.** Declare a `ui` block once; text, inventory and grids
  re-render when the variables they read change. Buttons carry hover and
  click in one line.
- **Acts like a genre engine.** Actor walking with pathfinding and arrival
  poses, lip-synced voices from your existing audio, verbs, inventories,
  option menus, camera and letterboxing: the adventure's hard parts are
  built in.
- **Save anywhere.** Every variable, actor and running thread is saved and
  restored exactly; players get a pause menu with save and load for free.
- **Errors worth reading.** A typo'd name, a wrong argument, an undeclared
  variable or a duplicate declaration is located in your source, colored,
  and answered with a suggestion. It fails before the game ever runs.
- **Assets that ship small.** Everything bakes into GPU-ready formats and
  packs into a single file: textures, atlases, audio, fonts and the bitcache
  of your compiled code.

## Install

```sh
curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh
```

The installer shows a plan (packs and sizes, where everything goes) and
asks before downloading. Uninstall the same careful way:

```sh
curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh -s -- --uninstall
```

## Quick start

Write a game, compile it, play it:

```sh
advc --release main.advf     # compile: one native exe + one .pak
./target/release/my-game     # play it
```

The demo folders here are full games. The smallest one, `crime-scene`, is a
complete noir point & click:

```sh
cd demos/crime-scene
advc --release main.advf
./target/release/crime-scene
```

This is what ADVL looks like, lifted straight from `demos/crime-scene`:

```adventure
// CRIME SCENE -- a one-room noir point-and-click.
import room

// 640x480 canvas in a 1280x960 window: pixel art stays crisp, subtitles
// render at the window's resolution.
default window 1280 960

// ESC pause menu: the screen dimmed under the engine-provided
// Save / Load / Exit list.
ui optionsMenu
    quad color=0,0,0,0.3
    grid items=$options cols=1 anchor=center padding=20
        text $item.label click=$item.callback

func entry
    font efmi
    call crimeScene
```

## The three demos

| demo | genre | size |
|------|-------|------|
| [`demos/crime-scene`](demos/crime-scene) | point & click, one room | a complete case: verbs, evidence, an officer to talk to |
| [`demos/king-relic`](demos/king-relic) | choose-your-adventure book | combat, gates, endings, sprites by plate difference |
| [`demos/love-is-near`](demos/love-is-near) | visual novel | a whole week in 1920x1080, choices and endings |

All three are rendered on the [website](https://advc.dev).

## The binary

`advc` keeps more than one version side by side and picks the newest
installed one:

```sh
advc main.advf      # compile this folder's game (the debug build)
advc --release      # the shipping build: one native exe + one .pak
advc --version      # installed compiler + runtime versions
advc --install 0.0.1  # fetch a specific version into the cache
advc --runtime <v>  # pick the runtime the compiler links against
```

## Documentation

The full language reference builds with the site: see
[docs/](https://github.com/advc-org/advc/tree/www/docs) on the `www` branch
(or the same pages at advc.dev), and `web/landing-page/devlog.md` for what
shipped, version by version.
