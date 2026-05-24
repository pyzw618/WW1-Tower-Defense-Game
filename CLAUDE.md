# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WW1-themed 2D tower defense game built with Godot 4.6 (GDScript). Germans attack along 3 fixed Path2D routes, French machine gun nests defend. Window size: 1672×941.

## Running the Game

Open `project.godot` in Godot 4.6 editor, press F5. Main scene is `res://scenes/main.tscn`. No build steps or external dependencies.

## Architecture

Three autoload singletons (registered in `project.godot` → `[autoload]`) serve as the game's backbone:

- **`GameManager`** — owns game state machine (`PREPARING → IN_WAVE → WAVE_COMPLETE → VICTORY/DEFEAT`), tracks lives. Emits `game_state_changed`, `lives_changed`.
- **`WaveManager`** — loads wave definitions, spawns enemies on assigned paths, tracks enemies alive, emits `wave_started`/`wave_completed`. Wave data is defined inline as array of dictionaries (scene path strings, counts, path indices, intervals) in `_build_wave_data()`.
- **`EconomyManager`** — gold tracking. `can_afford()`, `spend_gold()`, `add_gold()`, `get_refund()` (50% of invested).

These communicate exclusively through signals — no direct method calls between autoloads from scene scripts.

## Key Design Decisions

**Single enemy script** (`scripts/enemy_base.gd`): All 4 enemy types (EliteSoldier, Tank, Airplane, Zeppelin) use the same script with `@export` stats differing per scene file. No subclasses. Movement: each enemy creates a `PathFollow2D` as child of its assigned Path2D at runtime (`setup()`), reads `global_position` each frame.

**Enemy scaling**: Only the `$Sprite` node is scaled (`scale_factor` @export), NOT the root CharacterBody2D. This prevents the HealthBar (Control node) from shrinking.

**Single tower script** (`scripts/tower_base.gd`): One tower type (Machine Gun Nest), 3 upgrade levels via stat arrays (`damage_levels`, `fire_rate_levels`, `range_levels`). Targeting picks the enemy with highest `progress_ratio` in range (closest to path end). Upgrade swaps sprites from `mg_nest_lv1/2/3.png`.

**Path system**: 3 Path2D nodes in `main.tscn` under a `Paths` container. `main.gd` assigns them to `WaveManager.path_nodes` in `_ready()`. Each enemy spawn group specifies a `path_index` (0/1/2). Tower placement validates distance > 80px from all path baked points.

**Tower placement** (`scripts/tower_placement.gd`): Ghost preview follows mouse, green = valid, red = invalid. Click places tower. Validation: gold check, path distance check, tower-tower overlap check. Cancel with Esc or right-click.

**Tower clicking**: `tower_base.gd` sets `input_pickable = true`. `_input_event` emits `tower_clicked`. `game_ui.gd` connects this to `select_tower()` which shows upgrade/sell panel and range indicator circle.

**Bullets**: Area2D with `_draw()` circle visual. Track target in `_physics_process`, self-destruct after 3s lifetime. Connected `body_entered` calls `enemy.take_damage()`.

**Damage formula**: `max(raw_damage - armor, 1.0)`. Armor is flat reduction, minimum 1 damage.

## Scene Structure (main.tscn)

```
Main (Node2D, main.gd)
├── Background (Sprite2D, centered=false, pos=0,0)
├── Paths/Path2D, Path2D2, Path2D3 (3 attack routes from user's curve data)
├── Enemies (Node2D, z=1)       — dynamic enemy instances
├── Towers (Node2D, z=2)        — placed tower instances
├── Projectiles (Node2D, z=3)   — bullet instances
├── TowerPlacement (tower_placement.gd, z=100)
└── UI (CanvasLayer, game_ui.gd)
```

## Enemy/Tower Stats Reference

| Enemy | HP | Speed | Armor | Reward | Leak Cost |
|-------|-----|-------|-------|--------|-----------|
| Elite Soldier | 100 | 100 | 0 | 20 | 1 |
| Tank | 500 | 50 | 6 | 60 | 3 |
| Airplane | 150 | 170 | 0 | 35 | 2 |
| Zeppelin | 1000 | 35 | 4 | 200 | 5 |

Speed is normalized by path length: `progress_ratio += (speed * delta) / path_length`.

| Tower Level | Damage | Fire Rate | Range | Upgrade Cost |
|-------------|--------|-----------|-------|--------------|
| Lv1 | 15 | 0.5s | 250px | 100 (base) |
| Lv2 | 30 | 0.4s | 280px | 150 |
| Lv3 | 50 | 0.3s | 320px | 250 |

## Art Assets

Original large sprites in `art/` (500-950px). Scaled copies in `assets/` — same files but organized into `enemies/`, `towers/`, `ui/`. Elite soldier has 4 separate PNGs for animation frames (not a sprite sheet).

## Common Pitfalls

- Don't scale the root enemy node — scale `$Sprite` only, or the HealthBar becomes microscopic.
- PathFollow2D must be a child of a Path2D node to function. Enemies create these at runtime via `setup()`.
- `game_ui.gd` tower_placement @export references `../TowerPlacement` relative path from the UI CanvasLayer.
- Wave data uses `load()` with string paths (not `preload()`) to avoid errors before scenes exist.
- Bullet `_draw()` needs `queue_redraw()` called in `_ready()`.
