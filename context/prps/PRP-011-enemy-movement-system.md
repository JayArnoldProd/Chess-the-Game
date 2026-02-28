# PRP-011: Enemy Movement System

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-010 (Enemy Turn System)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

When enemies don't have a target in their attack site, they need to move toward player pieces:
1. **Movement AI:** Move toward closest player piece
2. **Movement types:** King-style for placeholder (extensible for future types)
3. **Collision rules:** Can't move onto other enemies (pushed back)
4. **Path validation:** Respect board boundaries, avoid hazards
5. **Animation:** Smooth tile-to-tile motion (reuse existing easeInOutQuad)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ENEMY MOVEMENT FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   enemy_state = "moving"                                                    │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────┐                                           │
│   │ enemy_find_move_target()   │  ◀── Find closest player piece            │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│                 ▼                                                           │
│   ┌────────────────────────────┐                                           │
│   │ enemy_get_valid_moves()    │  ◀── Based on movement_type               │
│   └─────────────┬──────────────┘      (king, knight, rook, etc.)           │
│                 │                                                           │
│                 ▼                                                           │
│   ┌────────────────────────────┐                                           │
│   │ enemy_pick_best_move()     │  ◀── Move that gets closest to target     │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│        ┌────────┴────────┐                                                 │
│        │                 │                                                 │
│        ▼                 ▼                                                 │
│   ┌─────────┐      ┌───────────────┐                                       │
│   │ Valid   │      │ No valid move │                                       │
│   │ move    │      │ (blocked)     │                                       │
│   └────┬────┘      └───────┬───────┘                                       │
│        │                   │                                               │
│        ▼                   ▼                                               │
│   ┌──────────────┐   ┌─────────────────┐                                   │
│   │ Start anim   │   │ Skip movement   │                                   │
│   │ is_moving=1  │   │ → turn_complete │                                   │
│   └──────┬───────┘   └─────────────────┘                                   │
│          │                                                                  │
│          ▼                                                                  │
│   ┌──────────────────┐                                                     │
│   │ Animation done   │                                                     │
│   │ → turn_complete  │                                                     │
│   └──────────────────┘                                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: scripts/ai_get_piece_moves_virtual/ai_get_piece_moves_virtual.gml
  why: Pattern for generating moves by piece type

- path: objects/Chess_Piece_Obj/Step_0.gml
  why: Movement animation pattern with easeInOutQuad
```

### Files to Modify

```yaml
- path: objects/Enemy_Obj/Step_0.gml
  changes: Implement "moving" state with movement logic
```

### Files to Create

```yaml
- path: scripts/enemy_find_move_target/enemy_find_move_target.gml
  purpose: Find closest player piece to move toward

- path: scripts/enemy_get_valid_moves/enemy_get_valid_moves.gml
  purpose: Get valid movement tiles based on movement type

- path: scripts/enemy_pick_best_move/enemy_pick_best_move.gml
  purpose: Choose move that minimizes distance to target

- path: scripts/enemy_is_move_valid/enemy_is_move_valid.gml
  purpose: Check if a specific move is valid (bounds, collision, hazards)
