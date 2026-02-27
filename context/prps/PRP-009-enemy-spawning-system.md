# PRP-009: Enemy Spawning System

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-008 (Enemy Data Architecture)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Enemies need to spawn on the board following configurable rules:
1. **Default spawn zone:** Ranks 8-6 (top 3 rows)
2. **Customizable per enemy type:** Lane lock, exact tile, random zone
3. **Collision avoidance:** Don't spawn on occupied tiles (pieces or other enemies)
4. **Level scaling:** Different levels have different enemy counts
5. **Timing:** Spawn at level start (after armies are placed)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ENEMY SPAWNING FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Room Load                                                                  │
│       │                                                                      │
│       ▼                                                                      │
│   ┌───────────────────┐                                                     │
│   │   Game_Manager    │  ──▶ spawns ──▶ Enemy_Manager                       │
│   │   Create          │                                                     │
│   └───────────────────┘                                                     │
│                                         │                                    │
│                                         ▼                                    │
│                              ┌──────────────────────┐                       │
│                              │  enemy_spawn_for_    │                       │
│                              │  level()             │                       │
│                              └──────────┬───────────┘                       │
│                                         │                                    │
│               ┌─────────────────────────┼─────────────────────────┐         │
│               ▼                         ▼                         ▼         │
│   ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐  │
│   │ Get Level Config  │    │ Get Enemy Types   │    │ Calculate Count   │  │
│   │ (room variables)  │    │ (from config)     │    │ (min/max range)   │  │
│   └─────────┬─────────┘    └─────────┬─────────┘    └─────────┬─────────┘  │
│             │                        │                        │             │
│             └────────────────────────┴────────────────────────┘             │
│                                      │                                       │
│                                      ▼                                       │
│                           ┌─────────────────────┐                           │
│                           │ For each enemy:     │                           │
│                           │ enemy_find_spawn_   │                           │
│                           │ position()          │                           │
│                           └─────────┬───────────┘                           │
│                                     │                                        │
│                    ┌────────────────┼────────────────┐                      │
│                    ▼                ▼                ▼                      │
│           ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│           │ Exact Tile   │  │ Lane Lock    │  │ Random Zone  │             │
│           │ (specific)   │  │ (column)     │  │ (default)    │             │
│           └──────────────┘  └──────────────┘  └──────────────┘             │
│                    │                │                │                      │
│                    └────────────────┴────────────────┘                      │
│                                     │                                        │
│                                     ▼                                        │
│                           ┌─────────────────────┐                           │
│                           │ Check collision     │                           │
│                           │ (avoid occupied)    │                           │
│                           └─────────┬───────────┘                           │
│                                     │                                        │
│                                     ▼                                        │
│                           ┌─────────────────────┐                           │
│                           │ enemy_create()      │                           │
│                           │ (from PRP-008)      │                           │
│                           └─────────────────────┘                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Player_Army_Manager/Create_0.gml
  why: Pattern for army spawning

- path: objects/Enemy_Army_Manager/Create_0.gml
  why: Pattern for enemy piece spawning

- path: objects/Object_Manager/Create_0.gml
  why: Grid coordinate system (topleft_x/y)
```

### Files to Modify

```yaml
- path: objects/Enemy_Manager/Create_0.gml
  changes: Add spawn initialization and room variable reading

- path: objects/Game_Manager/Create_0.gml
  changes: Spawn Enemy_Manager (if not already)
```

### Files to Create

```yaml
- path: scripts/enemy_spawn_for_level/enemy_spawn_for_level.gml
  purpose: Main spawn orchestration function

- path: scripts/enemy_find_spawn_position/enemy_find_spawn_position.gml
  purpose: Find valid spawn tile for an enemy type

- path: scripts/enemy_is_tile_occupied/enemy_is_tile_occupied.gml
  purpose: Check if a tile has a piece or enemy

- path: scripts/enemy_get_level_config/enemy_get_level_config.gml
  purpose: Get spawn config for current room/level
