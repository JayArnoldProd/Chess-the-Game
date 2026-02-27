# PRP-018: Boss 1 — King's Son (Overworld)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** MEDIUM  
**Depends On:** PRP-017 (Boss Framework)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

The King's Son is the first boss encounter (Ruined Overworld). He uses medium AI that makes a "bad move" every 3 turns, and has two cheat abilities:

1. **"Go! My Horses!"** — Knights pulse yellow, get extra turns, revive from capture
2. **"Wah Wah Wah!"** — Board shakes, random pieces from both sides removed

This PRP implements both cheats with full animations and state tracking.

---

## Boss Specification (from Design Doc)

### AI Settings
- **Difficulty:** Medium (level 3)
- **Bad Move Frequency:** Every 3 turns
- **Bad Move Offset:** Pick 2nd-3rd best move

### Cheat 1 — "Go! My Horses!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | Condition-based (when boss decides to use it) |
| **Visual** | Both knights pulse yellow and advance |
| **Revival** | If a knight was captured → revives on home square |
| **Teleport** | If a knight is elsewhere → teleports to home square, then moves |
| **Home Square Capture** | If a piece (even own) occupies home square → captured to make room |
| **King Safety** | King can NEVER be on a square the horses can reach |
| **Duration** | Both knights move every turn for 5 turns (no other pieces move) |
| **Cancellation** | If 1 horse captured during cheat → cheat ends AND boss loses 1 turn |

### Cheat 2 — "Wah Wah Wah!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | After horse cheat ends |
| **Visual** | Board shakes |
| **Effect** | 1 random white piece + 1 random black piece removed |
| **Immunity** | Queens and kings cannot be removed |
| **Horse Interaction** | If a horse is knocked off, horse cheat won't trigger next time |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    KING'S SON CHEAT STATE MACHINE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     "GO! MY HORSES!" STATES                          │   │
│  │                                                                       │   │
│  │  start ──▶ pulse_knights ──▶ check_revival ──▶ teleport_home         │   │
│  │                                   │              │                    │   │
│  │                                   │              ▼                    │   │
│  │                                   │         capture_blocking          │   │
│  │                                   │              │                    │   │
│  │                                   │              ▼                    │   │
│  │                                   └───────▶ knight_move_phase         │   │
│  │                                                  │                    │   │
│  │                                                  ▼                    │   │
│  │                              (repeat for 5 turns OR until cancelled)  │   │
│  │                                                  │                    │   │
│  │                                                  ▼                    │   │
│  │                                             complete                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                         │
│                                   ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     "WAH WAH WAH!" STATES                            │   │
│  │                                                                       │   │
│  │  start ──▶ shake_board ──▶ select_victims ──▶ remove_pieces          │   │
│  │                                                  │                    │   │
│  │                                                  ▼                    │   │
│  │                                             complete                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: context/design-docs/enemy-boss-system-spec.md
  why: Boss 1 specification

- path: context/prps/PRP-017-boss-framework.md
  why: Boss_Manager, cheat execution framework

- path: objects/Knight_Obj/Create_0.gml
  why: Knight object structure

- path: objects/Chess_Piece_Obj/Step_0.gml
  why: Piece animation system
```

### Files to Create

```yaml
- path: scripts/boss_cheat_go_my_horses/boss_cheat_go_my_horses.gml
  purpose: "Go! My Horses!" cheat implementation

- path: scripts/boss_cheat_wah_wah_wah/boss_cheat_wah_wah_wah.gml
  purpose: "Wah Wah Wah!" cheat implementation

- path: scripts/boss_kings_son_utils/boss_kings_son_utils.gml
  purpose: Utility functions (knight home squares, pulse animation, etc.)
```

### Files to Modify

```yaml
- path: objects/Boss_Manager/Create_0.gml
  changes: Add King's Son specific state variables

- path: objects/Boss_Manager/Step_0.gml
  changes: Handle horse cheat turn tracking

- path: objects/Knight_Obj/Draw_0.gml
  changes: Add yellow pulse overlay when horse_cheat_active