```

---

## Implementation Blueprint

### Step 1: Find Move Target

**File:** `scripts/enemy_find_move_target/enemy_find_move_target.gml`

```gml
/// @function enemy_find_move_target(_enemy)
/// @param {Id.Instance} _enemy The enemy instance
/// @returns {Id.Instance} Closest player piece, or noone if none exist
/// @description Finds the closest player piece to move toward
function enemy_find_move_target(_enemy) {
    if (!instance_exists(_enemy)) return noone;
    
    var _closest = noone;
    var _closest_dist = 9999;
    var _enemy_col = _enemy.grid_col;
    var _enemy_row = _enemy.grid_row;
    
    // Check all player pieces (piece_type == 0 is white/player)
    with (Chess_Piece_Obj) {
        if (piece_type == 0 && !is_moving) {
            // Calculate grid distance (Chebyshev distance for king-style movement)
            var _piece_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var _piece_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            
            var _dist = max(abs(_piece_col - _enemy_col), abs(_piece_row - _enemy_row));
            
            if (_dist < _closest_dist) {
                _closest_dist = _dist;
                _closest = id;
            }
        }
    }
    
    return _closest;
}
```

### Step 2: Get Valid Moves Based on Movement Type

**File:** `scripts/enemy_get_valid_moves/enemy_get_valid_moves.gml`

```gml
/// @function enemy_get_valid_moves(_enemy)
/// @param {Id.Instance} _enemy The enemy instance
/// @returns {array} Array of {col, row} valid move destinations
/// @description Gets all valid move tiles based on enemy's movement type
function enemy_get_valid_moves(_enemy) {
    if (!instance_exists(_enemy)) return [];
    if (_enemy.enemy_def == undefined) return [];
    
    var _moves = [];
    var _type = _enemy.enemy_def.movement_type;
    var _col = _enemy.grid_col;
    var _row = _enemy.grid_row;
    
    // Generate candidate moves based on movement type
    var _candidates = [];
    
    switch (_type) {
        case "king":
            // King-style: 1 tile in any of 8 directions
            for (var dy = -1; dy <= 1; dy++) {
                for (var dx = -1; dx <= 1; dx++) {
                    if (dx != 0 || dy != 0) {
                        array_push(_candidates, { col: _col + dx, row: _row + dy });
                    }
                }
            }
            break;
            
        case "knight":
            // Knight-style: L-shaped jumps
            var _knight_moves = [
                {dx: 1, dy: -2}, {dx: 2, dy: -1},
                {dx: 2, dy: 1},  {dx: 1, dy: 2},
                {dx: -1, dy: 2}, {dx: -2, dy: 1},
                {dx: -2, dy: -1}, {dx: -1, dy: -2}
            ];
            for (var i = 0; i < array_length(_knight_moves); i++) {
                var _m = _knight_moves[i];
                array_push(_candidates, { col: _col + _m.dx, row: _row + _m.dy });
            }
            break;
            
        case "rook":
            // Rook-style: straight lines (orthogonal)
            _candidates = enemy_get_sliding_moves(_enemy, [[0,-1], [0,1], [-1,0], [1,0]]);
            break;
            
        case "bishop":
            // Bishop-style: diagonal lines
            _candidates = enemy_get_sliding_moves(_enemy, [[-1,-1], [-1,1], [1,-1], [1,1]]);
            break;
            
        default:
            // Default to king-style
            for (var dy = -1; dy <= 1; dy++) {
                for (var dx = -1; dx <= 1; dx++) {
                    if (dx != 0 || dy != 0) {
                        array_push(_candidates, { col: _col + dx, row: _row + dy });
                    }
                }
            }
            break;
    }
    
    // Filter candidates through validation
    for (var i = 0; i < array_length(_candidates); i++) {
        var _c = _candidates[i];
        if (enemy_is_move_valid(_enemy, _c.col, _c.row)) {
            array_push(_moves, _c);
        }
    }
    
    return _moves;
}

