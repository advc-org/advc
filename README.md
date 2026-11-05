# advc

**A compiler for narrative games. Compiler and engine, in one.**

advc compiles point & click adventures, gamebooks and visual novels written
in its own language, **ADVL**: indented text that reads the way the game
plays. The output is **one native executable plus one packed asset file**.
No VM, no interpreter, no engine project to open: your game is a folder of
`.advf` files you can diff, grep, review and merge.

## Install

```sh
curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh
```

## Quick start

Write a game, compile it, play it:

```sh
advc --release              # compile: one native exe + one .pak
./target/release/my-game    # play it
```

See the demo folders to have a taste how games are made

```sh
cd demos/crime-scene
advc --release
./target/release/crime-scene
```

This is what ADVL looks like, lifted straight from `demos/crime-scene`:

```adventure
import room

ui optionsMenu
    quad color=0,0,0,0.3
    grid items=$options cols=1 anchor=center padding=20
        text $item.label click=$item.callback

func entry
    call crimeScene
```

## The three demos

| demo | genre |
|------|-------|
| [`demos/crime-scene`](demos/crime-scene) | point & click, one room |
| [`demos/king-relic`](demos/king-relic) | choose-your-adventure book |
| [`demos/love-is-near`](demos/love-is-near) | visual novel |

## Documentation

The full language reference builds with the site: see
[docs/](https://advc-org.github.io/advc/docs/index.html).
