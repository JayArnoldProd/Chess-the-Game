# PRP-021: Boss 4 — The King (Final Boss)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** LOW (due to complexity; implement last)  
**Depends On:** PRP-017 (Boss Framework)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

The King is the final boss encounter — the climactic battle. He uses strong AI (highest difficulty) and has a **two-phase** fight with multiple random abilities in phase 2:

1. **Phase 1: "Look Who's on Top Now!"** — All pawns become kings; defeat the extras to trigger phase 2
2. **Phase 2: "Back Off!"** — Board resets, random devastating abilities every 2 turns

This PRP implements the multi-phase structure, visual transformations, move undo mechanic, and all phase 2 abilities.

---

## Boss Specification (from Design Doc)

### AI Settings
- **Difficulty:** Strong (level 5 — highest)
- **Bad Move Frequency:** NEVER (plays optimally)
- **Search Time:** 10 seconds

### Phase 1 — "Look Who's on Top Now!"

| Aspect | Behavior |
|--------|----------|
| **Pre-Match Setup** | All black pawns transform into KINGS |
| **Boss Movement** | Boss only moves kings until extras defeated |
| **King Tracking** | Must track extra kings vs. original king |
| **Phase Transition** | When only original king remains → Phase 2 triggers |
| **Visual** | Pawns transform with crown animation |

### Phase 2 — "Back Off!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | Automatic after Phase 1 ends |
| **Board Reset** | All pieces return to original starting positions |
| **Pawn Revival** | All pawns (both sides) are revived |
| **Ability Frequency** | Every 2 turns, one random ability activates |

### Phase 2 Abilities (Random Selection)

| Ability | Quote | Effect |
|---------|-------|--------|
| **Invulnerable** | "I'm Invulnerable Now!" | King levitates 3 turns — cannot be targeted or captured |
| **Pity** | "Oh, I'll Pity You..." | King flicks one of his pawns to player side (player gains it) |
| **Undo** | "That Move Doesn't Count!" | Undoes player's last move INCLUDING captures |
| **Lose Turn** | "I... I Don't Know..." | King freezes — loses his turn |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     THE KING BOSS ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    PHASE 1: "LOOK WHO'S ON TOP NOW!"                   │  │
│  │                                                                        │  │
│  │   Pre-Match:                        During Phase 1:                    │  │
│  │   ┌─────────────────────────┐      ┌─────────────────────────┐       │  │
│  │   │ P P P P P P P P         │      │ K K K K K K K K         │       │  │
│  │   │ (8 pawns)               │ ──▶  │ (8 "extra" kings)       │       │  │
│  │   │                         │      │                         │       │  │
│  │   │ + original King         │      │ + original King         │       │  │
│  │   └─────────────────────────┘      └─────────────────────────┘       │  │
│  │                                                                        │  │
│  │   Transition Condition: All extra kings captured                       │  │
│  │                         Only original king remains                     │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                     │                                        │
│                                     ▼                                        │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    PHASE 2: "BACK OFF!"                                │  │
│  │                                                                        │  │
│  │   ┌─────────────────────────────────────────────────────────────────┐ │  │
│  │   │  1. Board Reset: All pieces return to starting positions        │ │  │
│  │   │  2. Pawn Revival: All captured pawns return                     │ │  │
│  │   │  3. Every 2 turns: Random ability triggers                      │ │  │
│  │   └─────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                        │  │
│  │   Random Abilities:                                                    │  │
│  │   ┌──────────────────┬──────────────────┬──────────────────┐         │  │
│  │   │  INVULNERABLE    │  PITY            │  UNDO            │         │  │
│  │   │  (25% chance)    │  (25% chance)    │  (25% chance)    │         │  │
│  │   │                  │                  │                  │         │  │
│  │   │  King levitates  │  Give pawn to    │  Undo player's   │         │  │
│  │   │  3 turns, can't  │  player (side    │  last move,      │         │  │
│  │   │  be captured     │  switch)         │  restore capture │         │  │
│  │   └──────────────────┴──────────────────┴──────────────────┘         │  │
│  │   ┌──────────────────┐                                                │  │
│  │   │  LOSE TURN       │                                                │  │
│  │   │  (25% chance)    │                                                │  │
│  │   │                  │                                                │  │
│  │   │  King freezes,   │                                                │  │
│  │   │  skips turn      │                                                │  │
│  │   └──────────────────┘                                                │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: context/design-docs/enemy-boss-system-spec.md
  why: Boss 4 specification

- path: context/prps/PRP-017-boss-framework.md
  why: Boss_Manager, cheat execution framework, phase system

- path: objects/King_Obj/Create_0.gml
  why: King object structure

- path: objects/Pawn_Obj/Create_0.gml
  why: Pawn object structure (for transformation)