/// @function enemy_get_sliding_moves(_enemy, _directions)
/// @param {Id.Instance} _enemy
/// @param {array} _directions Array of [dx, dy] direction vectors
/// @returns {array} Array of {col, row} for sliding moves
function enemy_get_sliding_moves(_enemy, _directions) {
    var _moves = [];
    var _col = _enemy.grid_col;
    var _row = _enemy.grid_row;
    
    for (var d = 0; d < array_length(_directions); d++) {
        var _dir = _directions[d];
        var _dx = _dir[0];
        var _dy = _dir[1];
        
        for (var dist = 1; dist <= 7; dist++) {
            var _new_col = _col + _dx * dist;
            var _new_row = _row + _dy * dist;
            
            // Bounds check
            if (_new_col < 0 || _new_col >= 8 || _new_row < 0 || _new_row >= 8) break;
            
            // Check for blocking piece
            var _px = Object_Manager.topleft_x + _new_col * Board_Manager.tile_size;
            var _py = Object_Manager.topleft_y + _new_row * Board_Manager.tile_size;
            
            var _piece = instance_position(_px, _py, Chess_Piece_Obj);
            var _other_enemy = instance_position(_px, _py, Enemy_Obj);
            
            if (_piece != noone || _other_enemy != noone) {
                // Blocked - can move here (capture) but not beyond
                array_push(_moves, { col: _new_col, row: _new_row });
                break;
            }
            
            // Empty tile - add and continue
            array_push(_moves, { col: _new_col, row: _new_row });
        }
    }
    
    return _moves;
}
```

### Step 3: Move Validation

**File:** `scripts/enemy_is_move_valid/enemy_is_move_valid.gml`

```gml
/// @function enemy_is_move_valid(_enemy, _col, _row)
/// @param {Id.Instance} _enemy The enemy trying to move
/// @param {real} _col Target column
/// @param {real} _row Target row
/// @returns {bool} True if the move is valid
/// @description Checks if an enemy can move to the specified tile
function enemy_is_move_valid(_enemy, _col, _row) {
    // === BOUNDS CHECK ===
    if (_col < 0 || _col >= 8 || _row < 0 || _row >= 8) {
        return false;
    }
    
    // Calculate pixel position
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // === OTHER ENEMY CHECK ===
    // Enemies cannot move onto each other
    var _other = instance_position(_x, _y, Enemy_Obj);
    if (_other != noone && _other != _enemy) {
        return false;
    }
    
    // === STEPPING STONE CHECK ===
    // Stepping stones are walls to enemies — enemies cannot occupy them (2026-02-27 ruling)
    var _stone = instance_position(_x, _y, Stepping_Stone_Obj);
    if (_stone != noone) {
        return false;
    }
    
    // === HAZARD CHECK ===
    var _tile = instance_position(_x, _y, Tile_Obj);
    if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
        // Void tile
        if (_tile.tile_type == -1) {
            return false;
        }
        // Water tile without bridge
        if (_tile.tile_type == 1) {
            var _bridge = instance_position(_x, _y, Bridge_Obj);
            if (_bridge == noone) {
                return false;
            }
        }
    }
    
    // === PLAYER PIECE CHECK ===
    // Enemies CAN move onto player pieces (that's an attack, handled separately)
    // But for movement phase (no target), we don't want to step on them
    var _piece = instance_position(_x, _y, Chess_Piece_Obj);
    if (_piece != noone && _piece.piece_type == 0) {
        // Player piece - valid for attack but not pure movement
        // Return true here because picking best move will handle this
        return true;
    }
    if (_piece != noone && _piece.piece_type == 1) {
        // AI piece (black) - enemies shouldn't step on allies
        return false;
    }
    
    return true;
}
```

### Step 4: Pick Best Move

**File:** `scripts/enemy_pick_best_move/enemy_pick_best_move.gml`

```gml
/// @function enemy_pick_best_move(_enemy, _valid_moves, _target)
/// @param {Id.Instance} _enemy The enemy
/// @param {array} _valid_moves Array of {col, row}
/// @param {Id.Instance} _target Target player piece (or noone)
/// @returns {struct} Best move {col, row}, or undefined if no valid moves
/// @description Picks the move that minimizes distance to target
function enemy_pick_best_move(_enemy, _valid_moves, _target) {
    if (array_length(_valid_moves) == 0) {
        return undefined;
    }
    
    // If no target, pick randomly
    if (_target == noone || !instance_exists(_target)) {
        var _idx = irandom(array_length(_valid_moves) - 1);
        return _valid_moves[_idx];
    }
    
    // Get target position
    var _target_col = round((_target.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _target_row = round((_target.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Find move that minimizes Chebyshev distance to target
    var _best_move = _valid_moves[0];
    var _best_dist = max(abs(_best_move.col - _target_col), abs(_best_move.row - _target_row));
    
    for (var i = 1; i < array_length(_valid_moves); i++) {
        var _m = _valid_moves[i];
        var _dist = max(abs(_m.col - _target_col), abs(_m.row - _target_row));
        
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best_move = _m;
        }
    }
    
    // Don't move onto player piece during movement phase (that triggers attack)
    var _px = Object_Manager.topleft_x + _best_move.col * Board_Manager.tile_size;
    var _py = Object_Manager.topleft_y + _best_move.row * Board_Manager.tile_size;
    var _piece = instance_position(_px, _py, Chess_Piece_Obj);
    if (_piece != noone && _piece.piece_type == 0) {
        // Would step on player piece - filter this out and try again
        var _filtered = [];
        for (var i = 0; i < array_length(_valid_moves); i++) {
            var _m = _valid_moves[i];
            var _mx = Object_Manager.topleft_x + _m.col * Board_Manager.tile_size;
            var _my = Object_Manager.topleft_y + _m.row * Board_Manager.tile_size;
            if (instance_position(_mx, _my, Chess_Piece_Obj) == noone) {
                array_push(_filtered, _m);
            }
        }
        if (array_length(_filtered) > 0) {
            return enemy_pick_best_move(_enemy, _filtered, _target);
        }
        // All moves step on pieces - return original (will be handled as attack)
    }
    
    return _best_move;
}
```

### Step 5: Update Enemy State Machine

**File:** `objects/Enemy_Obj/Step_0.gml` (update "moving" case)

Replace the stub "moving" case with:

```gml
case "moving":
    // MOVE TOWARD PLAYER
    // Only process if not already animating
    if (is_moving) {
        // Wait for animation to complete
        break;
    }
    
    // Check if we already started a move this turn
    if (!variable_instance_exists(id, "move_started") || !move_started) {
        move_started = true;
        
        // Find closest player piece to move toward
        var _target = enemy_find_move_target(id);
        
        // Get valid moves for this enemy type
        var _valid_moves = enemy_get_valid_moves(id);
        
        if (array_length(_valid_moves) == 0) {
            // No valid moves - skip movement
            show_debug_message("Enemy: No valid moves, skipping movement");
            move_started = false;
            enemy_state = "turn_complete";
            break;
        }
        
        // Pick best move toward target
        var _best = enemy_pick_best_move(id, _valid_moves, _target);
        
        if (_best == undefined) {
            show_debug_message("Enemy: Could not pick move");
            move_started = false;
            enemy_state = "turn_complete";
            break;
        }
        
        // Calculate target position
        var _dest_x = Object_Manager.topleft_x + _best.col * Board_Manager.tile_size;
        var _dest_y = Object_Manager.topleft_y + _best.row * Board_Manager.tile_size;
        
        // Start movement animation
        move_start_x = x;
        move_start_y = y;
        move_target_x = _dest_x;
        move_target_y = _dest_y;
        move_progress = 0;
        move_duration = enemy_def.movement_speed;
        is_moving = true;
        
        show_debug_message("Enemy: Moving from (" + string(grid_col) + "," + string(grid_row) + 
            ") to (" + string(_best.col) + "," + string(_best.row) + ")");
    } else {
        // Animation completed (is_moving just became false)
        move_started = false;
        enemy_state = "turn_complete";
    }
    break;
```

Also add initialization in Create_0.gml:

```gml
move_started = false;
```

---

## Collision Edge Cases

### Enemy Tries to Move onto Another Enemy

Per design spec: "If an enemy tries to move onto another enemy's tile, it gets **pushed back to its original square**"

This is already handled by `enemy_is_move_valid()` returning false for tiles with other enemies.

### Enemy Tries to Move onto a Stepping Stone
*(Added 2026-02-27, per Jas ruling)*

Stepping stones are **walls** to enemies. `enemy_is_move_valid()` returns false for tiles with `Stepping_Stone_Obj`. Enemies cannot occupy or use stepping stone mechanics.

### Enemy Pushed Back by Multiple Blockages

If ALL valid moves are blocked:
1. Enemy stays in place
2. Turn completes (no movement)
3. No crash or infinite loop

---

## Known Gotchas

### Grid vs Pixel Coordinates
- `grid_col`, `grid_row` are 0-7 board coordinates
- `x`, `y` are pixel positions
- Always use `Object_Manager.topleft_x/y` and `Board_Manager.tile_size` for conversion

### Animation State
- Set `is_moving = true` to start animation
- Animation progresses in Step event (inherited from base Enemy_Obj)
- Check `is_moving == false` to detect completion

### Move Selection Order
Valid moves array order affects tie-breaking. Currently first move with minimum distance wins.

---

## Success Criteria

- [ ] Enemy moves toward closest player piece when no target in attack site
- [ ] Movement uses correct type (king-style for placeholder)
- [ ] Enemy cannot move onto other enemies
- [ ] Enemy cannot move onto void tiles
- [ ] Enemy cannot move onto water without bridges
- [ ] Animation plays smoothly (easeInOutQuad)
- [ ] Turn completes after movement animation
- [ ] Enemy with no valid moves skips turn gracefully
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Start Ruined_Overworld
2. Move all player pieces away from enemies
3. Watch enemy move toward closest piece
4. Verify enemy takes shortest path

### Blocked Movement Test

1. Surround enemy with other enemies
2. Verify enemy skips movement (no crash)
3. Turn still completes normally

### Hazard Avoidance Test (Pirate_Seas)

1. Position enemy near water
2. Verify enemy doesn't walk into water
3. Verify enemy uses bridges if available

### Stepping Stone Blocking Test
*(Added 2026-02-27)*

1. Position enemy adjacent to a stepping stone tile
2. Make the stepping stone the only path toward the closest player piece
3. Verify enemy does NOT move onto the stepping stone (treated as wall)
4. Verify enemy picks an alternate path or skips movement

---

## Next Steps

After this PRP is implemented:
1. **PRP-012** — Implement melee attack (when target IS in range)
2. **PRP-014** — Enemy HP and knockback (can be parallel)
