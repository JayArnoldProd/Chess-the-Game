# PRP-010: Enemy Turn System

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-008 (Enemy Data Architecture), PRP-009 (Enemy Spawning System)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Enemies need to integrate into the existing turn system:
1. **Turn order:** Player → Enemies → AI (black pieces) → repeat
2. **Sequential processing:** Each enemy acts independently, one at a time
3. **State machine:** Each enemy cycles through IDLE → SCANNING → HIGHLIGHTING → ATTACKING/MOVING
4. **Animation waiting:** Next enemy doesn't act until previous enemy's animation completes

This PRP establishes the turn framework. Actual movement and attack behaviors are in PRP-011 and PRP-012.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TURN CYCLE (WITH ENEMIES)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                        GAME_MANAGER.turn                           │     │
│   │                                                                    │     │
│   │    turn=0           turn=2              turn=1                    │     │
│   │   ┌───────┐       ┌───────────┐       ┌───────┐                  │     │
│   │   │PLAYER │──────▶│  ENEMIES  │──────▶│  AI   │────────┐         │     │
│   │   │ TURN  │       │   TURN    │       │ TURN  │        │         │     │
│   │   └───────┘       └───────────┘       └───────┘        │         │     │
│   │       ▲                                                │         │     │
│   │       └────────────────────────────────────────────────┘         │     │
│   │                                                                    │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                    ENEMY_MANAGER STATE MACHINE                     │     │
│   │                                                                    │     │
│   │   turn=2 starts                                                   │     │
│   │        │                                                          │     │
│   │        ▼                                                          │     │
│   │   ┌─────────┐   queue built   ┌────────────┐                     │     │
│   │   │  IDLE   │ ───────────────▶│ PROCESSING │ ◀──┐                │     │
│   │   └─────────┘                 └──────┬─────┘    │                │     │
│   │                                      │          │ next enemy     │     │
│   │                                      ▼          │                │     │
│   │                             ┌────────────────┐  │                │     │
│   │                             │ Process single │──┘                │     │
│   │                             │ enemy's turn   │                   │     │
│   │                             └────────┬───────┘                   │     │
│   │                                      │                           │     │
│   │                                      │ queue empty               │     │
│   │                                      ▼                           │     │
│   │                             ┌────────────────┐                   │     │
│   │                             │ Set turn = 1   │                   │     │
│   │                             │ (AI's turn)    │                   │     │
│   │                             └────────────────┘                   │     │
│   │                                                                    │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                     ENEMY STATE MACHINE (per enemy)                │     │
│   │                                                                    │     │
│   │   ┌──────┐   scan for    ┌──────────┐   target    ┌────────────┐ │     │
│   │   │ IDLE │ ─────────────▶│ SCANNING │ ──────────▶│HIGHLIGHTING│ │     │
│   │   └──────┘   targets     └──────────┘   found     └─────┬──────┘ │     │
│   │       ▲                        │                        │        │     │
│   │       │                        │ no target              │ 1 turn │     │
│   │       │                        ▼                        ▼        │     │
│   │       │                  ┌──────────┐            ┌───────────┐   │     │
│   │       │                  │  MOVING  │            │ ATTACKING │   │     │
│   │       │                  └────┬─────┘            └─────┬─────┘   │     │
│   │       │                       │                        │         │     │
│   │       └───────────────────────┴────────────────────────┘         │     │
│   │                            turn complete                          │     │
│   │                                                                    │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Game_Manager/Step_0.gml
  why: Current turn handling patterns

- path: objects/AI_Manager/Step_0.gml
  why: State machine pattern for multi-frame processing

- path: objects/Chess_Piece_Obj/Step_0.gml
  why: Animation completion detection, pending_turn_switch pattern
```

### Files to Modify

```yaml
- path: objects/Game_Manager/Create_0.gml
  changes: Document turn value 2 for enemies

- path: objects/Chess_Piece_Obj/Step_0.gml
  changes: Update pending_turn_switch to handle turn=2

- path: objects/Tile_Obj/Mouse_7.gml
  changes: After player move, switch to turn=2 if enemies exist

- path: objects/Enemy_Manager/Step_0.gml
  changes: Full turn processing state machine

- path: objects/Enemy_Obj/Step_0.gml
  changes: Per-enemy state machine execution
```

### Files to Create

```yaml
- path: scripts/enemy_process_turn/enemy_process_turn.gml
  purpose: Process a single enemy's turn phase

- path: scripts/enemy_begin_turn_phase/enemy_begin_turn_phase.gml
  purpose: Start enemy turn processing

- path: scripts/enemy_end_turn_phase/enemy_end_turn_phase.gml
  purpose: Clean up and switch to AI turn
```

---

## Implementation Blueprint

### Step 1: Update Turn System Constants

**File:** `objects/Game_Manager/Create_0.gml` (documentation update)

```gml
// Initialize the turn variable:
// 0 = player's turn (white)
// 1 = AI's turn (black chess pieces)
// 2 = enemies' turn (hostile units, not chess pieces)
// 3 = boss cheat phase (for boss levels, after AI move)
turn = 0;
```

### Step 2: Enemy Turn Trigger (After Player Move)

**File:** `objects/Tile_Obj/Mouse_7.gml` (modification)

Find the lines that set `pending_turn_switch = 1` and update them:

```gml
// BEFORE (multiple locations):
piece.pending_turn_switch = (piece.piece_type == 0) ? 1 : 0;

// AFTER:
// If player moved (white, piece_type=0), check if enemies exist
if (piece.piece_type == 0) {
    // Check for active enemies
    if (instance_exists(Enemy_Manager) && array_length(Enemy_Manager.enemy_list) > 0) {
        piece.pending_turn_switch = 2;  // Enemy turn next
    } else {
        piece.pending_turn_switch = 1;  // AI turn next (no enemies)
    }
} else {
    piece.pending_turn_switch = 0;  // Player turn next
}
```

Apply this change to all locations in the file where `pending_turn_switch` is set.

### Step 3: Enemy Manager Turn Processing

**File:** `objects/Enemy_Manager/Step_0.gml` (full implementation)

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

// === TURN PROCESSING STATE MACHINE ===
if (!instance_exists(Game_Manager)) exit;

switch (enemy_turn_state) {
    
    // ===== IDLE STATE =====
    case "idle":
        // Only activate when it's enemies' turn
        if (Game_Manager.turn != 2) exit;
        
        // Don't start while pieces are animating
        var _any_moving = false;
        with (Chess_Piece_Obj) {
            if (is_moving) {
                _any_moving = true;
                break;
            }
        }
        if (_any_moving) exit;
        
        // Build queue of enemies to process
        enemies_to_process = [];
        for (var i = 0; i < array_length(enemy_list); i++) {
            if (instance_exists(enemy_list[i]) && !enemy_list[i].is_dead) {
                array_push(enemies_to_process, enemy_list[i]);
            }
        }
        
        // No enemies? Skip to AI turn
        if (array_length(enemies_to_process) == 0) {
            show_debug_message("Enemy_Manager: No enemies to process, skipping to AI turn");
            Game_Manager.turn = 1;  // AI turn
            exit;
        }
        
        show_debug_message("Enemy_Manager: Starting enemy turn (" + 
            string(array_length(enemies_to_process)) + " enemies)");
        
        current_enemy_index = 0;
        enemy_turn_state = "processing";
        break;
    
    // ===== PROCESSING STATE =====
    case "processing":
        // Safety check: turn changed externally?
        if (Game_Manager.turn != 2) {
            enemy_turn_state = "idle";
            exit;
        }
        
        // All enemies processed?
        if (current_enemy_index >= array_length(enemies_to_process)) {
            show_debug_message("Enemy_Manager: All enemies processed, switching to AI turn");
            Game_Manager.turn = 1;  // AI turn
            enemy_turn_state = "idle";
            exit;
        }
        
        // Get current enemy
        var _enemy = enemies_to_process[current_enemy_index];
        
        // Verify enemy still exists
        if (!instance_exists(_enemy) || _enemy.is_dead) {
            show_debug_message("Enemy_Manager: Skipping destroyed enemy");
            current_enemy_index++;
            exit;
        }
        
        // Wait for enemy animation to complete
        if (_enemy.is_moving) {
            exit;  // Keep waiting
        }
        
        // Check enemy state
        switch (_enemy.enemy_state) {
            case "idle":
                // Start this enemy's turn
                _enemy.enemy_state = "scanning";
                show_debug_message("Enemy " + string(current_enemy_index) + 
                    ": Starting turn (scanning)");
                break;
                
            case "scanning":
                // Scan for targets (implemented in Enemy_Obj/Step_0)
                // Enemy_Obj will transition to "highlighting" or "moving"
                break;
                
            case "highlighting":
                // Attack warning active (implemented in Enemy_Obj/Step_0)
                // Will transition to "attacking" after delay
                break;
                
            case "attacking":
                // Execute attack (implemented in PRP-012)
                // Will transition to "turn_complete"
                break;
                
            case "moving":
                // Movement toward player (implemented in PRP-011)
                // Will transition to "turn_complete"
                break;
                
            case "turn_complete":
                // This enemy is done - move to next
                _enemy.enemy_state = "idle";
                current_enemy_index++;
                show_debug_message("Enemy " + string(current_enemy_index - 1) + 
                    ": Turn complete");
                break;
                
            default:
                // Unknown state - skip this enemy
                show_debug_message("WARNING: Unknown enemy state: " + _enemy.enemy_state);
                _enemy.enemy_state = "idle";
                current_enemy_index++;
                break;
        }
        break;
    
    default:
        enemy_turn_state = "idle";
        break;
}
```

### Step 4: Enemy State Machine (Per-Enemy)

**File:** `objects/Enemy_Obj/Step_0.gml` (updated)

```gml
/// Enemy_Obj Step Event
/// Per-enemy state machine and animation

// Update audio emitter position
audio_emitter_position(audio_emitter, x, y, 0);

// === MOVEMENT INTERPOLATION ===
if (is_moving) {
    move_progress += 1 / move_duration;
    if (move_progress >= 1) {
        move_progress = 1;
        is_moving = false;
        x = move_target_x;
        y = move_target_y;
        
        // Update grid position
        grid_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        grid_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    } else {
        var t = easeInOutQuad(move_progress);
        x = lerp(move_start_x, move_target_x, t);
        y = lerp(move_start_y, move_target_y, t);
    }
}

// === DEATH ANIMATION ===
if (is_dead && !is_moving) {
    death_timer++;
    if (death_timer >= death_duration) {
        // Remove from Enemy_Manager's list
        if (instance_exists(Enemy_Manager)) {
            var _idx = array_get_index(Enemy_Manager.enemy_list, id);
            if (_idx >= 0) {
                array_delete(Enemy_Manager.enemy_list, _idx, 1);
            }
        }
        instance_destroy();
    }
    exit;  // Don't process state machine while dying
}

// === ENEMY STATE MACHINE ===
// Only process if it's enemy turn and this enemy is being processed
if (Game_Manager.turn != 2) exit;
if (!instance_exists(Enemy_Manager)) exit;
if (is_moving) exit;  // Wait for animation

// Check if this enemy is the one currently being processed
var _current_idx = Enemy_Manager.current_enemy_index;
if (_current_idx >= array_length(Enemy_Manager.enemies_to_process)) exit;
if (Enemy_Manager.enemies_to_process[_current_idx] != id) exit;

// Process state
switch (enemy_state) {
    
    case "scanning":
        // SCAN FOR TARGETS
        // Look for player pieces within attack site (detection zone)
        var _def = enemy_def;
        if (_def == undefined) {
            enemy_state = "turn_complete";
            exit;
        }
        
        var _site_w = _def.attack_site_width;
        var _site_h = _def.attack_site_height;
        var _half_w = floor(_site_w / 2);
        var _half_h = floor(_site_h / 2);
        
        target_piece = noone;
        var _closest_dist = 9999;
        
        // Check each tile in attack site
        for (var dy = -_half_h; dy <= _half_h; dy++) {
            for (var dx = -_half_w; dx <= _half_w; dx++) {
                var _check_col = grid_col + dx;
                var _check_row = grid_row + dy;
                
                // Bounds check
                if (_check_col < 0 || _check_col >= 8 || _check_row < 0 || _check_row >= 8) continue;
                
                // Calculate pixel position
                var _check_x = Object_Manager.topleft_x + _check_col * Board_Manager.tile_size;
                var _check_y = Object_Manager.topleft_y + _check_row * Board_Manager.tile_size;
                
                // Check for player piece (piece_type == 0 is white/player)
                var _piece = instance_position(_check_x, _check_y, Chess_Piece_Obj);
                if (_piece != noone && _piece.piece_type == 0) {
                    // Found a player piece - check if closest
                    var _dist = point_distance(grid_col, grid_row, _check_col, _check_row);
                    if (_dist < _closest_dist) {
                        _closest_dist = _dist;
                        target_piece = _piece;
                        target_col = _check_col;
                        target_row = _check_row;
                    }
                }
            }
        }
        
        // Decide next state
        if (target_piece != noone) {
            // Target found - highlight and prepare attack
            show_debug_message("Enemy: Target found at (" + string(target_col) + "," + string(target_row) + ")");
            enemy_state = "highlighting";
            state_timer = 0;
            
            // Store highlighted tiles for drawing
            highlighted_tiles = [{ col: target_col, row: target_row }];
        } else {
            // No target - move toward closest player piece
            show_debug_message("Enemy: No target in range, moving");
            enemy_state = "moving";
        }
        break;
    
    case "highlighting":
        // ATTACK WARNING
        // Wait for warning duration (1 turn in real game = instant in this turn)
        // For visual feedback, we wait a short delay
        state_timer++;
        
        var _warning_frames = 30;  // Half second of red highlight
        if (state_timer >= _warning_frames) {
            enemy_state = "attacking";
            state_timer = 0;
        }
        break;
    
    case "attacking":
        // EXECUTE ATTACK
        // Full implementation in PRP-012
        // For now, stub that transitions to turn_complete
        show_debug_message("Enemy: Attacking (stub - full impl in PRP-012)");
        
        // Clear highlights
        highlighted_tiles = [];
        
        enemy_state = "turn_complete";
        break;
    
    case "moving":
        // MOVE TOWARD PLAYER
        // Full implementation in PRP-011
        // For now, stub that transitions to turn_complete
        show_debug_message("Enemy: Moving (stub - full impl in PRP-011)");
        
        enemy_state = "turn_complete";
        break;
    
    case "turn_complete":
        // Handled by Enemy_Manager
        break;
}
```

### Step 5: Draw Attack Highlights

**File:** `objects/Enemy_Obj/Draw_0.gml` (addition)

Add before the normal draw:

```gml
// === ATTACK HIGHLIGHT ===
// Draw red warning on targeted tiles
if (array_length(highlighted_tiles) > 0 && enemy_state == "highlighting") {
    var _tile_size = Board_Manager.tile_size;
    var _pulse = 0.5 + 0.3 * sin(current_time / 150);  // Pulsing effect
    
    for (var i = 0; i < array_length(highlighted_tiles); i++) {
        var _tile = highlighted_tiles[i];
        var _tx = Object_Manager.topleft_x + _tile.col * _tile_size;
        var _ty = Object_Manager.topleft_y + _tile.row * _tile_size;
        
        // Draw red overlay
        draw_set_alpha(_pulse * 0.6);
        draw_rectangle_color(
            _tx, _ty,
            _tx + _tile_size - 1, _ty + _tile_size - 1,
            c_red, c_red, c_red, c_red, false
        );
        draw_set_alpha(1);
        
        // Draw danger icon (!)
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(_tx + _tile_size/2, _ty + _tile_size/2, "!");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}

// Continue with normal draw...
```

### Step 6: Update AI Manager Turn Detection

**File:** `objects/AI_Manager/Step_0.gml` (modification)

In the IDLE state, change:

```gml
// BEFORE:
if (Game_Manager.turn != 1) exit;

// AFTER (already correct, but verify):
if (Game_Manager.turn != 1) exit;
```

The AI Manager already correctly checks for `turn == 1`, so no changes needed. It will wait while enemies act (turn == 2).

### Step 7: Update Piece Turn Switch Handler

**File:** `objects/Chess_Piece_Obj/Step_0.gml` (modification)

The `pending_turn_switch` handler already sets `Game_Manager.turn` to whatever value is stored. Since we now store `2` for enemy turn, it will work automatically.

Verify this section exists and handles any value:

```gml
// Process deferred turn switch.
if (pending_turn_switch != undefined) {
    // ... existing skip logic ...
    
    if (!skip_turn_switch) {
        Game_Manager.turn = pending_turn_switch;
        pending_turn_switch = undefined;
    }
}
```

---

## Turn Flow Summary

1. **Player moves** (turn=0)
   - Tile_Obj sets `pending_turn_switch = 2` (if enemies exist) or `1` (if no enemies)
   
2. **Piece animation completes**
   - Chess_Piece_Obj sets `Game_Manager.turn = 2`
   
3. **Enemy turn begins** (turn=2)
   - Enemy_Manager builds queue of enemies
   - Processes each enemy sequentially
   
4. **Each enemy acts**
   - SCANNING → HIGHLIGHTING → ATTACKING (or MOVING)
   - Waits for animation between states
   
5. **All enemies done**
   - Enemy_Manager sets `turn = 1`
   
6. **AI turn** (turn=1)
   - AI_Manager processes as normal
   - After AI move, sets `turn = 0`
   
7. **Back to player**

---

## Known Gotchas

### Turn Value Confusion
- `turn = 0`: Player (white)
- `turn = 1`: AI (black chess pieces)
- `turn = 2`: Enemies (hostile units)
- `turn = 3`: Boss cheats (future, PRP-017)

Don't confuse "enemy" (hostile units) with "enemy army" (black chess pieces controlled by AI).

### Animation Synchronization
Always check `is_moving` before state transitions to prevent visual glitches.

### Dead Enemies
Always check `is_dead` and `instance_exists()` before processing an enemy.

### Multiple Tile_Obj Locations
The `pending_turn_switch` change needs to be applied to ALL locations in `Tile_Obj/Mouse_7.gml`:
- Normal moves
- Castling
- Stepping stone phase 2
- En passant

---

## Success Criteria

- [ ] Turn correctly cycles: Player → Enemies → AI → Player
- [ ] Each enemy processes its turn sequentially
- [ ] Enemy state machine transitions work
- [ ] Attack highlight appears during "highlighting" state
- [ ] Animations complete before next enemy acts
- [ ] Dead enemies are skipped
- [ ] Levels with no enemies skip directly to AI turn
- [ ] AI turn works normally after enemy turn
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Start Ruined_Overworld (1 enemy)
2. Move a player piece
3. Verify:
   - Turn switches to 2 (enemy)
   - Enemy processes (debug messages)
   - Turn switches to 1 (AI)
   - AI makes a move
   - Turn switches to 0 (player)

### Multiple Enemy Test

1. Configure level for 3 enemies (temp change in `enemy_get_level_config`)
2. Verify each enemy acts one at a time
3. Verify all enemies complete before AI turn

### Debug Display

Add to `Game_Manager/Draw_64.gml`:

```gml
// Show current turn state
var _turn_name = "";
switch (turn) {
    case 0: _turn_name = "PLAYER"; break;
    case 1: _turn_name = "AI"; break;
    case 2: _turn_name = "ENEMIES"; break;
    case 3: _turn_name = "BOSS CHEAT"; break;
}
draw_text(10, 10, "Turn: " + _turn_name);
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-011** — Implement enemy movement (fills in "moving" state)
2. **PRP-012** — Implement enemy attack (fills in "attacking" state)