```

### Files to Create

```yaml
- path: scripts/boss_cheat_look_whos_on_top/boss_cheat_look_whos_on_top.gml
  purpose: Phase 1 setup and tracking

- path: scripts/boss_cheat_back_off/boss_cheat_back_off.gml
  purpose: Phase 2 transition and board reset

- path: scripts/boss_cheat_invulnerable/boss_cheat_invulnerable.gml
  purpose: "I'm Invulnerable Now!" ability

- path: scripts/boss_cheat_pity/boss_cheat_pity.gml
  purpose: "Oh, I'll Pity You..." ability

- path: scripts/boss_cheat_undo/boss_cheat_undo.gml
  purpose: "That Move Doesn't Count!" ability

- path: scripts/boss_cheat_lose_turn/boss_cheat_lose_turn.gml
  purpose: "I... I Don't Know..." ability

- path: scripts/boss_king_utils/boss_king_utils.gml
  purpose: Utility functions (phase detection, move history, etc.)
```

### Files to Modify

```yaml
- path: objects/Boss_Manager/Create_0.gml
  changes: Add The King specific state variables, phase tracking

- path: objects/Boss_Manager/Step_0.gml
  changes: Phase transition detection, ability scheduling

- path: objects/King_Obj/Draw_0.gml
  changes: Invulnerability levitate visual, extra king indicator

- path: objects/Chess_Piece_Obj/Step_0.gml
  changes: Track move history for undo mechanic
```

---

## Implementation Blueprint

### Step 1: The King Utility Functions

**File:** `scripts/boss_king_utils/boss_king_utils.gml`

```gml
/// @function boss_king_get_original_king()
/// @returns {instance} The original black king, or noone
function boss_king_get_original_king() {
    if (!instance_exists(Boss_Manager)) return noone;
    if (!variable_instance_exists(Boss_Manager, "original_king")) return noone;
    
    var _king = Boss_Manager.original_king;
    if (instance_exists(_king)) return _king;
    
    return noone;
}

/// @function boss_king_get_extra_kings()
/// @returns {array} Array of extra king instances (pawns transformed)
function boss_king_get_extra_kings() {
    if (!instance_exists(Boss_Manager)) return [];
    if (!variable_instance_exists(Boss_Manager, "extra_kings")) return [];
    
    var _result = [];
    var _extra = Boss_Manager.extra_kings;
    
    for (var i = 0; i < array_length(_extra); i++) {
        if (instance_exists(_extra[i])) {
            array_push(_result, _extra[i]);
        }
    }
    
    return _result;
}

/// @function boss_king_count_extra_kings()
/// @returns {real} Number of extra kings still alive
function boss_king_count_extra_kings() {
    return array_length(boss_king_get_extra_kings());
}

/// @function boss_king_transform_pawn_to_king(_pawn)
/// @param {instance} _pawn The pawn to transform
/// @returns {instance} The new king instance
function boss_king_transform_pawn_to_king(_pawn) {
    if (!instance_exists(_pawn)) return noone;
    
    var _x = _pawn.x;
    var _y = _pawn.y;
    var _type = _pawn.piece_type;
    
    // Start transformation animation on pawn
    _pawn.transforming = true;
    _pawn.transform_timer = 30;
    _pawn.transform_to_king = true;
    
    // We'll create the king when animation completes
    // Store position for later
    return _pawn;  // Return pawn for tracking, king created after anim
}

/// @function boss_king_complete_transformation(_pawn)
/// @param {instance} _pawn The pawn that finished transforming
/// @returns {instance} The new king instance
function boss_king_complete_transformation(_pawn) {
    if (!instance_exists(_pawn)) return noone;
    
    var _x = _pawn.x;
    var _y = _pawn.y;
    
    // Create new king
    var _king = instance_create_depth(_x, _y, -1, King_Obj);
    _king.piece_type = 1;  // Black
    _king.has_moved = true;
    _king.is_extra_king = true;  // Mark as transformed pawn
    _king.original_was_pawn = true;
    _king.crown_rise_timer = 20;  // Crown animation
    
    // Destroy pawn
    instance_destroy(_pawn);
    
    // Track in Boss_Manager
    if (instance_exists(Boss_Manager)) {
        if (!variable_instance_exists(Boss_Manager, "extra_kings")) {
            Boss_Manager.extra_kings = [];
        }
        array_push(Boss_Manager.extra_kings, _king);
    }
    
    show_debug_message("Boss King: Pawn transformed to King at (" + 
        string(_x) + "," + string(_y) + ")");
    
    return _king;
}

