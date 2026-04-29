# Detective Kari (Godot)

Single-player detective story prototype built with Godot 4.

## Features
- Story intro with protagonist Kari
- Incremental clue discovery
- Suspect selection
- Deduction result (success or failure branch)
- Reset and replay

## Run
1. Open this folder in Godot 4.x.
2. Press Play (`F5`).
3. Use `Inspect Scene` to collect clues.
4. Select a suspect and click `Make Deduction`.

## Project Structure
- `project.godot`: Godot project config
- `scenes/Main.tscn`: Main playable scene
- `scripts/game.gd`: Investigation and deduction logic
- `data/case_01.json`: Case content data
