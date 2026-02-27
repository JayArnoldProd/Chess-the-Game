# PRP-019: Boss 2 — Queen (Pirate Seas)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** MEDIUM  
**Depends On:** PRP-017 (Boss Framework)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

The Queen is the second boss encounter (Pirate Seas). She uses low AI that makes a "bad move" every 5 turns, and has two cheat abilities:

1. **"Cut the Slack!"** — Sacrifices 3 pawns to create 1 new queen
2. **"Enchant!"** — Shields a piece; when captured, it explodes in 3×3 radius

This PRP implements both cheats with full animations, pawn sacrifice logic, and explosion mechanics.

---

## Boss Specification (from Design Doc)

### AI Settings
- **Difficulty:** Low (level 2)
- **Bad Move Frequency:** Every 5 turns
- **Bad Move Offset:** Pick 2nd-4th best move

### Cheat 1 — "Cut the Slack!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | Turn 1, then every 3 turns |
| **Pawn Sacrifice** | Removes 3 pawns from boss's side |
| **Queen Spawn** | Creates 1 new queen at middle pawn's position |
| **Selection Order** | Left pawns first → right pawns → middle pawns |
| **Repeat Condition** | Only if enough pawns remain (≥3) |
| **Visual** | Pawns dissolve/sacrifice animation, queen rises from middle position |

### Cheat 2 — "Enchant!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | Turn 2: enchant first "Cut the Slack" queen; every 3 turns: random non-pawn |
| **Visual** | Purple glowing shield around enchanted piece |
| **Explosion** | When enchanted piece is captured → 3×3 explosion |
| **Explosion Damage** | Kills BOTH black AND white pieces in radius |
| **King Immunity** | Kings are IMMUNE to explosion damage |
| **Target Selection** | Only enchants special pieces (not pawns) |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       QUEEN BOSS CHEAT ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    "CUT THE SLACK!" FLOW                               │  │
│  │                                                                        │  │
│  │   Check Pawn Count (≥3?) ──▶ Select 3 Pawns ──▶ Sacrifice Animation   │  │
│  │                                    │              │                    │  │
│  │                                    │              ▼                    │  │
│  │                                    │    ┌─────────────────┐           │  │
│  │                                    └───▶│ Spawn Queen at  │           │  │
│  │                                         │ Middle Position │           │  │
│  │                                         └────────┬────────┘           │  │
│  │                                                  │                    │  │
│  │                                                  ▼                    │  │
│  │                                    Track for Enchant (Turn 2)         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                       "ENCHANT!" FLOW                                  │  │
│  │                                                                        │  │
│  │   Select Target ──▶ Apply Shield ──▶ Track Enchanted Pieces           │  │
│  │        │                │                    │                        │  │
│  │        │                │                    ▼                        │  │
│  │        │                │           On Capture Detection:             │  │
│  │        │                │           ┌──────────────────────┐         │  │
│  │        │                │           │ Calculate 3×3 area   │         │  │
│  │        │                │           │ Damage all non-kings │         │  │
│  │        │                │           │ Play explosion FX    │         │  │
│  │        │                │           └──────────────────────┘         │  │
│  │        │                │                                             │  │
│  │   Turn 2: First        Every 3 turns:                                 │  │
│  │   Cut queen            Random non-pawn                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    EXPLOSION DETECTION (capture hooks)                 │  │
│  │                                                                        │  │
│  │   Chess_Piece_Obj capture ──▶ Is piece enchanted? ──▶ Trigger explosion│  │
│  │                                       │                                │  │
│  │                                       ▼                                │  │
│  │                              Remove from enchanted_pieces[]            │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: context/design-docs/enemy-boss-system-spec.md
  why: Boss 2 specification

- path: context/prps/PRP-017-boss-framework.md
  why: Boss_Manager, cheat execution framework

- path: objects/Pawn_Obj/Create_0.gml
  why: Pawn object structure

- path: objects/Queen_Obj/Create_0.gml
  why: Queen object structure (for spawning)
```

### Files to Create

```yaml
- path: scripts/boss_cheat_cut_the_slack/boss_cheat_cut_the_slack.gml
  purpose: "Cut the Slack!" cheat implementation

- path: scripts/boss_cheat_enchant/boss_cheat_enchant.gml
  purpose: "Enchant!" cheat implementation