/// @function boss_king_record_move(_move_data)
/// @param {struct} _move_data Move information to record
/// @description Records a player move for potential undo
function boss_king_record_move(_move_data) {
    if (!instance_exists(Boss_Manager)) return;
    
    if (!variable_instance_exists(Boss_Manager, "move_history")) {
        Boss_Manager.move_history = [];
    }
    
    // Keep last 5 moves
    array_push(Boss_Manager.move_history, _move_data);
    if (array_length(Boss_Manager.move_history) > 5) {
        array_delete(Boss_Manager.move_history, 0, 1);
    }
}

/// @function boss_king_get_last_move()
/// @returns {struct} Last recorded move, or undefined
function boss_king_get_last_move() {
    if (!instance_exists(Boss_Manager)) return undefined;
    if (!variable_instance_exists(Boss_Manager, "move_history")) return undefined;
    
    var _history = Boss_Manager.move_history;
    if (array_length(_history) == 0) return undefined;
    
    return _history[array_length(_history) - 1];
}

/// @function boss_king_get_black_pawns()
/// @returns {array} Array of black pawn instances
function boss_king_get_black_pawns() {
    var _pawns = [];
    with (Pawn_Obj) {
        if (piece_type == 1) {
            array_push(_pawns, id);
        }
    }
    return _pawns;
}