```

---

## Implementation Blueprint

### Step 1: King's Son Utility Functions

**File:** `scripts/boss_kings_son_utils/boss_kings_son_utils.gml`

```gml
/// @function boss_ks_get_knight_home_square(_knight)
/// @param {instance} _knight The knight instance
/// @returns {struct} {col, row} home square position
/// @description Returns the original starting position for a knight
function boss_ks_get_knight_home_square(_knight) {
    // Black knights start at b8 (col 1, row 0) and g8 (col 6, row 0)
    // Determine which knight this is based on original position or tracking
    
    // If we're tracking original positions
    if (variable_instance_exists(_knight, "home_col")) {
        return { col: _knight.home_col, row: _knight.home_row };
    }
    
    // Otherwise, determine by current position (left or right side)
    var _col = round((_knight.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    
    // If on left half → home is b8 (col 1), else → g8 (col 6)
    var _home_col = (_col < 4) ? 1 : 6;
    var _home_row = 0;  // Row 0 = rank 8 (black's back rank)
    
    return { col: _home_col, row: _home_row };
}

/// @function boss_ks_get_all_knights(_color)
/// @param {real} _color 0=white, 1=black
/// @returns {array} Array of knight instances
function boss_ks_get_all_knights(_color) {
    var _knights = [];
    with (Knight_Obj) {
        if (piece_type == _color) {
            array_push(_knights, id);
        }
    }
    return _knights;
}

/// @function boss_ks_get_piece_at(_col, _row)
/// @param {real} _col Board column
/// @param {real} _row Board row
/// @returns {instance} Piece at position, or noone
function boss_ks_get_piece_at(_col, _row) {
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    return instance_position(_x, _y, Chess_Piece_Obj);
}

/// @function boss_ks_move_knight_to(_knight, _col, _row)
/// @param {instance} _knight The knight to move
/// @param {real} _col Target column
/// @param {real} _row Target row
/// @description Animates knight movement to target position
function boss_ks_move_knight_to(_knight, _col, _row) {
    if (!instance_exists(_knight)) return;
    
    var _to_x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _to_y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    with (_knight) {
        move_start_x = x;
        move_start_y = y;
        move_target_x = _to_x;
        move_target_y = _to_y;
        move_progress = 0;
        move_duration = 20;  // Faster during cheat
        is_moving = true;
        move_animation_type = "knight";
    }
}

/// @function boss_ks_teleport_knight(_knight, _col, _row)
/// @param {instance} _knight The knight to teleport
/// @param {real} _col Target column
/// @param {real} _row Target row
/// @description Instant teleport with flash effect
function boss_ks_teleport_knight(_knight, _col, _row) {
    if (!instance_exists(_knight)) return;
    
    var _to_x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _to_y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // Set teleport flash flag (handled in Draw event)
    _knight.teleport_flash_timer = 15;
    
    // Instant position change
    _knight.x = _to_x;
    _knight.y = _to_y;
}

/// @function boss_ks_get_knight_attack_squares(_col, _row)
/// @param {real} _col Knight column
/// @param {real} _row Knight row
/// @returns {array} Array of {col, row} squares the knight can attack
function boss_ks_get_knight_attack_squares(_col, _row) {
    var _squares = [];
    var _offsets = [
        [1, -2], [1, 2], [-1, -2], [-1, 2],
        [2, -1], [2, 1], [-2, -1], [-2, 1]
    ];
    
    for (var i = 0; i < 8; i++) {
        var _nc = _col + _offsets[i][0];
        var _nr = _row + _offsets[i][1];
        if (_nc >= 0 && _nc < 8 && _nr >= 0 && _nr < 8) {
            array_push(_squares, { col: _nc, row: _nr });
        }
    }
    
    return _squares;
}

/// @function boss_ks_is_king_safe_from_horses(_king)
/// @param {instance} _king The king instance
/// @returns {bool} True if king is not on any horse-attackable square
function boss_ks_is_king_safe_from_horses(_king) {
    if (!instance_exists(_king)) return true;
    
    var _king_col = round((_king.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _king_row = round((_king.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Get all black knights
    var _knights = boss_ks_get_all_knights(1);
    
    for (var i = 0; i < array_length(_knights); i++) {
        var _kn = _knights[i];
        var _kn_col = round((_kn.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var _kn_row = round((_kn.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        
        var _attacks = boss_ks_get_knight_attack_squares(_kn_col, _kn_row);
        for (var j = 0; j < array_length(_attacks); j++) {
            if (_attacks[j].col == _king_col && _attacks[j].row == _king_row) {
                return false;  // King is on attackable square
            }
        }
    }
    
    return true;
}

/// @function boss_ks_revive_knight(_home_col, _home_row)
/// @param {real} _home_col Home column
/// @param {real} _home_row Home row
/// @returns {instance} The newly created knight
function boss_ks_revive_knight(_home_col, _home_row) {
    var _x = Object_Manager.topleft_x + _home_col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _home_row * Board_Manager.tile_size;
    
    var _knight = instance_create_depth(_x, _y, -1, Knight_Obj);
    _knight.piece_type = 1;  // Black
    _knight.has_moved = true;
    _knight.home_col = _home_col;
    _knight.home_row = _home_row;
    _knight.revived = true;
    _knight.revival_flash_timer = 30;
    
    show_debug_message("Boss KS: Revived knight at (" + 
        string(_home_col) + "," + string(_home_row) + ")");
    
    return _knight;
}
```

### Step 2: "Go! My Horses!" Cheat Implementation

**File:** `scripts/boss_cheat_go_my_horses/boss_cheat_go_my_horses.gml`

```gml
/// @function boss_cheat_go_my_horses()
/// @returns {bool} True if cheat execution is complete
/// @description "Go! My Horses!" - Knights get 5 turns of exclusive movement
function boss_cheat_go_my_horses() {
    // State machine for horse cheat
    var _mgr = Boss_Manager;
    
    // Initialize cheat state if starting
    if (!variable_instance_exists(_mgr, "horses_state")) {
        _mgr.horses_state = "init";
        _mgr.horses_turn_count = 0;
        _mgr.horses_max_turns = 5;
        _mgr.horses_knights = [];
        _mgr.horses_move_index = 0;
        _mgr.horses_waiting_animation = false;
        show_debug_message("Boss KS: Starting 'Go! My Horses!' cheat");
    }
    
    switch (_mgr.horses_state) {
        case "init":
            // Check for existing black knights
            _mgr.horses_knights = boss_ks_get_all_knights(1);
            
            // Track which knights need revival
            var _needs_revival = [];
            var _home_squares = [
                { col: 1, row: 0 },  // b8
                { col: 6, row: 0 }   // g8
            ];
            
            for (var i = 0; i < 2; i++) {
                var _home = _home_squares[i];
                var _found = false;
                
                // Check if a knight exists for this home square
                for (var j = 0; j < array_length(_mgr.horses_knights); j++) {
                    var _kn = _mgr.horses_knights[j];
                    var _kn_home = boss_ks_get_knight_home_square(_kn);
                    if (_kn_home.col == _home.col && _kn_home.row == _home.row) {
                        _found = true;
                        break;
                    }
                }
                
                if (!_found) {
                    array_push(_needs_revival, _home);
                }
            }
            
            _mgr.horses_needs_revival = _needs_revival;
            _mgr.horses_state = "check_revival";
            break;
            
        case "check_revival":
            // Revive any captured knights
            if (array_length(_mgr.horses_needs_revival) > 0) {
                var _home = array_pop(_mgr.horses_needs_revival);
                
                // Check if home square is occupied
                var _blocker = boss_ks_get_piece_at(_home.col, _home.row);
                if (_blocker != noone) {
                    // Capture the blocking piece
                    show_debug_message("Boss KS: Capturing piece on knight home square");
                    instance_destroy(_blocker);
                    audio_play_sound(Piece_Capture_SFX, 1, false);
                }
                
                // Revive the knight
                var _knight = boss_ks_revive_knight(_home.col, _home.row);
                array_push(_mgr.horses_knights, _knight);
                
                // Wait a moment for visual effect
                _mgr.horses_revival_timer = 30;
                _mgr.horses_state = "revival_wait";
            } else {
                _mgr.horses_state = "teleport_check";
            }
            break;
            
        case "revival_wait":
            _mgr.horses_revival_timer--;
            if (_mgr.horses_revival_timer <= 0) {
                _mgr.horses_state = "check_revival";
            }
            break;
            
        case "teleport_check":
            // Check if any knights need to teleport to home square
            for (var i = 0; i < array_length(_mgr.horses_knights); i++) {
                var _kn = _mgr.horses_knights[i];
                if (!instance_exists(_kn)) continue;
                
                var _kn_col = round((_kn.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
                var _kn_row = round((_kn.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
                var _home = boss_ks_get_knight_home_square(_kn);
                
                if (_kn_col != _home.col || _kn_row != _home.row) {
                    // Knight not at home — check for blocker
                    var _blocker = boss_ks_get_piece_at(_home.col, _home.row);
                    if (_blocker != noone && _blocker != _kn) {
                        show_debug_message("Boss KS: Capturing piece to teleport knight home");
                        instance_destroy(_blocker);
                        audio_play_sound(Piece_Capture_SFX, 1, false);
                    }
                    
                    // Teleport to home
                    boss_ks_teleport_knight(_kn, _home.col, _home.row);
                }
            }
            
            _mgr.horses_state = "pulse_start";
            _mgr.horses_pulse_timer = 45;  // Pulse for ~0.75 seconds
            break;
            
        case "pulse_start":
            // Start yellow pulse on all knights
            for (var i = 0; i < array_length(_mgr.horses_knights); i++) {
                var _kn = _mgr.horses_knights[i];
                if (instance_exists(_kn)) {
                    _kn.horse_cheat_pulse = true;
                }
            }
            
            _mgr.horses_pulse_timer--;
            if (_mgr.horses_pulse_timer <= 0) {
                _mgr.horses_state = "knight_turn";
                _mgr.horses_move_index = 0;
            }
            break;
            
        case "knight_turn":
            // Each knight gets to make a move
            if (_mgr.horses_move_index >= array_length(_mgr.horses_knights)) {
                // All knights moved this turn
                _mgr.horses_turn_count++;
                show_debug_message("Boss KS: Horse turn " + string(_mgr.horses_turn_count) + 
                    "/" + string(_mgr.horses_max_turns) + " complete");
                
                if (_mgr.horses_turn_count >= _mgr.horses_max_turns) {
                    _mgr.horses_state = "complete";
                } else {
                    // Check if any knight was captured (cancellation)
                    var _knights_alive = 0;
                    for (var i = 0; i < array_length(_mgr.horses_knights); i++) {
                        if (instance_exists(_mgr.horses_knights[i])) {
                            _knights_alive++;
                        }
                    }
                    
                    if (_knights_alive < array_length(_mgr.horses_knights)) {
                        show_debug_message("Boss KS: Knight captured! Cheat cancelled, boss loses turn");
                        _mgr.horses_cancelled = true;
                        _mgr.boss_lose_next_turn = true;
                        _mgr.horses_state = "complete";
                    } else {
                        // Continue to next turn
                        _mgr.horses_move_index = 0;
                        // Yield control back to player for one turn
                        _mgr.horses_state = "wait_player_turn";
                    }
                }
                break;
            }
            
            // Wait for animations to complete
            var _any_moving = false;
            with (Chess_Piece_Obj) {
                if (is_moving) {
                    _any_moving = true;
                    break;
                }
            }
            if (_any_moving) break;
            
            // Get current knight
            var _knight = _mgr.horses_knights[_mgr.horses_move_index];
            if (!instance_exists(_knight)) {
                _mgr.horses_move_index++;
                break;
            }
            
            // Calculate best knight move (simple: move toward enemy king)
            var _best_move = boss_ks_calculate_knight_move(_knight);
            if (_best_move != undefined) {
                // Check if target has a piece (capture)
                var _target_piece = boss_ks_get_piece_at(_best_move.col, _best_move.row);
                if (_target_piece != noone && _target_piece.piece_type == 0) {
                    // Capture white piece
                    instance_destroy(_target_piece);
                    audio_play_sound(Piece_Capture_SFX, 1, false);
                }
                
                boss_ks_move_knight_to(_knight, _best_move.col, _best_move.row);
                _mgr.horses_waiting_animation = true;
            }
            
            _mgr.horses_move_index++;
            break;
            
        case "wait_player_turn":
            // During horse cheat, player still gets turns between horse turns
            // This state yields control back to the normal turn system
            // The cheat will resume on the next boss cheat phase
            
            // Mark that horse cheat is ongoing
            _mgr.horses_cheat_active = true;
            _mgr.horses_state = "knight_turn";
            return true;  // Complete this cheat phase, will resume next turn
            
        case "complete":
            // Clean up pulse effect
            for (var i = 0; i < array_length(_mgr.horses_knights); i++) {
                var _kn = _mgr.horses_knights[i];
                if (instance_exists(_kn)) {
                    _kn.horse_cheat_pulse = false;
                }
            }
            
            // Reset state
            _mgr.horses_cheat_active = false;
            _mgr.horses_state = undefined;
            
            // Trigger "Wah Wah Wah!" after horses
            if (!_mgr.horses_cancelled) {
                array_push(_mgr.cheat_queue, "wah_wah_wah");
            }
            
            show_debug_message("Boss KS: 'Go! My Horses!' cheat complete");
            return true;
    }
    
    return false;  // Cheat still in progress
}

/// @function boss_ks_calculate_knight_move(_knight)
/// @param {instance} _knight The knight to calculate a move for
/// @returns {struct} {col, row} best move, or undefined
function boss_ks_calculate_knight_move(_knight) {
    if (!instance_exists(_knight)) return undefined;
    
    var _kn_col = round((_knight.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _kn_row = round((_knight.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Get all possible knight moves
    var _moves = boss_ks_get_knight_attack_squares(_kn_col, _kn_row);
    if (array_length(_moves) == 0) return undefined;
    
    // Find white king position
    var _king_col = 4;
    var _king_row = 7;
    with (King_Obj) {
        if (piece_type == 0) {
            _king_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            _king_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            break;
        }
    }
    
    // Score each move: prefer captures, then moves toward king
    var _best_move = undefined;
    var _best_score = -9999;
    
    for (var i = 0; i < array_length(_moves); i++) {
        var _move = _moves[i];
        var _score = 0;
        
        // Check what's on target square
        var _target = boss_ks_get_piece_at(_move.col, _move.row);
        
        // Can't move to square with own piece
        if (_target != noone && _target.piece_type == 1) continue;
        
        // Capture bonus
        if (_target != noone && _target.piece_type == 0) {
            _score += 100;
            // Extra for capturing valuable pieces
            switch (_target.piece_id) {
                case "queen": _score += 500; break;
                case "rook": _score += 200; break;
                case "bishop": _score += 150; break;
                case "knight": _score += 150; break;
                case "pawn": _score += 50; break;
            }
        }
        
        // Distance to king (closer = better)
        var _dist = point_distance(_move.col, _move.row, _king_col, _king_row);
        _score -= _dist * 10;
        
        // Check if this puts knight in check position
        var _attacks = boss_ks_get_knight_attack_squares(_move.col, _move.row);
        for (var j = 0; j < array_length(_attacks); j++) {
            if (_attacks[j].col == _king_col && _attacks[j].row == _king_row) {
                _score += 300;  // Bonus for checking the king
                break;
            }
        }
        
        if (_score > _best_score) {
            _best_score = _score;
            _best_move = _move;
        }
    }
    
    return _best_move;
}
```

### Step 3: "Wah Wah Wah!" Cheat Implementation

**File:** `scripts/boss_cheat_wah_wah_wah/boss_cheat_wah_wah_wah.gml`

```gml
/// @function boss_cheat_wah_wah_wah()
/// @returns {bool} True if cheat execution is complete
/// @description "Wah Wah Wah!" - Board shakes, removes 1 random piece from each side
function boss_cheat_wah_wah_wah() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "wah_state")) {
        _mgr.wah_state = "init";
        _mgr.wah_shake_timer = 0;
        _mgr.wah_shake_intensity = 0;
        _mgr.wah_white_victim = noone;
        _mgr.wah_black_victim = noone;
        show_debug_message("Boss KS: Starting 'Wah Wah Wah!' cheat");
    }
    
    switch (_mgr.wah_state) {
        case "init":
            // Start board shake
            _mgr.wah_shake_timer = 60;  // 1 second shake
            _mgr.wah_shake_intensity = 8;
            _mgr.wah_state = "shake";
            
            // Play shake sound
            audio_play_sound(Board_Shake_SFX, 1, false);
            break;
            
        case "shake":
            // Apply shake to board (handled in Board_Manager draw)
            _mgr.wah_shake_timer--;
            
            // Decrease intensity over time
            _mgr.wah_shake_intensity = 8 * (_mgr.wah_shake_timer / 60);
            
            if (_mgr.wah_shake_timer <= 30) {
                // Select victims midway through shake
                if (_mgr.wah_white_victim == noone) {
                    _mgr.wah_white_victim = boss_ks_select_random_piece(0);
                    _mgr.wah_black_victim = boss_ks_select_random_piece(1);
                    
                    // Mark them as falling
                    if (instance_exists(_mgr.wah_white_victim)) {
                        _mgr.wah_white_victim.falling_off_board = true;
                        _mgr.wah_white_victim.fall_timer = 0;
                    }
                    if (instance_exists(_mgr.wah_black_victim)) {
                        _mgr.wah_black_victim.falling_off_board = true;
                        _mgr.wah_black_victim.fall_timer = 0;
                    }
                }
            }
            
            if (_mgr.wah_shake_timer <= 0) {
                _mgr.wah_state = "remove";
            }
            break;
            
        case "remove":
            // Destroy victims
            if (instance_exists(_mgr.wah_white_victim)) {
                // Check if it's a knight (affects horse cheat)
                if (_mgr.wah_white_victim.piece_id == "knight") {
                    _mgr.white_knight_removed = true;
                }
                
                show_debug_message("Boss KS: Removing white " + _mgr.wah_white_victim.piece_id);
                instance_destroy(_mgr.wah_white_victim);
            }
            
            if (instance_exists(_mgr.wah_black_victim)) {
                // Check if it's a knight (prevents future horse cheat)
                if (_mgr.wah_black_victim.piece_id == "knight") {
                    _mgr.black_knight_removed = true;
                    _mgr.horses_disabled = true;
                    show_debug_message("Boss KS: Horse removed - future horse cheat disabled!");
                }
                
                show_debug_message("Boss KS: Removing black " + _mgr.wah_black_victim.piece_id);
                instance_destroy(_mgr.wah_black_victim);
            }
            
            _mgr.wah_state = "complete";
            break;
            
        case "complete":
            // Reset state
            _mgr.wah_shake_intensity = 0;
            _mgr.wah_state = undefined;
            
            show_debug_message("Boss KS: 'Wah Wah Wah!' cheat complete");
            return true;
    }
    
    return false;
}

/// @function boss_ks_select_random_piece(_color)
/// @param {real} _color 0=white, 1=black
/// @returns {instance} Random piece (not queen or king), or noone
function boss_ks_select_random_piece(_color) {
    var _candidates = [];
    
    with (Chess_Piece_Obj) {
        if (piece_type == _color) {
            // Cannot remove queens or kings
            if (piece_id != "queen" && piece_id != "king") {
                array_push(_candidates, id);
            }
        }
    }
    
    if (array_length(_candidates) == 0) {
        show_debug_message("Boss KS: No valid pieces to remove for color " + string(_color));
        return noone;
    }
    
    var _idx = irandom(array_length(_candidates) - 1);
    return _candidates[_idx];
}
```

### Step 4: Knight Draw Modifications

**Add to `objects/Knight_Obj/Draw_0.gml`:**

```gml
/// Knight_Obj Draw Event additions for boss cheat effects

// === HORSE CHEAT PULSE EFFECT ===
if (variable_instance_exists(id, "horse_cheat_pulse") && horse_cheat_pulse) {
    var _pulse = (sin(current_time / 100) + 1) / 2;  // 0 to 1
    var _alpha = 0.3 + _pulse * 0.4;  // 0.3 to 0.7
    
    // Yellow glow overlay
    draw_set_color(c_yellow);
    draw_set_alpha(_alpha);
    draw_sprite(sprite_index, image_index, x, y);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// === TELEPORT FLASH EFFECT ===
if (variable_instance_exists(id, "teleport_flash_timer") && teleport_flash_timer > 0) {
    teleport_flash_timer--;
    var _flash = teleport_flash_timer / 15;  // Fade from 1 to 0
    
    draw_set_color(c_white);
    draw_set_alpha(_flash * 0.8);
    draw_sprite(sprite_index, image_index, x, y);
    draw_set_alpha(1);
}

// === REVIVAL FLASH EFFECT ===
if (variable_instance_exists(id, "revival_flash_timer") && revival_flash_timer > 0) {
    revival_flash_timer--;
    var _flash = revival_flash_timer / 30;
    
    // Golden sparkle effect
    draw_set_color(c_yellow);
    draw_set_alpha(_flash * 0.6);
    
    for (var i = 0; i < 4; i++) {
        var _angle = i * 90 + current_time / 50;
        var _radius = 10 * (1 - _flash);
        var _px = x + lengthdir_x(_radius, _angle);
        var _py = y + lengthdir_y(_radius, _angle);
        draw_circle(_px, _py, 3 * _flash, false);
    }
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}
```

### Step 5: Board Shake Effect

**Add to `objects/Board_Manager/Draw_0.gml` (or create if needed):**

```gml
/// Board_Manager Draw Event - apply shake effect

// Check for shake from boss cheat
var _shake_x = 0;
var _shake_y = 0;

if (instance_exists(Boss_Manager) && 
    variable_instance_exists(Boss_Manager, "wah_shake_intensity")) {
    var _intensity = Boss_Manager.wah_shake_intensity;
    if (_intensity > 0) {
        _shake_x = irandom_range(-_intensity, _intensity);
        _shake_y = irandom_range(-_intensity, _intensity);
    }
}

// Apply shake offset to board rendering
// (This would be applied in Tile drawing, piece drawing, etc.)
global.board_shake_offset_x = _shake_x;
global.board_shake_offset_y = _shake_y;
```

---

## Known Gotchas

### Knight Home Squares
- b8 (col=1, row=0) — Queen-side knight
- g8 (col=6, row=0) — King-side knight

Make sure to track which knight is which to return them to the correct home.

### Piece Destruction During Cheat
When destroying pieces during cheats, the AI's board state becomes stale. Always call `boss_resync_board_state()` after the cheat completes.

### Turn Timing
The horse cheat spans multiple player turns. The cheat state persists in `Boss_Manager` between turns.

### Animation Waiting
Always check for `is_moving` animations before proceeding to the next cheat step.

### Sound Assets
Required sounds:
- `Piece_Capture_SFX` — Already exists
- `Board_Shake_SFX` — May need to be created/placeholder

---

## Success Criteria

- [ ] "Go! My Horses!" announces correctly
- [ ] Knights pulse yellow during cheat
- [ ] Captured knights revive at home square
- [ ] Knights teleport to home square if not already there
- [ ] Blocking pieces are captured to make room
- [ ] Knights move for 5 turns during cheat
- [ ] Cheat cancels if a knight is captured (boss loses turn)
- [ ] "Wah Wah Wah!" triggers after horse cheat
- [ ] Board shakes during "Wah Wah Wah!"
- [ ] One random white and one random black piece removed
- [ ] Queens and kings are never removed
- [ ] Removing a black knight disables future horse cheats
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Load King's Son boss room
2. Trigger horse cheat (may need debug key to force)
3. Verify knight pulse effect
4. Capture one knight
5. Verify cheat cancels and boss loses turn
6. Trigger full horse cheat (5 turns)
7. Verify "Wah Wah Wah!" triggers
8. Verify board shakes
9. Verify pieces removed

### Debug Keys

Add to `Boss_Manager/KeyPress_72.gml` (H key):
```gml
// DEBUG: Force horse cheat
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "kings_son") {
    array_push(cheat_queue, "go_my_horses");
    Game_Manager.turn = 3;  // Enter cheat phase
    show_debug_message("DEBUG: Forced horse cheat");
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-019** — Queen boss (Cut the Slack!, Enchant!)
2. Test horse cheat thoroughly
3. Add proper sound effects