```

---

## Implementation Blueprint

### Step 1: Level Configuration System

**File:** `scripts/enemy_get_level_config/enemy_get_level_config.gml`

```gml
/// @function enemy_get_level_config()
/// @returns {struct} Spawn configuration for current level
/// @description Returns enemy spawn configuration for the current room
function enemy_get_level_config() {
    // Default config (no enemies)
    var _config = {
        has_enemies: false,
        is_boss_level: false,
        enemy_count_min: 0,
        enemy_count_max: 0,
        enemy_types: [],
        spawn_delay_frames: 60  // 1 second after level start
    };
    
    // === LEVEL-SPECIFIC CONFIGURATIONS ===
    // Check room and set appropriate config
    
    switch (room) {
        case Ruined_Overworld:
            // World 1: Basic enemies, scaling with implied "level" (for now, fixed)
            _config.has_enemies = true;
            _config.enemy_count_min = 1;
            _config.enemy_count_max = 1;  // Start with just 1 for testing
            _config.enemy_types = ["placeholder"];
            break;
            
        case Pirate_Seas:
            _config.has_enemies = true;
            _config.enemy_count_min = 1;
            _config.enemy_count_max = 2;
            _config.enemy_types = ["placeholder"];
            break;
            
        case Fear_Factory:
            _config.has_enemies = true;
            _config.enemy_count_min = 2;
            _config.enemy_count_max = 3;
            _config.enemy_types = ["placeholder"];
            break;
            
        case Volcanic_Wasteland:
            _config.has_enemies = true;
            _config.enemy_count_min = 2;
            _config.enemy_count_max = 3;
            _config.enemy_types = ["placeholder"];
            break;
            
        // Boss levels - no standalone enemies
        case Volcanic_Wasteland_Boss:
            _config.has_enemies = false;
            _config.is_boss_level = true;
            // Boss config handled separately in PRP-017
            break;
            
        case Twisted_Carnival:
            _config.has_enemies = true;
            _config.enemy_count_min = 1;
            _config.enemy_count_max = 2;
            _config.enemy_types = ["placeholder"];
            break;
            
        case Void_Dimension:
            _config.has_enemies = true;
            _config.enemy_count_min = 2;
            _config.enemy_count_max = 3;
            _config.enemy_types = ["placeholder"];
            break;
            
        default:
            // Unknown room - no enemies
            _config.has_enemies = false;
            break;
    }
    
    return _config;
}
```

### Step 2: Tile Occupation Check

**File:** `scripts/enemy_is_tile_occupied/enemy_is_tile_occupied.gml`

```gml
/// @function enemy_is_tile_occupied(_col, _row)
/// @param {real} _col Board column (0-7)
/// @param {real} _row Board row (0-7)
/// @returns {bool} True if the tile is occupied by a piece or enemy
/// @description Checks if a tile is available for enemy spawning
function enemy_is_tile_occupied(_col, _row) {
    // Bounds check
    if (_col < 0 || _col >= 8 || _row < 0 || _row >= 8) {
        return true;  // Out of bounds = occupied
    }
    
    // Calculate pixel position (center of tile)
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // Check for chess pieces
    var _piece = instance_position(_x, _y, Chess_Piece_Obj);
    if (_piece != noone) {
        return true;
    }
    
    // Check for other enemies
    var _enemy = instance_position(_x, _y, Enemy_Obj);
    if (_enemy != noone) {
        return true;
    }
    
    // Check for world objects that block spawning (stepping stones, bridges don't block)
    // Void tiles - technically could spawn there but enemy would die
    var _tile = instance_position(_x, _y, Tile_Obj);
    if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
        if (_tile.tile_type == -1) {  // Void tile
            return true;
        }
        if (_tile.tile_type == 1) {  // Water tile
            // Check for bridge
            var _bridge = instance_position(_x, _y, Bridge_Obj);
            if (_bridge == noone) {
                return true;  // Water without bridge = occupied/unsafe
            }
        }
    }
    
    return false;  // Tile is available
}
```

### Step 3: Find Spawn Position

**File:** `scripts/enemy_find_spawn_position/enemy_find_spawn_position.gml`

```gml
/// @function enemy_find_spawn_position(_enemy_type_id)
/// @param {string} _enemy_type_id The enemy type ID
/// @returns {struct} {col, row} or undefined if no valid position found
/// @description Finds a valid spawn position for the given enemy type
function enemy_find_spawn_position(_enemy_type_id) {
    var _def = enemy_get_definition(_enemy_type_id);
    if (_def == undefined) {
        show_debug_message("ERROR: Cannot find spawn position - unknown enemy type: " + _enemy_type_id);
        return undefined;
    }
    
    var _rules = _def.spawn_rules;
    
    // === EXACT TILE SPAWN ===
    if (_rules.exact_tile != noone) {
        var _exact = _rules.exact_tile;
        if (!enemy_is_tile_occupied(_exact.col, _exact.row)) {
            return { col: _exact.col, row: _exact.row };
        }
        // Exact tile is occupied - no fallback
        show_debug_message("WARNING: Exact spawn tile occupied for " + _enemy_type_id);
        return undefined;
    }
    
    // === BUILD CANDIDATE TILES ===
    var _candidates = [];
    var _ranks = _rules.default_ranks;  // e.g., [0, 1, 2] for rows 0-2 (Ranks 8-6)
    var _lane = _rules.lane_lock;       // -1 for any, 0-7 for specific column
    
    // Determine column range
    var _col_start = (_lane >= 0) ? _lane : 0;
    var _col_end = (_lane >= 0) ? _lane : 7;
    
    // Build list of all valid candidates
    for (var _r = 0; _r < array_length(_ranks); _r++) {
        var _row = _ranks[_r];
        for (var _col = _col_start; _col <= _col_end; _col++) {
            if (!enemy_is_tile_occupied(_col, _row)) {
                array_push(_candidates, { col: _col, row: _row });
            }
        }
    }
    
    // === SELECT RANDOM CANDIDATE ===
    if (array_length(_candidates) == 0) {
        show_debug_message("WARNING: No valid spawn positions for " + _enemy_type_id);
        return undefined;
    }
    
    var _idx = irandom(array_length(_candidates) - 1);
    return _candidates[_idx];
}
```

### Step 4: Main Spawn Function

**File:** `scripts/enemy_spawn_for_level/enemy_spawn_for_level.gml`

```gml
/// @function enemy_spawn_for_level()
/// @description Spawns enemies for the current level based on configuration
function enemy_spawn_for_level() {
    // Get level configuration
    var _config = enemy_get_level_config();
    
    if (!_config.has_enemies) {
        show_debug_message("Enemy_Manager: No enemies for this level");
        return;
    }
    
    if (_config.is_boss_level) {
        show_debug_message("Enemy_Manager: Boss level - enemies handled by Boss_Manager");
        return;
    }
    
    // Determine enemy count
    var _count = irandom_range(_config.enemy_count_min, _config.enemy_count_max);
    show_debug_message("Enemy_Manager: Spawning " + string(_count) + " enemies...");
    
    // Spawn each enemy
    var _spawned = 0;
    var _attempts = 0;
    var _max_attempts = _count * 10;  // Prevent infinite loop
    
    while (_spawned < _count && _attempts < _max_attempts) {
        _attempts++;
        
        // Pick random enemy type from available types
        var _type_idx = irandom(array_length(_config.enemy_types) - 1);
        var _type_id = _config.enemy_types[_type_idx];
        
        // Find spawn position
        var _pos = enemy_find_spawn_position(_type_id);
        if (_pos == undefined) {
            continue;  // No valid position, try again
        }
        
        // Create the enemy
        var _enemy = enemy_create(_type_id, _pos.col, _pos.row);
        if (_enemy != noone) {
            _spawned++;
            show_debug_message("Enemy_Manager: Spawned " + _type_id + 
                " at (" + string(_pos.col) + "," + string(_pos.row) + ")");
        }
    }
    
    if (_spawned < _count) {
        show_debug_message("WARNING: Only spawned " + string(_spawned) + 
            "/" + string(_count) + " enemies (not enough valid positions)");
    }
    
    show_debug_message("Enemy_Manager: Spawn complete (" + string(_spawned) + " enemies)");
}
```

### Step 5: Update Enemy_Manager

**File:** `objects/Enemy_Manager/Create_0.gml` (additions)

```gml
/// Enemy_Manager Create Event (UPDATED)
/// Add after existing initialization code:

