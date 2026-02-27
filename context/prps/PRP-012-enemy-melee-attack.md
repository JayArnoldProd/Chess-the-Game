# PRP-012: Enemy Attack System (Melee)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-010 (Enemy Turn System), PRP-011 (Enemy Movement System)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Melee attacks are the primary attack type for enemies:
1. **Attack site scanning:** Detect player pieces within vision range (e.g., 3×3)
2. **Tile highlighting:** Red glow on target tile(s), 1-turn warning
3. **Attack execution:** Enemy moves onto target tile, captures piece
4. **Committed attacks:** If target moves, enemy still attacks highlighted tile then shifts
5. **Multiple enemies targeting same piece:** First to highlight gets priority

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MELEE ATTACK FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   === TURN 1: SCAN & HIGHLIGHT ===                                          │
│                                                                              │
│   enemy_state = "scanning"                                                  │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────┐                                           │
│   │ Scan attack_site (3x3)    │  ◀── Check for player pieces               │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│        ┌────────┴────────┐                                                 │
│        │                 │                                                 │
│        ▼                 ▼                                                 │
│   ┌──────────┐     ┌───────────────┐                                       │
│   │ Target   │     │ No target     │                                       │
│   │ found    │     │ → "moving"    │                                       │
│   └────┬─────┘     └───────────────┘                                       │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────┐                                           │
│   │ Highlight target tile(s)  │  ◀── Red pulsing overlay                   │
│   │ enemy_state = "highlight" │                                            │
│   │ target_col/row stored     │                                            │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│                 ▼                                                           │
│   ┌────────────────────────────┐                                           │
│   │ END TURN 1                 │  ◀── Player gets warning                  │
│   │ (enemy waits until next   │                                            │
│   │  enemy turn to strike)    │                                            │
│   └────────────────────────────┘                                           │
│                                                                              │
│   === TURN 2: EXECUTE ATTACK ===                                            │
│                                                                              │
│   enemy_state = "attacking"                                                 │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────┐                                           │
│   │ Move to highlighted tile  │  ◀── Melee = move onto tile                │
│   │ (regardless of target!)   │      Attack is COMMITTED                   │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│        ┌────────┴────────┐                                                 │
│        │                 │                                                 │
│        ▼                 ▼                                                 │
│   ┌──────────────┐  ┌───────────────────┐                                  │
│   │ Target still │  │ Target moved      │                                  │
│   │ there        │  │ (tile empty)      │                                  │
│   └──────┬───────┘  └─────────┬─────────┘                                  │
│          │                    │                                            │
│          ▼                    ▼                                            │
│   ┌──────────────┐  ┌───────────────────┐                                  │
│   │ Capture!     │  │ Miss - land on    │                                  │
│   │ Destroy piece│  │ empty tile        │                                  │
│   └──────────────┘  └───────────────────┘                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Tile_Obj/Mouse_7.gml
  why: Pattern for capturing pieces

- path: objects/Chess_Piece_Obj/Step_0.gml
  why: Pattern for pending_capture, destroy animations
```

### Files to Modify

```yaml
- path: objects/Enemy_Obj/Step_0.gml
  changes: Update "scanning", "highlighting", and "attacking" states

- path: objects/Enemy_Obj/Draw_0.gml
  changes: Enhanced attack highlight visuals

- path: objects/Enemy_Obj/Create_0.gml
  changes: Add attack-related state variables
```

### Files to Create

```yaml
- path: scripts/enemy_execute_melee_attack/enemy_execute_melee_attack.gml
  purpose: Execute a melee attack on the highlighted tile

- path: scripts/enemy_check_attack_priority/enemy_check_attack_priority.gml
  purpose: Handle multiple enemies targeting same piece
```

---

## Implementation Blueprint

### Step 1: Add Attack State Variables

**File:** `objects/Enemy_Obj/Create_0.gml` (additions)

```gml
// === ATTACK STATE ===
attack_committed = false;        // Has attack been locked in (highlight shown)?
attack_target_col = -1;          // Column of committed attack
attack_target_row = -1;          // Row of committed attack
attack_executed = false;         // Has attack animation started?
attack_hit = false;              // Did attack connect with a piece?

