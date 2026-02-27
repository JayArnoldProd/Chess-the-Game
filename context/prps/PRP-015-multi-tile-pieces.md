# PRP-015: Multi-Tile Piece Support

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** LOW  
**Depends On:** PRP-008 (Enemy Data Architecture), PRP-014 (Enemy HP & Knockback)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Some enemies can occupy multiple tiles (e.g., 1×2, 2×2):
1. **Multiple tile occupation:** Enemy "owns" all tiles of its hitbox
2. **Hitbox detection:** Can be hit on ANY occupied tile
3. **Movement for large pieces:** Whole piece shifts, respecting boundaries
4. **Knockback:** Whole piece shifts 1 tile in attack direction
5. **Visual representation:** Sprite spans multiple tiles

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       MULTI-TILE PIECE SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   === 1×2 ENEMY (Tall) ===        === 2×2 ENEMY (Large) ===                 │
│                                                                              │
│   anchor_col = 3                  anchor_col = 3                            │
│   anchor_row = 5                  anchor_row = 5                            │
│   hitbox_width = 1                hitbox_width = 2                          │
│   hitbox_height = 2               hitbox_height = 2                         │
│                                                                              │
│   Occupied tiles:                 Occupied tiles:                           │
│   ┌───┐                          ┌───┬───┐                                 │
│   │ A │  (3,5) anchor            │ A │   │  (3,5), (4,5)                   │
│   ├───┤                          ├───┼───┤                                 │
│   │   │  (3,6)                   │   │   │  (3,6), (4,6)                   │
│   └───┘                          └───┴───┘                                 │
│                                                                              │
│   Knockback (whole piece):                                                  │
│   ┌───┐      ┌───┐                                                         │
│   │ A │  →   │ A │   (all tiles shift +1 col)                              │
│   ├───┤      ├───┤                                                         │
│   │   │      │   │                                                         │
│   └───┘      └───┘                                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Enemy_Obj/Create_0.gml
  why: Enemy initialization pattern

- path: scripts/enemy_is_move_valid/enemy_is_move_valid.gml
  why: Move validation pattern to extend
```

### Files to Modify

```yaml
- path: objects/Enemy_Obj/Create_0.gml
  changes: Add hitbox tracking variables

- path: objects/Enemy_Obj/Step_0.gml
  changes: Update occupied tiles on move

- path: objects/Enemy_Obj/Draw_0.gml
  changes: Support large sprites

- path: scripts/enemy_is_tile_occupied/enemy_is_tile_occupied.gml
  changes: Check all tiles of multi-tile enemies

- path: scripts/enemy_is_move_valid/enemy_is_move_valid.gml
  changes: Validate all tiles of destination

- path: scripts/enemy_is_knockback_valid/enemy_is_knockback_valid.gml
  changes: Validate all tiles of knockback destination

- path: objects/Tile_Obj/Mouse_7.gml
  changes: Detect hits on any tile of multi-tile enemy
```

### Files to Create

```yaml
- path: scripts/enemy_get_occupied_tiles/enemy_get_occupied_tiles.gml
  purpose: Get all tiles occupied by an enemy

- path: scripts/enemy_occupies_tile/enemy_occupies_tile.gml
  purpose: Check if enemy occupies a specific tile

- path: scripts/enemy_can_fit_at/enemy_can_fit_at.gml
  purpose: Check if enemy's hitbox can fit at a position
```

---

## Implementation Blueprint

### Step 1: Add Hitbox Variables

**File:** `objects/Enemy_Obj/Create_0.gml` (additions)

```gml
// === MULTI-TILE HITBOX ===
// Anchor point is top-left of hitbox
// grid_col, grid_row already exist as anchor point
hitbox_width = 1;   // Set from enemy_def
hitbox_height = 1;  // Set from enemy_def