// === SPAWN INITIALIZATION ===
// Read level config
level_config = enemy_get_level_config();
spawn_complete = false;
spawn_delay_timer = level_config.spawn_delay_frames;

show_debug_message("Enemy_Manager: Level config loaded - " + 
    (level_config.has_enemies ? "enemies enabled" : "no enemies"));
```

**File:** `objects/Enemy_Manager/Step_0.gml` (updated)

```gml
/// Enemy_Manager Step Event
/// Handles spawn timing and turn processing

// === SPAWN TIMING ===
if (!spawn_complete && level_config.has_enemies) {
    spawn_delay_timer--;
    if (spawn_delay_timer <= 0) {
        enemy_spawn_for_level();
        spawn_complete = true;
    }
}

// === TURN PROCESSING ===
// (Implemented in PRP-010)
```

### Step 6: Integrate with Game_Manager

**File:** `objects/Game_Manager/Create_0.gml` (addition)

Add this after AI_Manager creation:

```gml
// Create Enemy Manager (handles enemy spawning and turns)
if (!instance_exists(Enemy_Manager)) {
    instance_create_depth(x, y, 0, Enemy_Manager);
}
```

---

## Level Scaling Details

Based on the design spec:

| Level Range | Enemy Count | Notes |
|-------------|-------------|-------|
| Levels 1-2 | 1 enemy | Introduction |
| Levels 3-4 | 2-3 enemies | Escalation |
| Boss Levels | 0 enemies | Boss fight only |

The `enemy_get_level_config()` function returns these values per room. To add true level progression within a world, we'd need to track level number (e.g., room variable or save data).

---

## Known Gotchas

### Spawn Timing
Enemies must spawn AFTER:
1. Tile grid is placed
2. Player army is spawned
3. Enemy army is spawned (for chess pieces)

The 60-frame delay ensures all other objects are initialized.

### Board Coordinates
- Row 0 = top of board (rank 8 in chess notation)
- Row 7 = bottom of board (rank 1)
- Column 0 = left (file A)
- Column 7 = right (file H)

Design spec says "ranks 8-6" which in 0-indexed terms is rows 0-2 (top 3 rows, black's side). Note: Row 0 = Rank 8 (topmost), Row 7 = Rank 1 (bottommost).

### Room Variable Approach vs Switch
We use a switch statement for simplicity. An alternative is room variables:
```gml
// In room editor, set these on each room:
room_set_variable(rm, "enemy_count_min", 1);
room_set_variable(rm, "enemy_count_max", 2);
```

This is more flexible but harder to manage across many rooms.

---

## Success Criteria

- [ ] `enemy_get_level_config()` returns correct config for each room
- [ ] `enemy_is_tile_occupied()` correctly detects pieces, enemies, and hazards
- [ ] `enemy_find_spawn_position()` returns valid positions
- [ ] `enemy_find_spawn_position()` respects spawn rules (lane lock, exact tile)
- [ ] `enemy_spawn_for_level()` spawns the correct number of enemies
- [ ] Enemies spawn after 1-second delay (visual smoothness)
- [ ] Enemies never spawn on occupied tiles
- [ ] Enemies never spawn on void or unbridged water tiles
- [ ] Boss levels have no enemy spawning
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Load Ruined_Overworld
2. Wait 1 second
3. Verify 1 enemy appears on rows 6-8
4. Check debug output for spawn messages

### Test Different Rooms

1. Navigate to each room with arrow keys
2. Verify enemy counts match configuration
3. Verify boss levels have no enemies

### Edge Case Test

1. Fill rows 6-8 with pieces manually (debug spawn all)
2. Try to spawn enemies
3. Verify warning message appears, no crash

### Debug Spawn Key

Add to `Game_Manager/KeyPress_69.gml`:
```gml
// E key: Force spawn enemies
if (!keyboard_check(vk_shift)) {
    if (instance_exists(Enemy_Manager)) {
        Enemy_Manager.spawn_complete = false;
        Enemy_Manager.spawn_delay_timer = 0;
    }
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-010** — Implement enemy turn system
2. **PRP-011** — Implement enemy movement (uses spawn positions)