// Visual effects
highlight_pulse_timer = 0;       // For pulsing red effect
```

### Step 2: Update Scanning State

**File:** `objects/Enemy_Obj/Step_0.gml` (update "scanning" case)

```gml
case "scanning":
    // SCAN FOR TARGETS
    var _def = enemy_def;
    if (_def == undefined) {
        enemy_state = "turn_complete";
        exit;
    }
    
    // Check if we already have a committed attack from previous turn
    if (attack_committed) {
        // Skip to attacking - we already highlighted last turn
        show_debug_message("Enemy: Has committed attack, proceeding to attack phase");
        enemy_state = "attacking";
        break;
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
            if (_check_col < 0 || _check_col >= 8) continue;
            if (_check_row < 0 || _check_row >= 8) continue;
            
            // Calculate pixel position
            var _check_x = Object_Manager.topleft_x + _check_col * Board_Manager.tile_size;
            var _check_y = Object_Manager.topleft_y + _check_row * Board_Manager.tile_size;
            
            // Check for player piece (piece_type == 0)
            var _piece = instance_position(_check_x, _check_y, Chess_Piece_Obj);
            if (_piece != noone && _piece.piece_type == 0 && !_piece.is_moving) {
                // Check if another enemy already has this target committed
                if (enemy_check_attack_priority(_piece)) {
                    continue;  // Another enemy has priority
                }
                
                // Found valid target - check if closest
                var _dist = max(abs(dx), abs(dy));
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
        // Target found - commit to attack
        show_debug_message("Enemy: Target found at (" + string(target_col) + "," + string(target_row) + 
            ") - " + target_piece.piece_id);
        
        // Commit the attack (locked in, even if target moves)
        attack_committed = true;
        attack_target_col = target_col;
        attack_target_row = target_row;
        
        // Store highlighted tiles for drawing
        highlighted_tiles = [{ col: target_col, row: target_row }];
        
        enemy_state = "highlighting";
        state_timer = 0;
        highlight_pulse_timer = 0;
    } else {
        // No target - move instead
        show_debug_message("Enemy: No target in attack range, moving");
        enemy_state = "moving";
    }
    break;
```

### Step 3: Update Highlighting State

**File:** `objects/Enemy_Obj/Step_0.gml` (update "highlighting" case)

```gml
case "highlighting":
    // ATTACK WARNING
    // Show red highlight on target tile for visual feedback
    // Design spec: 1-turn warning before attack
    // Implementation: Brief visual delay then end turn
    
    state_timer++;
    highlight_pulse_timer++;
    
    // Warning duration (30 frames = 0.5 seconds of visible warning)
    var _warning_frames = 30;
    
    if (state_timer >= _warning_frames) {
        // End this enemy's turn - attack executes NEXT enemy turn
        show_debug_message("Enemy: Highlight complete, attack committed for next turn");
        enemy_state = "turn_complete";
        
        // NOTE: attack_committed stays true
        // Next turn, scanning will detect this and skip to attacking
    }
    break;
```

### Step 4: Implement Attacking State

**File:** `objects/Enemy_Obj/Step_0.gml` (update "attacking" case)

```gml
case "attacking":
    // EXECUTE MELEE ATTACK
    // Move onto the committed tile (even if target has moved!)
    
    if (!attack_executed) {
        // First frame of attacking state - start the attack
        attack_executed = true;
        
        // Target tile (committed, doesn't change even if target moved)
        var _dest_col = attack_target_col;
        var _dest_row = attack_target_row;
        
        if (_dest_col < 0 || _dest_row < 0) {
            // No valid target - shouldn't happen but handle gracefully
            show_debug_message("Enemy: Invalid attack target, canceling");
            enemy_reset_attack_state();
            enemy_state = "turn_complete";
            break;
        }
        
        // Calculate destination position
        var _dest_x = Object_Manager.topleft_x + _dest_col * Board_Manager.tile_size;
        var _dest_y = Object_Manager.topleft_y + _dest_row * Board_Manager.tile_size;
        
        // Check if target piece is still there
        var _victim = instance_position(_dest_x, _dest_y, Chess_Piece_Obj);
        if (_victim != noone && _victim.piece_type == 0) {
            // Target still there - will capture
            attack_hit = true;
            show_debug_message("Enemy: Attacking " + _victim.piece_id + " at (" + 
                string(_dest_col) + "," + string(_dest_row) + ")");
        } else {
            // Target moved - attack misses but enemy still moves there
            attack_hit = false;
            show_debug_message("Enemy: Target moved! Attacking empty tile at (" + 
                string(_dest_col) + "," + string(_dest_row) + ")");
        }
        
        // Start movement to attack tile
        move_start_x = x;
        move_start_y = y;
        move_target_x = _dest_x;
        move_target_y = _dest_y;
        move_progress = 0;
        move_duration = enemy_def.movement_speed;
        is_moving = true;
        
        // Clear highlights
        highlighted_tiles = [];
    }
    
    // Wait for movement animation
    if (is_moving) {
        break;
    }
    
    // Animation complete - process capture
    if (attack_hit) {
        // Find and destroy the piece at this location
        var _victim = instance_position(x, y, Chess_Piece_Obj);
        if (_victim != noone && _victim.piece_type == 0) {
            // Play capture sound
            audio_play_sound(Piece_Capture_SFX, 1, false);
            
            // Check if this is the king (game over)
            if (_victim.piece_id == "king") {
                show_debug_message("Enemy: CAPTURED THE KING! Game over!");
                Game_Manager.game_over = true;
                Game_Manager.game_over_message = "Enemies Win!";
            }
            
            // Destroy the piece
            instance_destroy(_victim);
            show_debug_message("Enemy: Captured " + _victim.piece_id + "!");
        }
    } else {
        // Miss - play whiff sound if available
        show_debug_message("Enemy: Attack missed (target moved)");
    }
    
    // Reset attack state
    enemy_reset_attack_state();
    
    // Turn complete
    enemy_state = "turn_complete";
    break;
```

### Step 5: Attack State Reset Helper

**File:** `objects/Enemy_Obj/Step_0.gml` (add at end of file)

```gml
/// @function enemy_reset_attack_state()
/// @description Resets all attack-related state variables
function enemy_reset_attack_state() {
    attack_committed = false;
    attack_target_col = -1;
    attack_target_row = -1;
    attack_executed = false;
    attack_hit = false;
    highlighted_tiles = [];
    target_piece = noone;
    target_col = -1;
    target_row = -1;
}
```

### Step 6: Attack Priority Check

**File:** `scripts/enemy_check_attack_priority/enemy_check_attack_priority.gml`

```gml
/// @function enemy_check_attack_priority(_target_piece)
/// @param {Id.Instance} _target_piece The piece being considered as target
/// @returns {bool} True if another enemy already has priority on this target
/// @description Checks if another enemy has already committed an attack on this piece
function enemy_check_attack_priority(_target_piece) {
    if (!instance_exists(_target_piece)) return false;
    
    // Get target's grid position
    var _target_col = round((_target_piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _target_row = round((_target_piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Check all other enemies
    with (Enemy_Obj) {
        if (id == other) continue;  // Skip self
        if (is_dead) continue;
        
        // Check if this enemy has a committed attack on the same tile
        if (attack_committed && 
            attack_target_col == _target_col && 
            attack_target_row == _target_row) {
            return true;  // Another enemy has priority
        }
    }
    
    return false;  // No conflict, we can target this piece
}
```

### Step 7: Enhanced Attack Highlight Drawing

**File:** `objects/Enemy_Obj/Draw_0.gml` (update highlight section)

```gml
// === ATTACK HIGHLIGHT ===
// Draw pulsing red warning on targeted tiles
if (array_length(highlighted_tiles) > 0 && 
    (enemy_state == "highlighting" || attack_committed)) {
    
    var _tile_size = Board_Manager.tile_size;
    var _pulse = 0.5 + 0.3 * sin(highlight_pulse_timer / 5);  // Pulsing effect
    
    for (var i = 0; i < array_length(highlighted_tiles); i++) {
        var _tile = highlighted_tiles[i];
        var _tx = Object_Manager.topleft_x + _tile.col * _tile_size;
        var _ty = Object_Manager.topleft_y + _tile.row * _tile_size;
        
        // Draw red overlay with pulse
        draw_set_alpha(_pulse * 0.6);
        draw_rectangle_color(
            _tx, _ty,
            _tx + _tile_size - 1, _ty + _tile_size - 1,
            c_red, c_red, c_red, c_red, false
        );
        draw_set_alpha(1);
        
        // Draw border
        draw_rectangle_color(
            _tx, _ty,
            _tx + _tile_size - 1, _ty + _tile_size - 1,
            c_red, c_red, c_red, c_red, true
        );
        
        // Draw danger icon (!)
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text_transformed(_tx + _tile_size/2, _ty + _tile_size/2, "!", 1.5, 1.5, 0);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
    }
}
```

---

## Attack Timing Details

### Turn 1 (Highlight Turn)
1. Enemy scans for targets in attack site
2. Target found → commit attack, store target tile
3. Show red highlight on target tile
4. Enemy's turn ends

### Between Turns
- Highlight persists (drawn every frame via Draw_0)
- `attack_committed = true` persists
- Player can see warning and potentially move piece

### Turn 2 (Attack Turn)
1. Enemy scanning detects `attack_committed = true`
2. Jumps directly to "attacking" state
3. Moves onto committed tile (regardless of whether target moved)
4. If target present → capture
5. If target absent → miss, but still moves there

---

## Multiple Enemies Targeting Same Piece

Per design spec: "The first enemy to highlight gets priority and strikes first. The second enemy then tries to move toward the (now empty) tile."

Implementation:
1. `enemy_check_attack_priority()` prevents second enemy from targeting same tile
2. First enemy captures piece
3. Second enemy (if any) will move toward (now empty) tile on their turn

---

## Known Gotchas

### Committed Attack Persistence
`attack_committed` must persist across turns. Don't reset it in "turn_complete".

### Attack Site vs Attack Size
- **Attack Site:** Detection zone (e.g., 3×3) - where enemy LOOKS for targets
- **Attack Size:** Strike zone (e.g., 1×1) - how many tiles the attack HITS
- For placeholder enemy, both are effectively 1×1 (targets single tile)

### King Capture = Game Over
If enemy captures player's king, game ends immediately (enemies win).

---

## Success Criteria

- [ ] Enemy scans attack site for player pieces
- [ ] Red highlight appears on target tile
- [ ] Highlight persists until attack executes
- [ ] Enemy moves onto target tile (melee attack)
- [ ] Piece is captured if still on tile
- [ ] Attack still executes on empty tile if target moved (committed)
- [ ] Multiple enemies don't target same piece simultaneously
- [ ] Capture sound plays on successful hit
- [ ] King capture triggers game over
- [ ] Code compiles without errors

---

## Validation

### Basic Attack Test

1. Start level with 1 enemy
2. Move player piece into enemy's attack site (within 1 tile for 3×3)
3. Verify red highlight appears on piece's tile
4. Let enemy turn pass
5. Verify enemy moves onto piece and captures it

### Committed Attack Test

1. Enemy highlights a piece
2. Before enemy's next turn, move the targeted piece away
3. Verify enemy still moves to original highlighted tile
4. Verify attack "misses" (no capture, but enemy moved)

### Multiple Target Test

1. Place 2 player pieces in enemy's attack site
2. Verify enemy picks one (closest) to highlight
3. Verify other piece is not highlighted

### Priority Test

1. Have 2 enemies
2. Place player piece in range of both
3. Verify only first enemy commits attack
4. Second enemy should move instead

---

## Next Steps

After this PRP is implemented:
1. **PRP-013** — Implement ranged attacks (stay in place, projectile)
2. **PRP-014** — Implement HP and knockback (damage TO enemies)