// Cache occupied tiles (updated on move)
occupied_tiles = [];  // Array of {col, row}
```

### Step 2: Get Occupied Tiles

**File:** `scripts/enemy_get_occupied_tiles/enemy_get_occupied_tiles.gml`

```gml
/// @function enemy_get_occupied_tiles(_enemy)
/// @param {Id.Instance} _enemy The enemy instance
/// @returns {array} Array of {col, row} for all occupied tiles
/// @description Gets all tiles occupied by an enemy's hitbox
function enemy_get_occupied_tiles(_enemy) {
    var _tiles = [];
    
    if (!instance_exists(_enemy)) return _tiles;
    
    var _anchor_col = _enemy.grid_col;
    var _anchor_row = _enemy.grid_row;
    var _width = _enemy.hitbox_width;
    var _height = _enemy.hitbox_height;
    
    for (var dy = 0; dy < _height; dy++) {
        for (var dx = 0; dx < _width; dx++) {
            array_push(_tiles, {
                col: _anchor_col + dx,
                row: _anchor_row + dy
            });
        }
    }
    
    return _tiles;
}
```

### Step 3: Check If Enemy Occupies Tile

**File:** `scripts/enemy_occupies_tile/enemy_occupies_tile.gml`

```gml
/// @function enemy_occupies_tile(_enemy, _col, _row)
/// @param {Id.Instance} _enemy The enemy instance
/// @param {real} _col Column to check
/// @param {real} _row Row to check
/// @returns {bool} True if enemy occupies this tile
/// @description Checks if a specific tile is within enemy's hitbox
function enemy_occupies_tile(_enemy, _col, _row) {
    if (!instance_exists(_enemy)) return false;
    
    var _anchor_col = _enemy.grid_col;
    var _anchor_row = _enemy.grid_row;
    var _width = _enemy.hitbox_width;
    var _height = _enemy.hitbox_height;
    
    return (_col >= _anchor_col && _col < _anchor_col + _width &&
            _row >= _anchor_row && _row < _anchor_row + _height);
}
```

### Step 4: Check If Enemy Can Fit

**File:** `scripts/enemy_can_fit_at/enemy_can_fit_at.gml`

```gml
/// @function enemy_can_fit_at(_enemy, _col, _row)
/// @param {Id.Instance} _enemy The enemy instance
/// @param {real} _col Anchor column
/// @param {real} _row Anchor row
/// @returns {bool} True if enemy's hitbox can fit at this position
/// @description Validates that all tiles of enemy's hitbox are valid at position
function enemy_can_fit_at(_enemy, _col, _row) {
    if (!instance_exists(_enemy)) return false;
    
    var _width = _enemy.hitbox_width;
    var _height = _enemy.hitbox_height;
    
    // Check each tile in the hitbox
    for (var dy = 0; dy < _height; dy++) {
        for (var dx = 0; dx < _width; dx++) {
            var _check_col = _col + dx;
            var _check_row = _row + dy;
            
            // Bounds check
            if (_check_col < 0 || _check_col >= 8 || 
                _check_row < 0 || _check_row >= 8) {
                return false;
            }
            
            // Calculate pixel position
            var _x = Object_Manager.topleft_x + _check_col * Board_Manager.tile_size;
            var _y = Object_Manager.topleft_y + _check_row * Board_Manager.tile_size;
            
            // Check for other enemies (not self)
            with (Enemy_Obj) {
                if (id != _enemy && !is_dead) {
                    if (enemy_occupies_tile(id, _check_col, _check_row)) {
                        return false;
                    }
                }
            }
            
            // Check for chess pieces
            var _piece = instance_position(_x, _y, Chess_Piece_Obj);
            if (_piece != noone) {
                return false;
            }
            
            // Check for hazards
            var _tile = instance_position(_x, _y, Tile_Obj);
            if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
                if (_tile.tile_type == -1) return false;  // Void
                if (_tile.tile_type == 1) {
                    var _bridge = instance_position(_x, _y, Bridge_Obj);
                    if (_bridge == noone) return false;  // Water without bridge
                }
            }
        }
    }
    
    return true;
}
```

### Step 5: Update Movement Validation

**File:** `scripts/enemy_is_move_valid/enemy_is_move_valid.gml` (update)

Replace single-tile logic with multi-tile:

```gml
/// @function enemy_is_move_valid(_enemy, _col, _row)
/// Updated to support multi-tile enemies
function enemy_is_move_valid(_enemy, _col, _row) {
    if (!instance_exists(_enemy)) return false;
    
    // For multi-tile enemies, _col/_row is the anchor point
    return enemy_can_fit_at(_enemy, _col, _row);
}
```

### Step 6: Update Knockback Validation

**File:** `scripts/enemy_is_knockback_valid/enemy_is_knockback_valid.gml` (update)

```gml
/// @function enemy_is_knockback_valid(_enemy, _col, _row)
/// Updated to support multi-tile enemies
function enemy_is_knockback_valid(_enemy, _col, _row) {
    if (!instance_exists(_enemy)) return false;
    
    // For multi-tile enemies, _col/_row is the anchor point
    return enemy_can_fit_at(_enemy, _col, _row);
}
```

### Step 7: Update Tile Occupation Check

**File:** `scripts/enemy_is_tile_occupied/enemy_is_tile_occupied.gml` (update)

```gml
/// @function enemy_is_tile_occupied(_col, _row)
/// Updated to check all tiles of multi-tile enemies
function enemy_is_tile_occupied(_col, _row) {
    // ... existing bounds and piece checks ...
    
    // Check for enemies (including multi-tile)
    with (Enemy_Obj) {
        if (!is_dead && enemy_occupies_tile(id, _col, _row)) {
            return true;
        }
    }
    
    // ... rest of existing code ...
}
```

### Step 8: Update Hit Detection

**File:** `objects/Tile_Obj/Mouse_7.gml` (update enemy detection)

```gml
// Check for enemy collision (including multi-tile)
var enemy_unit = noone;
with (Enemy_Obj) {
    if (!is_dead) {
        // Get tile coordinates of click
        var _click_col = round((other.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var _click_row = round((other.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        
        if (enemy_occupies_tile(id, _click_col, _click_row)) {
            enemy_unit = id;
            break;
        }
    }
}

if (enemy_unit != noone) {
    // ... existing damage code ...
}
```

### Step 9: Update Enemy Creation

**File:** `scripts/enemy_create/enemy_create.gml` (update)

Add after setting enemy_def:

```gml
// Set hitbox dimensions from definition
if (variable_struct_exists(_def, "hitbox_width")) {
    _enemy.hitbox_width = _def.hitbox_width;
}
if (variable_struct_exists(_def, "hitbox_height")) {
    _enemy.hitbox_height = _def.hitbox_height;
}

// Initialize occupied tiles cache
_enemy.occupied_tiles = enemy_get_occupied_tiles(_enemy);
```

### Step 10: Update Occupied Tiles on Move

**File:** `objects/Enemy_Obj/Step_0.gml` (add after movement completion)

```gml
// Update occupied tiles after movement
if (!is_moving && array_length(occupied_tiles) > 0) {
    var _old_tiles = occupied_tiles;
    occupied_tiles = enemy_get_occupied_tiles(id);
    
    // Only log if actually changed
    if (array_length(_old_tiles) != array_length(occupied_tiles) ||
        _old_tiles[0].col != occupied_tiles[0].col ||
        _old_tiles[0].row != occupied_tiles[0].row) {
        show_debug_message("Enemy: Updated occupied tiles to " + 
            string(array_length(occupied_tiles)) + " tiles");
    }
}
```

### Step 11: Draw Large Sprites

**File:** `objects/Enemy_Obj/Draw_0.gml` (update sprite drawing)

```gml
// === NORMAL DRAW (Multi-tile support) ===
var _scale_x = hitbox_width;
var _scale_y = hitbox_height;

// Center sprite on hitbox (not anchor)
var _offset_x = (hitbox_width - 1) * Board_Manager.tile_size / 2;
var _offset_y = (hitbox_height - 1) * Board_Manager.tile_size / 2;

draw_sprite_ext(
    sprite_index, image_index,
    x + _offset_x, y + _offset_y,
    _scale_x, _scale_y, 0,
    c_white, 1
);
```

---

## Large Enemy Example Definition

```gml
// === 2×2 BOSS MINION ===
var _large_enemy = {
    enemy_id: "large_placeholder",
    display_name: "Large Placeholder",
    
    max_hp: 4,
    hitbox_width: 2,   // Occupies 2×2 = 4 tiles
    hitbox_height: 2,
    
    movement_type: "king",
    movement_speed: 45,  // Slower for large enemy
    
    attack_type: "melee",
    attack_site_width: 4,  // Larger vision
    attack_site_height: 4,
    attack_size_width: 2,  // Attacks 2×2 area
    attack_size_height: 2,
    
    spawn_rules: {
        default_ranks: [5, 6],  // Needs room for 2-tile height
        lane_lock: -1,
        exact_tile: noone,
        avoid_occupied: true
    },
    
    sprite_idle: spr_enemy_large,  // 48×48 sprite for 2×2
    // ...
};
```

---

## Knockback for Multi-Tile Pieces

Per design spec: "Knockback for multi-tile pieces: Same as 1×1 — the whole piece shifts 1 tile in the direction it was hit."

The knockback system already calculates direction and destination. For multi-tile:
- The anchor point shifts by (dir_x, dir_y)
- All other tiles shift the same amount
- `enemy_can_fit_at()` validates the entire new footprint

---

## Known Gotchas

### Sprite Size
Large sprites should be hitbox_width × hitbox_height × tile_size (e.g., 48×48 for 2×2).

### Anchor Point
The anchor is always top-left. Position calculations use this point.

### Partial Overlap
A multi-tile enemy cannot partially overlap another multi-tile enemy. All tiles must be free.

### Board Edges
2×2 enemy at column 7 would extend off-board. Spawning and movement must respect this.

---

## Success Criteria

- [ ] 2×2 enemy occupies 4 tiles
- [ ] Enemy can be hit from any occupied tile
- [ ] Enemy cannot move to positions where hitbox extends off-board
- [ ] Enemy knockback moves entire hitbox
- [ ] Other enemies cannot overlap multi-tile enemy
- [ ] Large sprite displays correctly
- [ ] HP bar positioned correctly for large sprites
- [ ] Code compiles without errors

---

## Validation

### Multi-Tile Spawn Test

1. Add 2×2 enemy definition
2. Configure level to spawn it
3. Verify enemy appears occupying 4 tiles
4. Verify sprite size is correct

### Hit Detection Test

1. Attack 2×2 enemy from different tiles
2. Verify hit registers from any of the 4 tiles
3. Verify knockback direction matches attack angle

### Boundary Test

1. Position 2×2 enemy near board edge
2. Try to knock back toward edge
3. Verify enemy stays put (can't fit)

---

## Next Steps

After this PRP is implemented:
1. **PRP-016** — Integration test with all enemy features
