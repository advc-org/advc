# devlog

## v0.0.2 Highlights

- Save files now survive new builds.

## New

### Save migration (advc save-migration <from> <to>)

`save-migration` generate an .advm file. These files allow the developer to specify how he wants the game save state to return, when the block the save file points to was deleted in the current version.

```advm
// main.advf
// func optWhat
//    func optWhat
//        crime::askedWhat = 1   // b0 = a0
//        wait sequence
//            talk AskWhat       // b1 = a1
//            talk OffWhat1      // b2 = a2
//  -         talk OffWhat2      // b3
//            talk What3         // b4 = a3
//        end                    // b5 = a4
//        crime::talking = 0     // b6 = a5
remap b3 to a3 // proposed
```

The remap row: `remap b3 to a3` means a save parked at old block b3 (the deleted OffWhat2 line) resumes at new block a3 (What3, the next surviving line).

### Voice and dialogue

- `say` is folded into the `talk` command.

## 2026-11-05 - 0.0.1 · Hello

Hello,

We are new here. And we would like to introduce ourselves:

advc is a compiler for narrative games: point & click adventures, gamebooks,
visual novels. You write scenes, dialogue and UI in **ADVL**, our
indentation-based language, and `advc --release` hands you **one native
executable plus one packed asset file**.

Feel free to try us:

```
curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh
```