- path: scripts/boss_queen_utils/boss_queen_utils.gml
  purpose: Utility functions (pawn selection, explosion, etc.)

- path: scripts/boss_trigger_explosion/boss_trigger_explosion.gml
  purpose: 3×3 explosion effect and damage
```

### Files to Modify

```yaml
- path: objects/Boss_Manager/Create_0.gml
  changes: Add Queen-specific state variables

- path: objects/Chess_Piece_Obj/Step_0.gml
  changes: Add enchantment visual overlay, capture explosion hook

- path: objects/Chess_Piece_Obj/Destroy_0.gml
  changes: Trigger explosion if enchanted
```

---

## Implementation Blueprint

### Step 1: Queen Boss Utility Functions

**File:** `scripts/boss_queen_utils/boss_queen_utils.gml`

```gml
/// @function boss_queen_get_all_pawns(_color)
/// @param {real} _color 0=white, 1=black
/// @returns {array} Array of pawn instances sorted by column (left to right)
function boss_queen_get_all_pawns(_color) {
    var _pawns = [];
    
    with (Pawn_Obj) {
        if (piece_type == _color) {
            array_push(_pawns, id);
        }
    }
    
    // Sort by column (left to right)
    var n = array_length(_pawns);
    for (var i = 0; i < n - 1; i++) {
        for (var j = 0; j < n - i - 1; j++) {
            var _col_a = round((_pawns[j].x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var _col_b = round((_pawns[j+1].x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            if (_col_a > _col_b) {
                var _temp = _pawns[j];
                _pawns[j] = _pawns[j+1];
                _pawns[j+1] = _temp;
            }
        }
    }
    
    return _pawns;
}

/// @function boss_queen_select_sacrifice_pawns(_pawns)
/// @param {array} _pawns Array of pawn instances (sorted by column)
/// @returns {array} Array of 3 pawns to sacrifice, or empty if not enough
/// @description Selects 3 pawns: left first, then right, then middle
function boss_queen_select_sacrifice_pawns(_pawns) {
    var n = array_length(_pawns);
    if (n < 3) return [];
    
    var _selected = [];
    var _used = array_create(n, false);
    
    // Selection order: leftmost, rightmost, then middle
    // Left pawn
    _selected[0] = _pawns[0];
    _used[0] = true;
    
    // Right pawn
    _selected[1] = _pawns[n - 1];
    _used[n - 1] = true;
    
    // Middle pawn (closest to center column 3.5)
    var _best_middle = -1;
    var _best_dist = 999;
    for (var i = 0; i < n; i++) {
        if (_used[i]) continue;
        var _col = round((_pawns[i].x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var _dist = abs(_col - 3.5);
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best_middle = i;
        }
    }
    
    if (_best_middle >= 0) {
        _selected[2] = _pawns[_best_middle];
    } else {
        // Fallback: just take any remaining pawn
        for (var i = 0; i < n; i++) {
            if (!_used[i]) {
                _selected[2] = _pawns[i];
                break;
            }
        }
    }
    
    return _selected;
}

/// @function boss_queen_get_middle_position(_pawns)
/// @param {array} _pawns Array of 3 sacrifice pawns
/// @returns {struct} {col, row} position of the middle pawn
function boss_queen_get_middle_position(_pawns) {
    if (array_length(_pawns) < 3) return { col: 3, row: 1 };  // Default
    
    // The middle pawn is the third selected (index 2)
    var _middle = _pawns[2];
    var _col = round((_middle.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _row = round((_middle.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    return { col: _col, row: _row };
}

/// @function boss_queen_spawn_queen(_col, _row)
/// @param {real} _col Column position
/// @param {real} _row Row position
/// @returns {instance} The new queen instance
function boss_queen_spawn_queen(_col, _row) {
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    var _queen = instance_create_depth(_x, _y, -1, Queen_Obj);
    _queen.piece_type = 1;  // Black
    _queen.has_moved = true;
    _queen.spawned_by_cheat = true;
    _queen.spawn_rise_timer = 30;  // Rising animation
    
    show_debug_message("Boss Queen: Spawned new queen at (" + 
        string(_col) + "," + string(_row) + ")");
    
    return _queen;
}

/// @function boss_queen_get_non_pawn_pieces(_color)
/// @param {real} _color 0=white, 1=black
/// @returns {array} Array of non-pawn piece instances
function boss_queen_get_non_pawn_pieces(_color) {
    var _pieces = [];
    
    with (Chess_Piece_Obj) {
        if (piece_type == _color && piece_id != "pawn") {
            array_push(_pieces, id);
        }
    }
    
    return _pieces;
}

/// @function boss_queen_is_piece_enchanted(_piece)
/// @param {instance} _piece The piece to check
/// @returns {bool} True if piece is in enchanted_pieces array
function boss_queen_is_piece_enchanted(_piece) {
    if (!instance_exists(Boss_Manager)) return false;
    if (!variable_instance_exists(Boss_Manager, "enchanted_pieces")) return false;
    
    var _enchanted = Boss_Manager.enchanted_pieces;
    for (var i = 0; i < array_length(_enchanted); i++) {
        if (_enchanted[i].piece == _piece) {
            return true;
        }
    }
    
    return false;
}

/// @function boss_queen_add_enchantment(_piece)
/// @param {instance} _piece The piece to enchant
function boss_queen_add_enchantment(_piece) {
    if (!instance_exists(_piece)) return;
    if (!instance_exists(Boss_Manager)) return;
    
    // Initialize enchanted_pieces if needed
    if (!variable_instance_exists(Boss_Manager, "enchanted_pieces")) {
        Boss_Manager.enchanted_pieces = [];
    }
    
    // Don't double-enchant
    if (boss_queen_is_piece_enchanted(_piece)) return;
    
    // Add to tracking
    array_push(Boss_Manager.enchanted_pieces, {
        piece: _piece,
        enchant_time: current_time
    });
    
    // Set visual flag on piece
    _piece.is_enchanted = true;
    _piece.enchant_pulse_phase = 0;
    
    show_debug_message("Boss Queen: Enchanted " + _piece.piece_id);
}

/// @function boss_queen_remove_enchantment(_piece)
/// @param {instance} _piece The piece to remove enchantment from
function boss_queen_remove_enchantment(_piece) {
    if (!instance_exists(Boss_Manager)) return;
    if (!variable_instance_exists(Boss_Manager, "enchanted_pieces")) return;
    
    var _enchanted = Boss_Manager.enchanted_pieces;
    for (var i = array_length(_enchanted) - 1; i >= 0; i--) {
        if (_enchanted[i].piece == _piece) {
            array_delete(_enchanted, i, 1);
            if (instance_exists(_piece)) {
                _piece.is_enchanted = false;
            }
            break;
        }
    }
}
```

### Step 2: "Cut the Slack!" Cheat Implementation

**File:** `scripts/boss_cheat_cut_the_slack/boss_cheat_cut_the_slack.gml`

```gml
/// @function boss_cheat_cut_the_slack()
/// @returns {bool} True if cheat execution is complete
/// @description "Cut the Slack!" - Sacrifice 3 pawns to create 1 queen
function boss_cheat_cut_the_slack() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "cts_state")) {
        _mgr.cts_state = "init";
        _mgr.cts_sacrifice_pawns = [];
        _mgr.cts_sacrifice_index = 0;
        _mgr.cts_new_queen = noone;
        _mgr.cts_spawn_position = undefined;
        show_debug_message("Boss Queen: Starting 'Cut the Slack!' cheat");
    }
    
    switch (_mgr.cts_state) {
        case "init":
            // Get all black pawns
            var _pawns = boss_queen_get_all_pawns(1);
            
            // Check if we have enough pawns
            if (array_length(_pawns) < 3) {
                show_debug_message("Boss Queen: Not enough pawns for Cut the Slack (" + 
                    string(array_length(_pawns)) + " available)");
                _mgr.cts_state = undefined;
                return true;  // Can't execute, skip
            }
            
            // Select sacrifice pawns
            _mgr.cts_sacrifice_pawns = boss_queen_select_sacrifice_pawns(_pawns);
            _mgr.cts_spawn_position = boss_queen_get_middle_position(_mgr.cts_sacrifice_pawns);
            _mgr.cts_sacrifice_index = 0;
            _mgr.cts_state = "sacrifice_animate";
            _mgr.cts_anim_timer = 20;  // Time between sacrifices
            break;
            
        case "sacrifice_animate":
            // Animate each pawn sacrifice one at a time
            _mgr.cts_anim_timer--;
            
            if (_mgr.cts_anim_timer <= 0) {
                if (_mgr.cts_sacrifice_index < array_length(_mgr.cts_sacrifice_pawns)) {
                    var _pawn = _mgr.cts_sacrifice_pawns[_mgr.cts_sacrifice_index];
                    
                    if (instance_exists(_pawn)) {
                        // Start sacrifice animation
                        _pawn.sacrifice_timer = 30;
                        _pawn.sacrificing = true;
                        
                        show_debug_message("Boss Queen: Sacrificing pawn " + 
                            string(_mgr.cts_sacrifice_index + 1) + "/3");
                    }
                    
                    _mgr.cts_sacrifice_index++;
                    _mgr.cts_anim_timer = 20;
                } else {
                    _mgr.cts_state = "wait_sacrifice_complete";
                }
            }
            break;
            
        case "wait_sacrifice_complete":
            // Wait for all sacrifice animations to complete
            var _any_sacrificing = false;
            for (var i = 0; i < array_length(_mgr.cts_sacrifice_pawns); i++) {
                var _pawn = _mgr.cts_sacrifice_pawns[i];
                if (instance_exists(_pawn) && variable_instance_exists(_pawn, "sacrificing") && _pawn.sacrificing) {
                    _any_sacrificing = true;
                    
                    // Update sacrifice animation
                    _pawn.sacrifice_timer--;
                    if (_pawn.sacrifice_timer <= 0) {
                        // Destroy the pawn
                        instance_destroy(_pawn);
                    }
                }
            }
            
            if (!_any_sacrificing) {
                _mgr.cts_state = "spawn_queen";
            }
            break;
            
        case "spawn_queen":
            // Spawn new queen at middle pawn's position
            var _pos = _mgr.cts_spawn_position;
            _mgr.cts_new_queen = boss_queen_spawn_queen(_pos.col, _pos.row);
            
            // Track this queen for enchantment on turn 2
            if (!variable_instance_exists(_mgr, "cut_the_slack_queens")) {
                _mgr.cut_the_slack_queens = [];
            }
            array_push(_mgr.cut_the_slack_queens, _mgr.cts_new_queen);
            _mgr.cut_the_slack_count++;
            
            // Play spawn sound
            audio_play_sound(Queen_Spawn_SFX, 1, false);
            
            _mgr.cts_state = "spawn_animate";
            _mgr.cts_spawn_timer = 30;
            break;
            
        case "spawn_animate":
            // Wait for queen spawn animation
            _mgr.cts_spawn_timer--;
            
            if (instance_exists(_mgr.cts_new_queen)) {
                _mgr.cts_new_queen.spawn_rise_timer--;
            }
            
            if (_mgr.cts_spawn_timer <= 0) {
                _mgr.cts_state = "complete";
            }
            break;
            
        case "complete":
            // Reset state
            _mgr.cts_state = undefined;
            show_debug_message("Boss Queen: 'Cut the Slack!' complete - new queen spawned!");
            return true;
    }
    
    return false;
}
```

### Step 3: "Enchant!" Cheat Implementation

**File:** `scripts/boss_cheat_enchant/boss_cheat_enchant.gml`

```gml
/// @function boss_cheat_enchant()
/// @returns {bool} True if cheat execution is complete
/// @description "Enchant!" - Shield a piece; causes 3×3 explosion when captured
function boss_cheat_enchant() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "enchant_state")) {
        _mgr.enchant_state = "init";
        _mgr.enchant_target = noone;
        show_debug_message("Boss Queen: Starting 'Enchant!' cheat");
    }
    
    switch (_mgr.enchant_state) {
        case "init":
            // Determine target based on turn
            var _target = noone;
            
            // Turn 2: Enchant first Cut the Slack queen
            if (_mgr.boss_turn_count == 2) {
                if (variable_instance_exists(_mgr, "cut_the_slack_queens") && 
                    array_length(_mgr.cut_the_slack_queens) > 0) {
                    // Find first CTS queen that exists and isn't already enchanted
                    for (var i = 0; i < array_length(_mgr.cut_the_slack_queens); i++) {
                        var _queen = _mgr.cut_the_slack_queens[i];
                        if (instance_exists(_queen) && !boss_queen_is_piece_enchanted(_queen)) {
                            _target = _queen;
                            break;
                        }
                    }
                }
            }
            
            // If no CTS queen available, pick random non-pawn
            if (_target == noone) {
                var _candidates = boss_queen_get_non_pawn_pieces(1);  // Black pieces
                
                // Filter out already enchanted pieces
                var _valid = [];
                for (var i = 0; i < array_length(_candidates); i++) {
                    if (!boss_queen_is_piece_enchanted(_candidates[i])) {
                        array_push(_valid, _candidates[i]);
                    }
                }
                
                if (array_length(_valid) > 0) {
                    _target = _valid[irandom(array_length(_valid) - 1)];
                }
            }
            
            if (_target == noone) {
                show_debug_message("Boss Queen: No valid target for Enchant!");
                _mgr.enchant_state = undefined;
                return true;  // Skip
            }
            
            _mgr.enchant_target = _target;
            _mgr.enchant_state = "apply_shield";
            _mgr.enchant_anim_timer = 45;  // Shield application animation
            break;
            
        case "apply_shield":
            // Apply enchantment to target
            boss_queen_add_enchantment(_mgr.enchant_target);
            
            // Play enchant sound
            audio_play_sound(Enchant_SFX, 1, false);
            
            _mgr.enchant_state = "animate";
            break;
            
        case "animate":
            // Wait for shield visual to settle
            _mgr.enchant_anim_timer--;
            
            if (_mgr.enchant_anim_timer <= 0) {
                _mgr.enchant_state = "complete";
            }
            break;
            
        case "complete":
            show_debug_message("Boss Queen: 'Enchant!' complete - " + 
                _mgr.enchant_target.piece_id + " is now enchanted!");
            _mgr.enchant_state = undefined;
            return true;
    }
    
    return false;
}
```

### Step 4: Explosion System

**File:** `scripts/boss_trigger_explosion/boss_trigger_explosion.gml`

```gml
/// @function boss_trigger_explosion(_col, _row)
/// @param {real} _col Center column of explosion
/// @param {real} _row Center row of explosion
/// @description Triggers a 3×3 explosion centered at the given position
function boss_trigger_explosion(_col, _row) {
    show_debug_message("Boss Queen: EXPLOSION at (" + string(_col) + "," + string(_row) + ")!");
    
    // Play explosion sound
    audio_play_sound(Explosion_SFX, 1, false);
    
    // Create visual explosion effect
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // Create explosion effect object (if exists)
    if (object_exists(Explosion_Effect_Obj)) {
        instance_create_depth(_x, _y, -5, Explosion_Effect_Obj);
    } else {
        // Fallback: create particles or simple visual
        global.explosion_flash_x = _x;
        global.explosion_flash_y = _y;
        global.explosion_flash_timer = 20;
    }
    
    // Damage all pieces in 3×3 area
    var _killed_white = 0;
    var _killed_black = 0;
    
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            var _tc = _col + dx;
            var _tr = _row + dy;
            
            // Skip out of bounds
            if (_tc < 0 || _tc >= 8 || _tr < 0 || _tr >= 8) continue;
            
            // Check for piece at this position
            var _target_x = Object_Manager.topleft_x + _tc * Board_Manager.tile_size;
            var _target_y = Object_Manager.topleft_y + _tr * Board_Manager.tile_size;
            var _piece = instance_position(_target_x, _target_y, Chess_Piece_Obj);
            
            if (_piece != noone) {
                // Kings are IMMUNE to explosion damage
                if (_piece.piece_id == "king") {
                    show_debug_message("Boss Queen: King immune to explosion");
                    continue;
                }
                
                // Remove any enchantment before destroying
                boss_queen_remove_enchantment(_piece);
                
                // Track for debug
                if (_piece.piece_type == 0) {
                    _killed_white++;
                } else {
                    _killed_black++;
                }
                
                // Mark for explosion death (special animation)
                _piece.explosion_death = true;
                _piece.explosion_timer = 15;
            }
        }
    }
    
    show_debug_message("Boss Queen: Explosion killed " + 
        string(_killed_white) + " white, " + 
        string(_killed_black) + " black pieces");
    
    // Schedule piece destruction after explosion animation
    alarm_set(0, 20);  // Will be handled by Boss_Manager alarm
}

/// @function boss_check_enchanted_capture(_piece, _col, _row)
/// @param {instance} _piece The piece being captured
/// @param {real} _col Column where capture occurred
/// @param {real} _row Row where capture occurred
/// @returns {bool} True if piece was enchanted (explosion triggered)
function boss_check_enchanted_capture(_piece, _col, _row) {
    if (!instance_exists(_piece)) return false;
    
    // Check if piece was enchanted
    if (!variable_instance_exists(_piece, "is_enchanted") || !_piece.is_enchanted) {
        return false;
    }
    
    // Trigger explosion
    boss_trigger_explosion(_col, _row);
    
    // Remove from enchanted tracking
    boss_queen_remove_enchantment(_piece);
    
    return true;
}
```

### Step 5: Chess Piece Visual Modifications

**Add to `objects/Chess_Piece_Obj/Create_0.gml`:**

```gml
// === ENCHANTMENT STATE ===
is_enchanted = false;
enchant_pulse_phase = 0;

// === EXPLOSION DEATH ===
explosion_death = false;
explosion_timer = 0;

// === SACRIFICE ANIMATION (for pawns) ===
sacrificing = false;
sacrifice_timer = 0;

// === SPAWN ANIMATION (for CTS queens) ===
spawned_by_cheat = false;
spawn_rise_timer = 0;
```

**Add to `objects/Chess_Piece_Obj/Draw_0.gml`:**

```gml
/// Chess_Piece_Obj Draw Event additions for Queen boss effects

// === ENCHANTMENT VISUAL (Purple Shield) ===
if (variable_instance_exists(id, "is_enchanted") && is_enchanted) {
    enchant_pulse_phase += 0.1;
    var _pulse = (sin(enchant_pulse_phase) + 1) / 2;
    var _alpha = 0.3 + _pulse * 0.3;
    var _scale = 1.0 + _pulse * 0.15;
    
    // Purple glow
    draw_set_color(c_purple);
    draw_set_alpha(_alpha);
    draw_sprite_ext(sprite_index, image_index, x, y, _scale, _scale, 0, c_purple, _alpha);
    draw_set_alpha(1);
    draw_set_color(c_white);
    
    // Shield particles
    for (var i = 0; i < 3; i++) {
        var _angle = enchant_pulse_phase * 50 + i * 120;
        var _radius = 10 + sin(enchant_pulse_phase + i) * 3;
        var _px = x + lengthdir_x(_radius, _angle);
        var _py = y + lengthdir_y(_radius, _angle);
        
        draw_set_color(c_fuchsia);
        draw_set_alpha(0.5 + _pulse * 0.3);
        draw_circle(_px, _py, 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// === EXPLOSION DEATH EFFECT ===
if (variable_instance_exists(id, "explosion_death") && explosion_death) {
    var _progress = 1 - (explosion_timer / 15);
    var _shake_x = irandom_range(-4, 4);
    var _shake_y = irandom_range(-4, 4);
    
    // Red flash expanding outward
    draw_set_color(c_red);
    draw_set_alpha(1 - _progress);
    var _expand = 1 + _progress * 2;
    draw_sprite_ext(sprite_index, image_index, x + _shake_x, y + _shake_y, 
                   _expand, _expand, 0, c_red, 1 - _progress);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// === SACRIFICE ANIMATION ===
if (variable_instance_exists(id, "sacrificing") && sacrificing) {
    var _progress = 1 - (sacrifice_timer / 30);
    
    // Shrink and rise
    var _scale = 1 - _progress;
    var _rise = -_progress * 20;
    
    // Purple dissolve effect
    draw_set_alpha(1 - _progress);
    draw_sprite_ext(sprite_index, image_index, x, y + _rise, _scale, _scale, 0, c_purple, 1 - _progress);
    draw_set_alpha(1);
    
    // Particles rising
    for (var i = 0; i < 5; i++) {
        var _px = x + irandom_range(-8, 8);
        var _py = y + _rise - irandom(10);
        draw_set_color(c_purple);
        draw_set_alpha(0.7 - _progress * 0.7);
        draw_circle(_px, _py, 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// === SPAWN RISE ANIMATION ===
if (variable_instance_exists(id, "spawn_rise_timer") && spawn_rise_timer > 0) {
    var _progress = spawn_rise_timer / 30;  // 1 to 0
    
    // Rise from below
    var _offset_y = _progress * 30;
    
    draw_set_alpha(1 - _progress * 0.5);
    draw_sprite_ext(sprite_index, image_index, x, y + _offset_y, 1, 1, 0, c_white, 1 - _progress * 0.5);
    draw_set_alpha(1);
    
    // Golden sparkles
    for (var i = 0; i < 3; i++) {
        var _px = x + irandom_range(-10, 10);
        var _py = y + _offset_y + irandom_range(-5, 15);
        draw_set_color(c_yellow);
        draw_set_alpha(_progress * 0.8);
        draw_circle(_px, _py, 1 + _progress * 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}
```

**Add to `objects/Chess_Piece_Obj/Step_0.gml`:**

```gml
// === EXPLOSION DEATH PROCESSING ===
if (variable_instance_exists(id, "explosion_death") && explosion_death) {
    explosion_timer--;
    if (explosion_timer <= 0) {
        instance_destroy();
    }
}
```

### Step 6: Capture Hook Integration

**Add to the capture handling in `Tile_Obj/Mouse_7.gml` and `ai_execute_move_animated.gml`:**

```gml
// === ENCHANTMENT EXPLOSION CHECK ===
// Before destroying the captured piece:
if (instance_exists(captured_piece)) {
    var _cap_col = round((captured_piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _cap_row = round((captured_piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    if (boss_check_enchanted_capture(captured_piece, _cap_col, _cap_row)) {
        // Explosion will handle piece destruction
        // Don't destroy immediately — wait for explosion
    } else {
        instance_destroy(captured_piece);
    }
}
```

---

## Known Gotchas

### Pawn Selection Order
The design spec says "left pawns first, then right pawns, then middle pawns." This means:
1. First selected = leftmost pawn
2. Second selected = rightmost pawn
3. Third selected = most central remaining pawn

### Explosion Kings Immunity
Kings MUST be immune to explosion damage. This is a failsafe to prevent impossible game states where both kings die simultaneously.

### Sound Assets Required
- `Queen_Spawn_SFX` — Queen rising from sacrifice
- `Enchant_SFX` — Shield application sound
- `Explosion_SFX` — 3×3 explosion

### Cut the Slack Timing
- Turn 1: First Cut the Slack
- Turn 2: Enchant the Cut the Slack queen
- Turn 4, 7, 10...: Subsequent Cut the Slack (every 3 turns)
- Turn 5, 8, 11...: Subsequent Enchant (every 3 turns after turn 2)

### Enchantment Persistence
Enchantment stays on a piece until:
1. The piece is captured (triggers explosion)
2. The boss fight ends

---

## Success Criteria

- [ ] "Cut the Slack!" selects 3 pawns correctly (left, right, middle)
- [ ] Sacrifice animation plays for each pawn
- [ ] New queen spawns at middle pawn position
- [ ] "Enchant!" targets Cut the Slack queen on turn 2
- [ ] "Enchant!" targets random non-pawn on subsequent turns
- [ ] Purple shield visual appears on enchanted pieces
- [ ] Capturing enchanted piece triggers 3×3 explosion
- [ ] Explosion damages both white and black pieces
- [ ] Kings are immune to explosion damage
- [ ] Enchantment is removed after explosion
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Load Queen boss room
2. Wait for turn 1 — "Cut the Slack!" should trigger
3. Verify 3 pawns sacrifice, queen spawns
4. Turn 2 — "Enchant!" should target the new queen
5. Capture the enchanted queen
6. Verify 3×3 explosion occurs
7. Verify pieces in explosion radius are destroyed
8. Verify kings survive if in explosion radius

### Debug Keys

Add to `Boss_Manager/KeyPress_67.gml` (C key):
```gml
// DEBUG: Force Cut the Slack
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "queen") {
    array_push(cheat_queue, "cut_the_slack");
    Game_Manager.turn = 3;
    show_debug_message("DEBUG: Forced Cut the Slack");
}
```

Add to `Boss_Manager/KeyPress_69.gml` (E key):
```gml
// DEBUG: Force Enchant
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "queen") {
    array_push(cheat_queue, "enchant");
    Game_Manager.turn = 3;
    show_debug_message("DEBUG: Forced Enchant");
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-020** — Jester boss (Rookie Mistake!, Mind Control!)
2. Test pawn sacrifice thoroughly
3. Test explosion edge cases (multiple enchanted pieces, kings in radius)
