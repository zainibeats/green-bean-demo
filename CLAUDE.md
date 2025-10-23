# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Green Bean" is a 2D platformer game built with Godot 4.5 using GDScript. The game features multiple levels with collectibles (coins, keys), a player character with various movement mechanics (walking, running, jumping, double-jumping, crouching), and a timing system for speedrunning.

## Development Commands

### Running the Game
- Open the project in Godot Editor: `godot project.godot`
- Run from command line: `godot --path /workspace`

### Exporting the Game
- Export configurations are defined in `export_presets.cfg`
- Build from Godot Editor: Project → Export

### Testing
- There is no automated test suite. Testing is done manually through the Godot Editor or running the game.
- Debug mode can be activated in-game by pressing the F12 key (see debug_mode input action)

## Architecture

### Autoload Singletons (Global State)
The game uses several autoload scripts that are always loaded and accessible from anywhere:

- **Gamestate** (`scripts/gamestate.gd`): Central game state manager controlling game flow, level progression, pause/resume, timer tracking, and level transitions. This is the primary controller for game lifecycle.
- **Music** (`scenes/music.tscn` → `scripts/music.gd`): Manages background music and menu music playback, volume control.
- **GlobalUiTime** (`scenes/global_ui_time.tscn`): Displays the game timer UI and final completion time.
- **FadetoBlack** (`scenes/FadetoBlack.tscn`): Scene transition effects.
- **ConfigManager** (`scripts/ConfigManager.gd`): Handles loading/saving player settings (volume levels) to `user://settings.cfg`.
- **GlobalStats** (`scripts/Global_Stats.gd`): Tracks persistent player statistics (total coins, keys, unlocked skins).

### Level Structure
- Levels are named sequentially: `game_1.tscn`, `game_2.tscn`, `game_3.tscn`
- Level progression is handled by `Gamestate.level_complete()` which increments the level number
- Main menu is `scenes/MainMenu.tscn`
- Tutorial levels: `moveintro.tscn`, `jumpintro.tscn`, `instructions.tscn`, `instructions2.tscn`

### Player System
The player (`scripts/player.gd`) is a CharacterBody2D with:
- Movement mechanics: walking (slower), running (default), crouching
- Jump system: single jump, double jump, coyote time (0.2s grace period for jumping after leaving ground)
- Edge detection when crouching (RayCast2D prevents falling off edges)
- Animation states: idle, walk, run, jump, doublejump, fall, crouch, death
- Multiple skin support (default girl sprite, unlockable boy sprite)
- Debug features: teleport to mouse click, instant level completion (when debug_mode enabled)

### Game Flow
1. Game starts at `MainMenu.tscn`
2. When first level loads, call `Gamestate.start_game()` to initialize timer and enable pause functionality
3. Player collects coins tracked by `game_manager.gd` (30 coins per level)
4. Player can complete level by reaching `level_finish` area
5. `Gamestate.level_complete()` transitions to next level or shows final time
6. Player can pause (Escape key or gamepad Start button) to access options menu
7. Options menu allows: resume, restart level, exit to main menu, adjust volume

### Configuration System
- User settings stored in `user://settings.cfg` (Godot user data directory)
- ConfigManager provides get/set/save functions for config values
- Audio settings: master_volume, music_volume (stored as decibels)
- Config is loaded on game start and saved when exiting to main menu

### Input Actions
Key input actions defined in `project.godot`:
- `jump`: Space, Gamepad A
- `move_left`: A, Left Arrow, Gamepad D-pad/Stick
- `move_right`: D, Right Arrow, Gamepad D-pad/Stick
- `walk`: Shift (hold to walk slower)
- `crouch`: Down Arrow, Ctrl
- `pause`: Escape, Gamepad Start
- `debug_mode`: F12 (enables debug features)
- `level_complete`: Numpad 0 (debug: instant level completion)
- `click_debug`: Left Mouse (debug: teleport to cursor)

### Scene Organization
- `scenes/`: All .tscn scene files (levels, menus, prefabs)
- `scripts/`: All .gd script files
- `assets/`: Game assets organized by type
  - `fonts/`: PixelOperator8.ttf (custom UI font)
  - `music/`: Background music files
  - `sounds/`: Sound effects
  - `sprites/`: Character and object sprites
  - `ui_etc/`: UI elements, icons, cursor

### Common Patterns

#### Creating Interactive Objects
Interactive objects (coins, keys, hazards) typically use Area2D nodes with collision detection:
```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):  # Or check specific type
        # Handle interaction
        queue_free()  # Remove object
```

#### Level Transitions
Level transitions should preserve game state:
```gdscript
Gamestate.level_complete()  # Handles scene change and state
```

#### Accessing Singletons
```gdscript
Gamestate.is_paused  # Check pause state
ConfigManager.get_value("audio", "master_volume", 0)  # Get config
GlobalStats.total_coins += 1  # Update global stats
Music.play_game_music()  # Control music
```

## Important Notes

- The game uses GL Compatibility rendering (for broader device support)
- Window size: 1920x1080, fullscreen by default
- Custom pixel art font and cursor
- Time.get_ticks_msec() is used for pause cooldown to prevent rapid toggling
- Player death triggers sound playback, then resets when sound finishes
- Music pitch is modified on final level completion (slowed to 0.95)
- Engine.time_scale is manipulated for pause (set to nearly 0) and resume (set to 1)

## Current Level Configuration
- Final level path: `res://scenes/game_3.tscn` (defined in `gamestate.gd`)
- Level transition increments by 2 currently (see comment: "CHANGE BACK TO 1 WHEN NOT ONLY ONE LEVEL")
- This suggests the game may be under development with placeholder levels

## Debug Features
When debug_mode is enabled (F12):
- Numpad 0: Instantly complete current level
- Left click: Teleport player to mouse cursor
- These features should be disabled/removed for production builds