/// @function boss_king_reset_board()
/// @description Reset all pieces to starting positions
function boss_king_reset_board() {
    show_debug_message("Boss King: Resetting board to starting positions...");
    
    // Destroy all current pieces
    with (Chess_Piece_Obj) {
        instance_destroy();
    }
    
    // Respawn armies using army managers
    // White pieces
    var _white_positions = [
        // Row 7 (rank 1): back rank
        [{obj: Rook_Obj, col: 0}, {obj: Knight_Obj, col: 1}, {obj: Bishop_Obj, col: 2}, 
         {obj: Queen_Obj, col: 3}, {obj: King_Obj, col: 4}, {obj: Bishop_Obj, col: 5},
         {obj: Knight_Obj, col: 6}, {obj: Rook_Obj, col: 7}],
        // Row 6 (rank 2): pawns
        [{obj: Pawn_Obj, col: 0}, {obj: Pawn_Obj, col: 1}, {obj: Pawn_Obj, col: 2},
         {obj: Pawn_Obj, col: 3}, {obj: Pawn_Obj, col: 4}, {obj: Pawn_Obj, col: 5},
         {obj: Pawn_Obj, col: 6}, {obj: Pawn_Obj, col: 7}]
    ];
    
    // Black pieces
    var _black_positions = [
        // Row 0 (rank 8): back rank
        [{obj: Rook_Obj, col: 0}, {obj: Knight_Obj, col: 1}, {obj: Bishop_Obj, col: 2}, 
         {obj: Queen_Obj, col: 3}, {obj: King_Obj, col: 4}, {obj: Bishop_Obj, col: 5},
         {obj: Knight_Obj, col: 6}, {obj: Rook_Obj, col: 7}],
        // Row 1 (rank 7): pawns
        [{obj: Pawn_Obj, col: 0}, {obj: Pawn_Obj, col: 1}, {obj: Pawn_Obj, col: 2},
         {obj: Pawn_Obj, col: 3}, {obj: Pawn_Obj, col: 4}, {obj: Pawn_Obj, col: 5},
         {obj: Pawn_Obj, col: 6}, {obj: Pawn_Obj, col: 7}]
    ];
    
    // Spawn white pieces
    for (var row_idx = 0; row_idx < 2; row_idx++) {
        var _row = (row_idx == 0) ? 7 : 6;
        var _pieces = _white_positions[row_idx];
        
        for (var i = 0; i < array_length(_pieces); i++) {
            var _def = _pieces[i];
            var _x = Object_Manager.topleft_x + _def.col * Board_Manager.tile_size;
            var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
            
            var _piece = instance_create_depth(_x, _y, -1, _def.obj);
            _piece.piece_type = 0;  // White
            _piece.has_moved = false;
            _piece.reset_spawn_flash = 30;  // Visual effect
        }
    }
    
    // Spawn black pieces
    for (var row_idx = 0; row_idx < 2; row_idx++) {
        var _row = (row_idx == 0) ? 0 : 1;
        var _pieces = _black_positions[row_idx];
        
        for (var i = 0; i < array_length(_pieces); i++) {
            var _def = _pieces[i];
            var _x = Object_Manager.topleft_x + _def.col * Board_Manager.tile_size;
            var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
            
            var _piece = instance_create_depth(_x, _y, -1, _def.obj);
            _piece.piece_type = 1;  // Black
            _piece.has_moved = false;
            _piece.reset_spawn_flash = 30;
            
            // Track the original king
            if (_def.obj == King_Obj) {
                Boss_Manager.original_king = _piece;
            }
        }
    }
    
    show_debug_message("Boss King: Board reset complete");
}
```

### Step 2: Phase 1 — "Look Who's on Top Now!"

**File:** `scripts/boss_cheat_look_whos_on_top/boss_cheat_look_whos_on_top.gml`

```gml
/// @function boss_cheat_look_whos_on_top()
/// @returns {bool} True if cheat execution is complete
/// @description Phase 1: Transform all black pawns into kings
function boss_cheat_look_whos_on_top() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "lwot_state")) {
        _mgr.lwot_state = "init";
        _mgr.lwot_pawns_to_transform = [];
        _mgr.lwot_transform_index = 0;
        _mgr.extra_kings = [];
        show_debug_message("Boss King: Starting 'Look Who's on Top Now!' (Phase 1)");
    }
    
    switch (_mgr.lwot_state) {
        case "init":
            // Find all black pawns
            _mgr.lwot_pawns_to_transform = boss_king_get_black_pawns();
            
            // Find and track the original king
            with (King_Obj) {
                if (piece_type == 1) {
                    _mgr.original_king = id;
                    break;
                }
            }
            
            if (array_length(_mgr.lwot_pawns_to_transform) == 0) {
                show_debug_message("Boss King: No pawns to transform");
                _mgr.lwot_state = undefined;
                return true;
            }
            
            _mgr.lwot_state = "transform";
            _mgr.lwot_transform_index = 0;
            _mgr.lwot_anim_timer = 15;  // Delay between transformations
            
            // Play dramatic sound
            audio_play_sound(Phase_Transform_SFX, 1, false);
            break;
            
        case "transform":
            _mgr.lwot_anim_timer--;
            
            if (_mgr.lwot_anim_timer <= 0) {
                if (_mgr.lwot_transform_index < array_length(_mgr.lwot_pawns_to_transform)) {
                    var _pawn = _mgr.lwot_pawns_to_transform[_mgr.lwot_transform_index];
                    
                    if (instance_exists(_pawn)) {
                        // Start transformation
                        _pawn.transforming = true;
                        _pawn.transform_timer = 20;
                    }
                    
                    _mgr.lwot_transform_index++;
                    _mgr.lwot_anim_timer = 8;  // Quick succession
                } else {
                    _mgr.lwot_state = "wait_transforms";
                }
            }
            break;
            
        case "wait_transforms":
            // Wait for all transformations to complete
            var _any_transforming = false;
            
            for (var i = 0; i < array_length(_mgr.lwot_pawns_to_transform); i++) {
                var _pawn = _mgr.lwot_pawns_to_transform[i];
                if (instance_exists(_pawn) && variable_instance_exists(_pawn, "transforming") && _pawn.transforming) {
                    _pawn.transform_timer--;
                    _any_transforming = true;
                    
                    if (_pawn.transform_timer <= 0) {
                        // Complete transformation
                        boss_king_complete_transformation(_pawn);
                    }
                }
            }
            
            if (!_any_transforming) {
                _mgr.lwot_state = "complete";
            }
            break;
            
        case "complete":
            show_debug_message("Boss King: Phase 1 setup complete - " + 
                string(boss_king_count_extra_kings()) + " extra kings created!");
            
            _mgr.current_phase = 1;
            _mgr.phase_1_active = true;
            _mgr.lwot_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 3: Phase Transition Check

**Add to `objects/Boss_Manager/Step_0.gml`:**

```gml
// === PHASE 1 → PHASE 2 TRANSITION CHECK ===
if (is_boss_level && current_boss_id == "the_king" && 
    variable_instance_exists(id, "phase_1_active") && phase_1_active) {
    
    // Check if all extra kings are defeated
    var _extra_count = boss_king_count_extra_kings();
    
    if (_extra_count == 0) {
        show_debug_message("Boss King: All extra kings defeated! Transitioning to Phase 2...");
        phase_1_active = false;
        phase_transition_pending = true;
        
        // Queue the "Back Off!" transition
        array_push(cheat_queue, "back_off");
        
        // Force cheat phase to execute transition
        if (Game_Manager.turn != 3) {
            Game_Manager.turn = 3;
        }
    }
}
```

### Step 4: Phase 2 — "Back Off!"

**File:** `scripts/boss_cheat_back_off/boss_cheat_back_off.gml`

```gml
/// @function boss_cheat_back_off()
/// @returns {bool} True if cheat execution is complete
/// @description Phase 2 transition: Reset board and begin ability phase
function boss_cheat_back_off() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "bo_state")) {
        _mgr.bo_state = "init";
        show_debug_message("Boss King: Starting 'Back Off!' (Phase 2 transition)");
    }
    
    switch (_mgr.bo_state) {
        case "init":
            // Screen flash for dramatic effect
            global.screen_flash_color = c_white;
            global.screen_flash_timer = 30;
            
            // Play transition sound
            audio_play_sound(Phase_Transition_SFX, 1, false);
            
            _mgr.bo_state = "flash";
            _mgr.bo_timer = 30;
            break;
            
        case "flash":
            _mgr.bo_timer--;
            if (_mgr.bo_timer <= 15) {
                // Reset board at midpoint of flash
                if (_mgr.bo_timer == 15) {
                    boss_king_reset_board();
                }
            }
            
            if (_mgr.bo_timer <= 0) {
                _mgr.bo_state = "settle";
                _mgr.bo_timer = 60;  // Let board settle
            }
            break;
            
        case "settle":
            _mgr.bo_timer--;
            
            // Spawn animation on pieces
            with (Chess_Piece_Obj) {
                if (variable_instance_exists(id, "reset_spawn_flash") && reset_spawn_flash > 0) {
                    reset_spawn_flash--;
                }
            }
            
            if (_mgr.bo_timer <= 0) {
                _mgr.bo_state = "complete";
            }
            break;
            
        case "complete":
            show_debug_message("Boss King: Phase 2 active - abilities every 2 turns!");
            
            _mgr.current_phase = 2;
            _mgr.phase_2_active = true;
            _mgr.phase_2_turn_counter = 0;
            _mgr.extra_kings = [];  // Clear phase 1 tracking
            
            // Re-sync board state for AI
            boss_resync_board_state();
            
            _mgr.bo_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 5: Phase 2 Ability Selection

**Add to `objects/Boss_Manager/Step_0.gml`:**

```gml
// === PHASE 2 ABILITY SCHEDULING ===
if (is_boss_level && current_boss_id == "the_king" && 
    variable_instance_exists(id, "phase_2_active") && phase_2_active) {
    
    // Track turns in phase 2
    if (Game_Manager.turn == 3 && cheat_state == "idle" && 
        array_length(cheat_queue) == 0) {
        
        phase_2_turn_counter++;
        
        // Every 2 turns, trigger random ability
        if (phase_2_turn_counter % 2 == 0) {
            var _ability = boss_king_select_random_ability();
            if (_ability != "") {
                array_push(cheat_queue, _ability);
                show_debug_message("Boss King: Phase 2 ability - " + _ability);
            }
        }
    }
}

/// @function boss_king_select_random_ability()
/// @returns {string} Randomly selected phase 2 ability cheat ID
function boss_king_select_random_ability() {
    var _abilities = ["invulnerable", "pity", "undo", "lose_turn"];
    
    // Weight check - can't use invulnerable if already active
    if (variable_instance_exists(Boss_Manager, "invulnerable_turns") && 
        Boss_Manager.invulnerable_turns > 0) {
        // Remove invulnerable from options
        _abilities = ["pity", "undo", "lose_turn"];
    }
    
    // Can't undo if no move history
    var _last_move = boss_king_get_last_move();
    if (_last_move == undefined) {
        // Remove undo from options
        var _filtered = [];
        for (var i = 0; i < array_length(_abilities); i++) {
            if (_abilities[i] != "undo") {
                array_push(_filtered, _abilities[i]);
            }
        }
        _abilities = _filtered;
    }
    
    if (array_length(_abilities) == 0) {
        return "lose_turn";  // Fallback
    }
    
    return _abilities[irandom(array_length(_abilities) - 1)];
}
```

### Step 6: Invulnerability Ability

**File:** `scripts/boss_cheat_invulnerable/boss_cheat_invulnerable.gml`

```gml
/// @function boss_cheat_invulnerable()
/// @returns {bool} True if cheat execution is complete
/// @description "I'm Invulnerable Now!" - King can't be captured for 3 turns
function boss_cheat_invulnerable() {
    var _mgr = Boss_Manager;
    
    if (!variable_instance_exists(_mgr, "inv_state")) {
        _mgr.inv_state = "init";
        show_debug_message("Boss King: 'I'm Invulnerable Now!'");
    }
    
    switch (_mgr.inv_state) {
        case "init":
            // Find the original king
            var _king = boss_king_get_original_king();
            if (!instance_exists(_king)) {
                _mgr.inv_state = undefined;
                return true;
            }
            
            // Set invulnerability
            _king.is_invulnerable = true;
            _king.levitate_height = 0;
            _king.levitate_target = 20;  // Pixels to levitate
            
            _mgr.invulnerable_turns = 3;
            _mgr.invulnerable_king = _king;
            
            // Play sound
            audio_play_sound(Invulnerable_SFX, 1, false);
            
            _mgr.inv_state = "animate";
            _mgr.inv_timer = 30;
            break;
            
        case "animate":
            // Levitate animation
            var _king = _mgr.invulnerable_king;
            if (instance_exists(_king)) {
                _king.levitate_height = lerp(_king.levitate_height, _king.levitate_target, 0.1);
            }
            
            _mgr.inv_timer--;
            if (_mgr.inv_timer <= 0) {
                _mgr.inv_state = "complete";
            }
            break;
            
        case "complete":
            show_debug_message("Boss King: Invulnerable for " + 
                string(_mgr.invulnerable_turns) + " turns!");
            _mgr.inv_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 7: Pity Ability

**File:** `scripts/boss_cheat_pity/boss_cheat_pity.gml`

```gml
/// @function boss_cheat_pity()
/// @returns {bool} True if cheat execution is complete
/// @description "Oh, I'll Pity You..." - Give one pawn to player
function boss_cheat_pity() {
    var _mgr = Boss_Manager;
    
    if (!variable_instance_exists(_mgr, "pity_state")) {
        _mgr.pity_state = "init";
        show_debug_message("Boss King: 'Oh, I'll Pity You...'");
    }
    
    switch (_mgr.pity_state) {
        case "init":
            // Find a black pawn to give away
            var _pawns = boss_king_get_black_pawns();
            
            if (array_length(_pawns) == 0) {
                show_debug_message("Boss King: No pawns to give away");
                _mgr.pity_state = undefined;
                return true;
            }
            
            // Select random pawn
            _mgr.pity_pawn = _pawns[irandom(array_length(_pawns) - 1)];
            _mgr.pity_state = "flick";
            _mgr.pity_timer = 40;
            break;
            
        case "flick":
            var _pawn = _mgr.pity_pawn;
            if (!instance_exists(_pawn)) {
                _mgr.pity_state = "complete";
                break;
            }
            
            // Animate pawn flicking
            _mgr.pity_timer--;
            
            var _progress = 1 - (_mgr.pity_timer / 40);
            
            // Arc animation
            _pawn.flick_offset_y = sin(_progress * pi) * -30;
            _pawn.flick_rotation = _progress * 360;
            
            if (_mgr.pity_timer <= 0) {
                // Convert pawn to white
                _pawn.piece_type = 0;  // Now player's piece
                _pawn.flick_offset_y = 0;
                _pawn.flick_rotation = 0;
                _pawn.has_moved = true;
                
                // Play sound
                audio_play_sound(Pawn_Convert_SFX, 1, false);
                
                show_debug_message("Boss King: Gave pawn to player!");
                _mgr.pity_state = "complete";
            }
            break;
            
        case "complete":
            _mgr.pity_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 8: Undo Ability

**File:** `scripts/boss_cheat_undo/boss_cheat_undo.gml`

```gml
/// @function boss_cheat_undo()
/// @returns {bool} True if cheat execution is complete
/// @description "That Move Doesn't Count!" - Undo player's last move
function boss_cheat_undo() {
    var _mgr = Boss_Manager;
    
    if (!variable_instance_exists(_mgr, "undo_state")) {
        _mgr.undo_state = "init";
        show_debug_message("Boss King: 'That Move Doesn't Count!'");
    }
    
    switch (_mgr.undo_state) {
        case "init":
            // Get last recorded move
            var _last = boss_king_get_last_move();
            
            if (_last == undefined) {
                show_debug_message("Boss King: No move to undo");
                _mgr.undo_state = undefined;
                return true;
            }
            
            _mgr.undo_move_data = _last;
            _mgr.undo_state = "reverse";
            _mgr.undo_timer = 30;
            
            // Rewind sound
            audio_play_sound(Undo_SFX, 1, false);
            break;
            
        case "reverse":
            var _data = _mgr.undo_move_data;
            
            // Visual rewind effect
            _mgr.undo_timer--;
            global.screen_rewind_effect = _mgr.undo_timer / 30;
            
            if (_mgr.undo_timer == 15) {
                // Perform the undo at midpoint
                
                // Find the piece that moved
                var _piece = _data.piece;
                if (instance_exists(_piece)) {
                    // Move piece back to original position
                    var _from_x = Object_Manager.topleft_x + _data.from_col * Board_Manager.tile_size;
                    var _from_y = Object_Manager.topleft_y + _data.from_row * Board_Manager.tile_size;
                    
                    _piece.x = _from_x;
                    _piece.y = _from_y;
                    _piece.has_moved = _data.had_moved_before;
                }
                
                // Restore captured piece if any
                if (_data.captured_piece_type != undefined) {
                    var _cap_x = Object_Manager.topleft_x + _data.to_col * Board_Manager.tile_size;
                    var _cap_y = Object_Manager.topleft_y + _data.to_row * Board_Manager.tile_size;
                    
                    // Recreate the captured piece
                    var _obj = boss_king_get_piece_object(_data.captured_piece_id);
                    var _restored = instance_create_depth(_cap_x, _cap_y, -1, _obj);
                    _restored.piece_type = _data.captured_piece_type;
                    _restored.has_moved = _data.captured_had_moved;
                    _restored.undo_restored = true;
                    _restored.restore_flash_timer = 20;
                    
                    show_debug_message("Boss King: Restored captured " + _data.captured_piece_id);
                }
                
                // Remove this move from history
                array_pop(Boss_Manager.move_history);
            }
            
            if (_mgr.undo_timer <= 0) {
                global.screen_rewind_effect = 0;
                _mgr.undo_state = "complete";
            }
            break;
            
        case "complete":
            // Re-sync board
            boss_resync_board_state();
            
            show_debug_message("Boss King: Move undone!");
            _mgr.undo_state = undefined;
            return true;
    }
    
    return false;
}

/// @function boss_king_get_piece_object(_piece_id)
/// @param {string} _piece_id The piece ID
/// @returns {object} The corresponding object type
function boss_king_get_piece_object(_piece_id) {
    switch (_piece_id) {
        case "pawn": return Pawn_Obj;
        case "knight": return Knight_Obj;
        case "bishop": return Bishop_Obj;
        case "rook": return Rook_Obj;
        case "queen": return Queen_Obj;
        case "king": return King_Obj;
        default: return Pawn_Obj;
    }
}
```

### Step 9: Lose Turn Ability

**File:** `scripts/boss_cheat_lose_turn/boss_cheat_lose_turn.gml`

```gml
/// @function boss_cheat_lose_turn()
/// @returns {bool} True if cheat execution is complete
/// @description "I... I Don't Know..." - Boss skips turn
function boss_cheat_lose_turn() {
    var _mgr = Boss_Manager;
    
    if (!variable_instance_exists(_mgr, "lt_state")) {
        _mgr.lt_state = "init";
        show_debug_message("Boss King: 'I... I Don't Know...'");
    }
    
    switch (_mgr.lt_state) {
        case "init":
            var _king = boss_king_get_original_king();
            
            if (instance_exists(_king)) {
                _king.confused = true;
                _king.confused_timer = 60;
            }
            
            // Confusion sound
            audio_play_sound(Confused_SFX, 1, false);
            
            _mgr.lt_state = "animate";
            _mgr.lt_timer = 60;
            break;
            
        case "animate":
            _mgr.lt_timer--;
            
            var _king = boss_king_get_original_king();
            if (instance_exists(_king)) {
                // Wobble animation
                _king.confused_wobble = sin(current_time / 80) * 5;
            }
            
            if (_mgr.lt_timer <= 0) {
                if (instance_exists(_king)) {
                    _king.confused = false;
                    _king.confused_wobble = 0;
                }
                _mgr.lt_state = "complete";
            }
            break;
            
        case "complete":
            // Flag that boss loses next turn
            _mgr.boss_skip_next_turn = true;
            
            show_debug_message("Boss King: Lost turn due to confusion!");
            _mgr.lt_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 10: Move History Recording

**Add to `objects/Chess_Piece_Obj/Step_0.gml`:**

```gml
// === RECORD MOVE FOR UNDO MECHANIC ===
// After a player piece completes a move
if (piece_type == 0 && !is_moving && 
    variable_instance_exists(id, "just_moved") && just_moved) {
    
    just_moved = false;
    
    // Record for The King's undo ability
    if (instance_exists(Boss_Manager) && 
        Boss_Manager.current_boss_id == "the_king") {
        
        var _move_data = {
            piece: id,
            piece_id: piece_id,
            from_col: move_from_col,
            from_row: move_from_row,
            to_col: round((x - Object_Manager.topleft_x) / Board_Manager.tile_size),
            to_row: round((y - Object_Manager.topleft_y) / Board_Manager.tile_size),
            had_moved_before: move_had_moved_before,
            captured_piece_id: (captured_instance != noone) ? captured_instance.piece_id : undefined,
            captured_piece_type: (captured_instance != noone) ? captured_instance.piece_type : undefined,
            captured_had_moved: (captured_instance != noone) ? captured_instance.has_moved : false
        };
        
        boss_king_record_move(_move_data);
    }
}
```

### Step 11: King Visual Effects

**Add to `objects/King_Obj/Draw_0.gml`:**

```gml
// === EXTRA KING INDICATOR ===
if (variable_instance_exists(id, "is_extra_king") && is_extra_king) {
    // Different crown color for extra kings
    draw_set_color(c_silver);
    draw_set_alpha(0.4);
    draw_sprite(sprite_index, image_index, x, y);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// === INVULNERABILITY LEVITATE ===
if (variable_instance_exists(id, "is_invulnerable") && is_invulnerable) {
    // Levitate offset
    var _float = (variable_instance_exists(id, "levitate_height")) ? levitate_height : 0;
    
    // Golden glow
    var _pulse = (sin(current_time / 100) + 1) / 2;
    draw_set_color(c_yellow);
    draw_set_alpha(0.3 + _pulse * 0.3);
    draw_sprite(sprite_index, image_index, x, y - _float);
    draw_set_alpha(1);
    draw_set_color(c_white);
    
    // Shadow below
    draw_set_alpha(0.3);
    draw_ellipse(x - 8, y + 4, x + 8, y + 8, false);
    draw_set_alpha(1);
    
    // Apply levitate to actual draw position
    y -= _float;
}

// === CONFUSION WOBBLE ===
if (variable_instance_exists(id, "confused") && confused) {
    // Draw question marks
    var _wobble = (variable_instance_exists(id, "confused_wobble")) ? confused_wobble : 0;
    
    draw_set_color(c_white);
    draw_set_alpha(0.8);
    
    for (var i = 0; i < 3; i++) {
        var _ox = cos(current_time / 200 + i * 2.1) * 12;
        var _oy = -15 - sin(current_time / 300 + i) * 5;
        draw_text(x + _ox, y + _oy, "?");
    }
    
    draw_set_alpha(1);
}
```

---

## Known Gotchas

### Extra Kings vs Original King
- Extra kings are marked with `is_extra_king = true`
- Original king is tracked in `Boss_Manager.original_king`
- Checkmate detection must still work on original king
- Capturing extra kings = good; capturing original king = game over (for boss)

### Invulnerability and Check
When the king is invulnerable:
- Cannot be captured
- Cannot be put in "check" (treated as if not there for check detection)
- AI must handle this special case

### Move History for Undo
Move history must record:
- Piece that moved
- From/to positions
- Whether piece had moved before
- Captured piece details (for restoration)

### Board Reset Timing
`boss_king_reset_board()` destroys ALL pieces and recreates them. This MUST:
1. Happen during a "flash" so player doesn't see disappearing pieces
2. Be followed by `boss_resync_board_state()`
3. Properly track the new original king instance

### Sound Assets Required
- `Phase_Transform_SFX` — Pawn to king transformation
- `Phase_Transition_SFX` — Phase 2 dramatic transition
- `Invulnerable_SFX` — King levitation
- `Pawn_Convert_SFX` — Pawn changing sides
- `Undo_SFX` — Time rewind effect
- `Confused_SFX` — Boss confusion

---

## Success Criteria

### Phase 1
- [ ] All black pawns transform to kings at match start
- [ ] Transformation animation plays
- [ ] Original king is tracked separately
- [ ] Phase 2 triggers when all extra kings defeated
- [ ] Game still ends if original king is checkmated

### Phase 2
- [ ] Board resets to starting positions
- [ ] All pawns (both sides) revived
- [ ] Random ability triggers every 2 turns
- [ ] Invulnerability makes king untargetable
- [ ] Pity gives a pawn to player
- [ ] Undo reverses player's last move including captures
- [ ] Lose Turn causes boss to skip move

### General
- [ ] AI plays at highest difficulty
- [ ] No crashes during phase transition
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Load The King boss room
2. Verify 8 pawns transform to kings (Phase 1)
3. Capture all extra kings
4. Verify Phase 2 transition (board reset)
5. Play 4 turns in Phase 2
6. Verify 2 abilities triggered
7. Test each ability works correctly

### Debug Keys

Add to `Boss_Manager/KeyPress_80.gml` (P key):
```gml
// DEBUG: Force phase transition
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "the_king") {
    // Kill all extra kings
    with (King_Obj) {
        if (variable_instance_exists(id, "is_extra_king") && is_extra_king) {
            instance_destroy();
        }
    }
    extra_kings = [];
    show_debug_message("DEBUG: Killed all extra kings");
}
```

Add to `Boss_Manager/KeyPress_49-52.gml` (1-4 keys):
```gml
// DEBUG: Force specific Phase 2 ability
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "the_king" && phase_2_active) {
    var _abilities = ["invulnerable", "pity", "undo", "lose_turn"];
    var _key = keyboard_lastkey - 49;  // 1=0, 2=1, 3=2, 4=3
    if (_key >= 0 && _key < 4) {
        array_push(cheat_queue, _abilities[_key]);
        Game_Manager.turn = 3;
        show_debug_message("DEBUG: Forced ability - " + _abilities[_key]);
    }
}
```

---

## Next Steps

After this PRP is implemented:
1. Complete integration testing for all bosses
2. Balance testing for boss difficulty
3. Polish visual effects and sounds
4. Consider difficulty options per boss
