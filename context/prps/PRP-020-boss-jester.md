# PRP-020: Boss 3 — Jester (Volcanic Wasteland)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** MEDIUM  
**Depends On:** PRP-017 (Boss Framework)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

The Jester is the third boss encounter (Volcanic Wasteland). He uses medium AI that makes a "bad move" every 4 turns, and has two cheat abilities:

1. **"Rookie Mistake!"** — Modified board setup with 8 rooks that slam down periodically
2. **"Mind Control!"** — Forces player to make a random move (but doesn't skip their turn)

This PRP implements both cheats with full animations, board modification, and the unique player control hijacking mechanic.

---

## Boss Specification (from Design Doc)

### AI Settings
- **Difficulty:** Medium (level 3)
- **Bad Move Frequency:** Every 4 turns
- **Bad Move Offset:** Pick 2nd-3rd best move

### Cheat 1 — "Rookie Mistake!"

| Aspect | Behavior |
|--------|----------|
| **Pre-Match Setup** | All back-rank pieces shift down 1 tile (to 7th rank) |
| **Board Modification** | 8th rank fills with 8 ROOKS |
| **Rook Slam** | Every 3 turns: all 8 rooks slam downward simultaneously |
| **Slam Damage** | Captures any WHITE pieces in their path |
| **Slam Blocking** | Rooks STOP if they hit a BLACK piece (won't go through own pieces) |
| **Rook Return** | After slamming, rooks return to 8th rank |
| **Visual** | Rooks slide down, capture flash, slide back up |

### Cheat 2 — "Mind Control!"

| Aspect | Behavior |
|--------|----------|
| **Trigger** | Turn 3, then every 4 turns |
| **Effect** | Jester moves one of your pieces FOR you |
| **AI Level** | Uses lowest-level AI (depth 1, minimal evaluation) |
| **Visibility** | Player CANNOT see which piece will be moved beforehand |
| **Turn Impact** | Does NOT skip player's turn — they still get their normal move after |
| **Selection** | Random player piece with at least one legal move |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      JESTER BOSS CHEAT ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                PRE-MATCH SETUP (turn 0)                                │  │
│  │                                                                        │  │
│  │   Original Board:           Modified Board:                           │  │
│  │   Row 0: R N B Q K B N R    Row 0: R R R R R R R R  (8 ROOKS)        │  │
│  │   Row 1: P P P P P P P P    Row 1: R N B Q K B N R  (shifted down)   │  │
│  │                              Row 2: P P P P P P P P  (pawns same)     │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    "ROOKIE MISTAKE!" ROOK SLAM                         │  │
│  │                                                                        │  │
│  │   Every 3 turns:                                                       │  │
│  │                                                                        │  │
│  │   Row 0: [R] [R] [R] [R] [R] [R] [R] [R]   ← Start position           │  │
│  │          ↓   ↓   ↓   ↓   ↓   ↓   ↓   ↓                               │  │
│  │   Row 7: [R] [R] [R] [R] [R] [R] [R] [R]   ← Slam to bottom           │  │
│  │                                                                        │  │
│  │   • Capture any white pieces in path                                   │  │
│  │   • Stop if hitting black piece                                        │  │
│  │   • Return to row 0 after slam                                         │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    "MIND CONTROL!" FLOW                                │  │
│  │                                                                        │  │
│  │   Trigger ──▶ Select Random Player Piece ──▶ Calculate Worst Move     │  │
│  │                      │                              │                  │  │
│  │                      │                              ▼                  │  │
│  │                      │                    Execute Move (animated)      │  │
│  │                      │                              │                  │  │
│  │                      │                              ▼                  │  │
│  │                      └───────────────▶ Player Gets Normal Turn        │  │
│  │                                                                        │  │
│  │   Note: Mind Control does NOT end player's turn!                       │  │
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
  why: Boss 3 specification

- path: context/prps/PRP-017-boss-framework.md
  why: Boss_Manager, cheat execution framework

- path: objects/Rook_Obj/Create_0.gml
  why: Rook object structure

- path: scripts/ai_get_piece_moves_virtual/ai_get_piece_moves_virtual.gml
  why: Move generation for mind control
```

### Files to Create

```yaml
- path: scripts/boss_cheat_rookie_mistake/boss_cheat_rookie_mistake.gml
  purpose: "Rookie Mistake!" cheat implementation

- path: scripts/boss_cheat_mind_control/boss_cheat_mind_control.gml
  purpose: "Mind Control!" cheat implementation

- path: scripts/boss_jester_utils/boss_jester_utils.gml
  purpose: Utility functions (board setup, rook tracking, etc.)

- path: scripts/boss_jester_rook_slam/boss_jester_rook_slam.gml
  purpose: Rook slam animation and damage logic
```

### Files to Modify

```yaml
- path: objects/Boss_Manager/Create_0.gml
  changes: Add Jester-specific state variables

- path: objects/Rook_Obj/Draw_0.gml
  changes: Add slam animation visual effects

- path: objects/Enemy_Army_Manager/Create_0.gml
  changes: Detect Jester level and modify initial spawn
```

---

## Implementation Blueprint

### Step 1: Jester Utility Functions

**File:** `scripts/boss_jester_utils/boss_jester_utils.gml`

```gml
/// @function boss_jester_setup_board()
/// @description Pre-match setup: shift back rank down, fill row 0 with 8 rooks
function boss_jester_setup_board() {
    show_debug_message("Boss Jester: Setting up modified board...");
    
    // Track the 8 slam rooks
    Boss_Manager.slam_rooks = [];
    
    // Step 1: Find and shift all black back-rank pieces down one row
    var _back_rank_pieces = [];
    with (Chess_Piece_Obj) {
        if (piece_type == 1) {  // Black
            var _row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            if (_row == 0) {
                array_push(_back_rank_pieces, id);
            }
        }
    }
    
    // Shift them all down
    for (var i = 0; i < array_length(_back_rank_pieces); i++) {
        var _piece = _back_rank_pieces[i];
        _piece.y += Board_Manager.tile_size;  // Move down 1 row
        show_debug_message("Boss Jester: Shifted " + _piece.piece_id + " to row 1");
    }
    
    // Step 2: Create 8 rooks on row 0
    for (var col = 0; col < 8; col++) {
        var _x = Object_Manager.topleft_x + col * Board_Manager.tile_size;
        var _y = Object_Manager.topleft_y + 0 * Board_Manager.tile_size;
        
        var _rook = instance_create_depth(_x, _y, -1, Rook_Obj);
        _rook.piece_type = 1;  // Black
        _rook.has_moved = true;
        _rook.is_slam_rook = true;
        _rook.slam_rook_col = col;
        _rook.home_row = 0;
        
        array_push(Boss_Manager.slam_rooks, _rook);
    }
    
    show_debug_message("Boss Jester: Board setup complete - 8 slam rooks placed");
}

/// @function boss_jester_get_player_pieces_with_moves()
/// @returns {array} Array of player pieces that have at least one legal move
function boss_jester_get_player_pieces_with_moves() {
    var _pieces = [];
    
    with (Chess_Piece_Obj) {
        if (piece_type == 0) {  // White (player)
            // Calculate valid moves for this piece
            var _moves = boss_jester_get_piece_legal_moves(id);
            if (array_length(_moves) > 0) {
                array_push(_pieces, id);
            }
        }
    }
    
    return _pieces;
}

/// @function boss_jester_get_piece_legal_moves(_piece)
/// @param {instance} _piece The piece to get moves for
/// @returns {array} Array of legal moves for this piece
function boss_jester_get_piece_legal_moves(_piece) {
    if (!instance_exists(_piece)) return [];
    
    var _moves = [];
    var _col = round((_piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _row = round((_piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Build a simple virtual board
    var _board = array_create(8);
    for (var r = 0; r < 8; r++) {
        _board[r] = array_create(8, noone);
    }
    
    with (Chess_Piece_Obj) {
        var _pc = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var _pr = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (_pc >= 0 && _pc < 8 && _pr >= 0 && _pr < 8) {
            _board[_pr][_pc] = {
                piece_id: piece_id,
                piece_type: piece_type,
                instance: id
            };
        }
    }
    
    // Get piece-specific moves
    var _raw_moves = [];
    
    switch (_piece.piece_id) {
        case "pawn":
            _raw_moves = boss_jester_get_pawn_moves(_board, _col, _row, 0);
            break;
        case "knight":
            _raw_moves = boss_jester_get_knight_moves(_board, _col, _row, 0);
            break;
        case "bishop":
            _raw_moves = boss_jester_get_sliding_moves(_board, _col, _row, 0, 
                [[-1,-1], [-1,1], [1,-1], [1,1]]);
            break;
        case "rook":
            _raw_moves = boss_jester_get_sliding_moves(_board, _col, _row, 0,
                [[0,-1], [0,1], [-1,0], [1,0]]);
            break;
        case "queen":
            _raw_moves = boss_jester_get_sliding_moves(_board, _col, _row, 0,
                [[-1,-1], [-1,1], [1,-1], [1,1], [0,-1], [0,1], [-1,0], [1,0]]);
            break;
        case "king":
            _raw_moves = boss_jester_get_king_moves(_board, _col, _row, 0);
            break;
    }
    
    // Filter out moves that leave king in check
    for (var i = 0; i < array_length(_raw_moves); i++) {
        var _move = _raw_moves[i];
        // Simplified check - in full implementation, verify with move_leaves_king_in_check
        array_push(_moves, _move);
    }
    
    return _moves;
}

/// @function boss_jester_get_pawn_moves(_board, _col, _row, _color)
function boss_jester_get_pawn_moves(_board, _col, _row, _color) {
    var _moves = [];
    var _dir = (_color == 0) ? -1 : 1;  // White moves up, black moves down
    var _start_row = (_color == 0) ? 6 : 1;
    
    // Forward 1
    var _nr = _row + _dir;
    if (_nr >= 0 && _nr < 8 && _board[_nr][_col] == noone) {
        array_push(_moves, { to_col: _col, to_row: _nr });
        
        // Forward 2 from start
        if (_row == _start_row) {
            var _nr2 = _row + _dir * 2;
            if (_board[_nr2][_col] == noone) {
                array_push(_moves, { to_col: _col, to_row: _nr2 });
            }
        }
    }
    
    // Diagonal captures
    for (var dc = -1; dc <= 1; dc += 2) {
        var _nc = _col + dc;
        var _nr = _row + _dir;
        if (_nc >= 0 && _nc < 8 && _nr >= 0 && _nr < 8) {
            if (_board[_nr][_nc] != noone && _board[_nr][_nc].piece_type != _color) {
                array_push(_moves, { to_col: _nc, to_row: _nr, is_capture: true });
            }
        }
    }
    
    return _moves;
}

/// @function boss_jester_get_knight_moves(_board, _col, _row, _color)
function boss_jester_get_knight_moves(_board, _col, _row, _color) {
    var _moves = [];
    var _offsets = [[1,-2], [1,2], [-1,-2], [-1,2], [2,-1], [2,1], [-2,-1], [-2,1]];
    
    for (var i = 0; i < 8; i++) {
        var _nc = _col + _offsets[i][0];
        var _nr = _row + _offsets[i][1];
        
        if (_nc >= 0 && _nc < 8 && _nr >= 0 && _nr < 8) {
            var _target = _board[_nr][_nc];
            if (_target == noone || _target.piece_type != _color) {
                array_push(_moves, { to_col: _nc, to_row: _nr, is_capture: (_target != noone) });
            }
        }
    }
    
    return _moves;
}

/// @function boss_jester_get_sliding_moves(_board, _col, _row, _color, _directions)
function boss_jester_get_sliding_moves(_board, _col, _row, _color, _directions) {
    var _moves = [];
    
    for (var d = 0; d < array_length(_directions); d++) {
        var _dx = _directions[d][0];
        var _dy = _directions[d][1];
        
        for (var dist = 1; dist <= 7; dist++) {
            var _nc = _col + _dx * dist;
            var _nr = _row + _dy * dist;
            
            if (_nc < 0 || _nc >= 8 || _nr < 0 || _nr >= 8) break;
            
            var _target = _board[_nr][_nc];
            if (_target == noone) {
                array_push(_moves, { to_col: _nc, to_row: _nr });
            } else if (_target.piece_type != _color) {
                array_push(_moves, { to_col: _nc, to_row: _nr, is_capture: true });
                break;
            } else {
                break;  // Own piece blocks
            }
        }
    }
    
    return _moves;
}

/// @function boss_jester_get_king_moves(_board, _col, _row, _color)
function boss_jester_get_king_moves(_board, _col, _row, _color) {
    var _moves = [];
    
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            
            var _nc = _col + dx;
            var _nr = _row + dy;
            
            if (_nc >= 0 && _nc < 8 && _nr >= 0 && _nr < 8) {
                var _target = _board[_nr][_nc];
                if (_target == noone || _target.piece_type != _color) {
                    array_push(_moves, { to_col: _nc, to_row: _nr, is_capture: (_target != noone) });
                }
            }
        }
    }
    
    return _moves;
}

/// @function boss_jester_execute_piece_move(_piece, _move)
/// @param {instance} _piece The piece to move
/// @param {struct} _move The move to execute {to_col, to_row}
function boss_jester_execute_piece_move(_piece, _move) {
    if (!instance_exists(_piece)) return;
    
    var _to_x = Object_Manager.topleft_x + _move.to_col * Board_Manager.tile_size;
    var _to_y = Object_Manager.topleft_y + _move.to_row * Board_Manager.tile_size;
    
    // Handle capture
    if (variable_struct_exists(_move, "is_capture") && _move.is_capture) {
        var _target = instance_position(_to_x, _to_y, Chess_Piece_Obj);
        if (instance_exists(_target)) {
            instance_destroy(_target);
            audio_play_sound(Piece_Capture_SFX, 1, false);
        }
    }
    
    // Animate the move
    with (_piece) {
        move_start_x = x;
        move_start_y = y;
        move_target_x = _to_x;
        move_target_y = _to_y;
        move_progress = 0;
        move_duration = 25;
        is_moving = true;
        has_moved = true;
        move_animation_type = (piece_id == "knight") ? "knight" : "linear";
        
        // Mark as mind controlled move
        mind_controlled_move = true;
    }
    
    show_debug_message("Boss Jester: Mind Control moved " + _piece.piece_id + 
        " to (" + string(_move.to_col) + "," + string(_move.to_row) + ")");
}
```

### Step 2: "Rookie Mistake!" Cheat Implementation

**File:** `scripts/boss_cheat_rookie_mistake/boss_cheat_rookie_mistake.gml`

```gml
/// @function boss_cheat_rookie_mistake()
/// @returns {bool} True if cheat execution is complete
/// @description "Rookie Mistake!" - Pre-match board setup OR rook slam
function boss_cheat_rookie_mistake() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "rm_state")) {
        _mgr.rm_state = "init";
        _mgr.rm_setup_complete = false;
        show_debug_message("Boss Jester: Starting 'Rookie Mistake!' cheat");
    }
    
    // Pre-match setup (turn 0)
    if (_mgr.boss_turn_count == 0 && !_mgr.rm_setup_complete) {
        switch (_mgr.rm_state) {
            case "init":
                boss_jester_setup_board();
                _mgr.rm_setup_complete = true;
                _mgr.rm_state = "complete";
                break;
                
            case "complete":
                _mgr.rm_state = undefined;
                return true;
        }
        return false;
    }
    
    // Rook slam (every 3 turns after setup)
    return boss_jester_rook_slam();
}
```

### Step 3: Rook Slam Implementation

**File:** `scripts/boss_jester_rook_slam/boss_jester_rook_slam.gml`

```gml
/// @function boss_jester_rook_slam()
/// @returns {bool} True if slam is complete
/// @description Execute the 8-rook slam attack
function boss_jester_rook_slam() {
    var _mgr = Boss_Manager;
    
    // Initialize slam state
    if (!variable_instance_exists(_mgr, "slam_state")) {
        _mgr.slam_state = "init";
        _mgr.slam_rook_targets = [];  // Target row for each rook
        _mgr.slam_captures = [];       // Pieces to capture
        _mgr.slam_anim_phase = 0;
        show_debug_message("Boss Jester: Starting rook slam!");
    }
    
    switch (_mgr.slam_state) {
        case "init":
            // Calculate slam targets for each rook
            _mgr.slam_rook_targets = [];
            _mgr.slam_captures = [];
            
            for (var i = 0; i < array_length(_mgr.slam_rooks); i++) {
                var _rook = _mgr.slam_rooks[i];
                if (!instance_exists(_rook)) {
                    array_push(_mgr.slam_rook_targets, -1);  // Rook destroyed
                    continue;
                }
                
                var _col = _rook.slam_rook_col;
                var _target_row = 7;  // Default: slam all the way
                
                // Check for blockers in the column
                for (var row = 1; row <= 7; row++) {
                    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
                    var _y = Object_Manager.topleft_y + row * Board_Manager.tile_size;
                    var _piece = instance_position(_x, _y, Chess_Piece_Obj);
                    
                    if (_piece != noone && _piece != _rook) {
                        if (_piece.piece_type == 1) {
                            // Black piece = stop BEFORE it
                            _target_row = row - 1;
                            break;
                        } else {
                            // White piece = capture it, continue
                            array_push(_mgr.slam_captures, {
                                piece: _piece,
                                col: _col,
                                row: row
                            });
                        }
                    }
                }
                
                // Don't go below row 0
                if (_target_row < 0) _target_row = 0;
                
                array_push(_mgr.slam_rook_targets, _target_row);
            }
            
            // Play slam sound
            audio_play_sound(Rook_Slam_SFX, 1, false);
            
            _mgr.slam_state = "slam_down";
            _mgr.slam_anim_timer = 30;  // Animation duration
            break;
            
        case "slam_down":
            // Animate rooks moving down
            var _progress = 1 - (_mgr.slam_anim_timer / 30);
            
            for (var i = 0; i < array_length(_mgr.slam_rooks); i++) {
                var _rook = _mgr.slam_rooks[i];
                if (!instance_exists(_rook)) continue;
                
                var _target_row = _mgr.slam_rook_targets[i];
                if (_target_row < 0) continue;
                
                var _start_y = Object_Manager.topleft_y + 0 * Board_Manager.tile_size;
                var _end_y = Object_Manager.topleft_y + _target_row * Board_Manager.tile_size;
                
                _rook.y = lerp(_start_y, _end_y, _progress);
                _rook.slamming = true;
            }
            
            _mgr.slam_anim_timer--;
            
            if (_mgr.slam_anim_timer <= 0) {
                // Capture pieces
                for (var i = 0; i < array_length(_mgr.slam_captures); i++) {
                    var _cap = _mgr.slam_captures[i];
                    if (instance_exists(_cap.piece)) {
                        show_debug_message("Boss Jester: Rook slam captured " + _cap.piece.piece_id);
                        _cap.piece.slam_captured = true;
                        _cap.piece.slam_flash_timer = 15;
                    }
                }
                
                _mgr.slam_state = "impact";
                _mgr.slam_anim_timer = 20;
            }
            break;
            
        case "impact":
            // Screen shake and capture flash
            _mgr.slam_anim_timer--;
            
            // Apply screen shake
            global.screen_shake_intensity = max(0, (_mgr.slam_anim_timer / 20) * 6);
            
            // Destroy captured pieces after flash
            if (_mgr.slam_anim_timer == 10) {
                for (var i = 0; i < array_length(_mgr.slam_captures); i++) {
                    var _cap = _mgr.slam_captures[i];
                    if (instance_exists(_cap.piece)) {
                        instance_destroy(_cap.piece);
                    }
                }
                audio_play_sound(Piece_Capture_SFX, 1, false);
            }
            
            if (_mgr.slam_anim_timer <= 0) {
                _mgr.slam_state = "return";
                _mgr.slam_anim_timer = 25;
            }
            break;
            
        case "return":
            // Animate rooks returning to row 0
            var _progress = 1 - (_mgr.slam_anim_timer / 25);
            
            for (var i = 0; i < array_length(_mgr.slam_rooks); i++) {
                var _rook = _mgr.slam_rooks[i];
                if (!instance_exists(_rook)) continue;
                
                var _target_row = _mgr.slam_rook_targets[i];
                if (_target_row < 0) continue;
                
                var _start_y = Object_Manager.topleft_y + _target_row * Board_Manager.tile_size;
                var _end_y = Object_Manager.topleft_y + 0 * Board_Manager.tile_size;
                
                _rook.y = lerp(_start_y, _end_y, _progress);
            }
            
            _mgr.slam_anim_timer--;
            
            if (_mgr.slam_anim_timer <= 0) {
                _mgr.slam_state = "complete";
            }
            break;
            
        case "complete":
            // Reset rook states
            for (var i = 0; i < array_length(_mgr.slam_rooks); i++) {
                var _rook = _mgr.slam_rooks[i];
                if (instance_exists(_rook)) {
                    _rook.slamming = false;
                    _rook.y = Object_Manager.topleft_y;  // Ensure at row 0
                }
            }
            
            global.screen_shake_intensity = 0;
            _mgr.slam_state = undefined;
            
            show_debug_message("Boss Jester: Rook slam complete!");
            return true;
    }
    
    return false;
}
```

### Step 4: "Mind Control!" Cheat Implementation

**File:** `scripts/boss_cheat_mind_control/boss_cheat_mind_control.gml`

```gml
/// @function boss_cheat_mind_control()
/// @returns {bool} True if cheat execution is complete
/// @description "Mind Control!" - Force player to make a random move
function boss_cheat_mind_control() {
    var _mgr = Boss_Manager;
    
    // Initialize state if starting
    if (!variable_instance_exists(_mgr, "mc_state")) {
        _mgr.mc_state = "init";
        _mgr.mc_target_piece = noone;
        _mgr.mc_selected_move = undefined;
        show_debug_message("Boss Jester: Starting 'Mind Control!' cheat");
    }
    
    switch (_mgr.mc_state) {
        case "init":
            // Get all player pieces with legal moves
            var _pieces = boss_jester_get_player_pieces_with_moves();
            
            if (array_length(_pieces) == 0) {
                show_debug_message("Boss Jester: No player pieces to mind control");
                _mgr.mc_state = undefined;
                return true;
            }
            
            // Select random piece
            _mgr.mc_target_piece = _pieces[irandom(array_length(_pieces) - 1)];
            
            // Get moves for this piece
            var _moves = boss_jester_get_piece_legal_moves(_mgr.mc_target_piece);
            
            if (array_length(_moves) == 0) {
                show_debug_message("Boss Jester: Selected piece has no moves");
                _mgr.mc_state = undefined;
                return true;
            }
            
            // Select a move using "worst" AI (random, or actually bad)
            // For flavor, pick a move that doesn't help the player
            _mgr.mc_selected_move = boss_jester_select_bad_move(_mgr.mc_target_piece, _moves);
            
            _mgr.mc_state = "announce";
            _mgr.mc_announce_timer = 30;
            break;
            
        case "announce":
            // Brief pause to show mind control effect
            _mgr.mc_announce_timer--;
            
            // Visual effect on target piece
            if (instance_exists(_mgr.mc_target_piece)) {
                _mgr.mc_target_piece.mind_control_pulse = true;
            }
            
            if (_mgr.mc_announce_timer <= 0) {
                _mgr.mc_state = "execute";
            }
            break;
            
        case "execute":
            // Execute the forced move
            boss_jester_execute_piece_move(_mgr.mc_target_piece, _mgr.mc_selected_move);
            _mgr.mc_state = "wait_animation";
            break;
            
        case "wait_animation":
            // Wait for move animation to complete
            if (instance_exists(_mgr.mc_target_piece) && _mgr.mc_target_piece.is_moving) {
                break;  // Still animating
            }
            
            _mgr.mc_state = "complete";
            break;
            
        case "complete":
            // Clear mind control visual
            if (instance_exists(_mgr.mc_target_piece)) {
                _mgr.mc_target_piece.mind_control_pulse = false;
            }
            
            // IMPORTANT: Mind control does NOT end the player's turn!
            // The player still gets their normal move after this
            _mgr.mind_control_just_used = true;
            
            _mgr.mc_state = undefined;
            show_debug_message("Boss Jester: Mind Control complete - player still gets their turn!");
            return true;
    }
    
    return false;
}

/// @function boss_jester_select_bad_move(_piece, _moves)
/// @param {instance} _piece The piece being moved
/// @param {array} _moves Available moves
/// @returns {struct} A deliberately bad move
function boss_jester_select_bad_move(_piece, _moves) {
    if (array_length(_moves) == 0) return undefined;
    
    // Score each move (lower = worse for player)
    var _worst_move = _moves[0];
    var _worst_score = 999999;
    
    for (var i = 0; i < array_length(_moves); i++) {
        var _move = _moves[i];
        var _score = 0;
        
        // Prefer moves that don't capture (miss opportunities)
        if (!variable_struct_exists(_move, "is_capture") || !_move.is_capture) {
            _score -= 50;
        }
        
        // Prefer moves toward the edge (usually bad)
        var _center_dist = abs(_move.to_col - 3.5) + abs(_move.to_row - 3.5);
        _score += _center_dist * 5;
        
        // Prefer moves that move back (retreat)
        var _from_row = round((_piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (_move.to_row > _from_row) {  // Moving down (backward for white)
            _score -= 30;
        }
        
        // Add some randomness
        _score += irandom(20);
        
        if (_score < _worst_score) {
            _worst_score = _score;
            _worst_move = _move;
        }
    }
    
    return _worst_move;
}
```

### Step 5: Rook Visual Effects

**Add to `objects/Rook_Obj/Draw_0.gml`:**

```gml
/// Rook_Obj Draw Event additions for Jester boss slam effects

// === SLAM ROOK VISUAL ===
if (variable_instance_exists(id, "is_slam_rook") && is_slam_rook) {
    // Glowing red eyes effect when slamming
    if (variable_instance_exists(id, "slamming") && slamming) {
        var _pulse = (sin(current_time / 50) + 1) / 2;
        
        // Motion blur trail
        draw_set_alpha(0.3);
        for (var i = 1; i <= 3; i++) {
            draw_sprite(sprite_index, image_index, x, y - i * 8);
        }
        draw_set_alpha(1);
        
        // Red glow
        draw_set_color(c_red);
        draw_set_alpha(0.4 + _pulse * 0.3);
        draw_sprite(sprite_index, image_index, x, y);
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
}

// === SLAM CAPTURE FLASH ===
if (variable_instance_exists(id, "slam_flash_timer") && slam_flash_timer > 0) {
    slam_flash_timer--;
    var _flash = slam_flash_timer / 15;
    
    draw_set_color(c_white);
    draw_set_alpha(_flash);
    draw_sprite(sprite_index, image_index, x, y);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
```

### Step 6: Chess Piece Mind Control Visual

**Add to `objects/Chess_Piece_Obj/Draw_0.gml`:**

```gml
// === MIND CONTROL VISUAL ===
if (variable_instance_exists(id, "mind_control_pulse") && mind_control_pulse) {
    var _pulse = (sin(current_time / 80) + 1) / 2;
    
    // Purple hypnotic swirl
    draw_set_color(c_purple);
    draw_set_alpha(0.5 + _pulse * 0.3);
    
    var _swirl_offset = current_time / 100;
    for (var i = 0; i < 4; i++) {
        var _angle = _swirl_offset + i * 90;
        var _radius = 8 + sin(_swirl_offset * 2 + i) * 3;
        var _px = x + lengthdir_x(_radius, _angle);
        var _py = y + lengthdir_y(_radius, _angle);
        draw_circle(_px, _py, 2, false);
    }
    
    // Central glow
    draw_set_alpha(0.3 + _pulse * 0.2);
    draw_circle(x, y, 12, false);
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}
```

### Step 7: Turn Flow for Mind Control

**Add to `objects/Game_Manager/Step_0.gml`:**

```gml
// === MIND CONTROL TURN HANDLING ===
// After mind control, ensure player still gets their turn
if (instance_exists(Boss_Manager) && 
    variable_instance_exists(Boss_Manager, "mind_control_just_used") &&
    Boss_Manager.mind_control_just_used) {
    
    // Wait for mind control animation to finish
    var _any_moving = false;
    with (Chess_Piece_Obj) {
        if (is_moving) {
            _any_moving = true;
            break;
        }
    }
    
    if (!_any_moving) {
        // Animation done - give player their turn
        turn = 0;
        Boss_Manager.mind_control_just_used = false;
        show_debug_message("Game: Player turn after mind control");
    }
}
```

---

## Known Gotchas

### Board Setup Timing
The "Rookie Mistake!" board setup must happen BEFORE armies spawn, or immediately after. The cleanest approach is to detect the Jester level in `Enemy_Army_Manager` and modify spawn positions there.

### Rook Slam and Board State
After rook slam:
1. Captured pieces are destroyed
2. AI's virtual board is stale
3. MUST call `boss_resync_board_state()`

### Mind Control Turn Order
Critical: Mind Control does NOT consume the player's turn!
- Cheat executes during boss cheat phase
- Player turn happens AFTER cheat phase
- Player can make their own move after being mind controlled

### Slam Rooks vs Regular Rooks
The 8 slam rooks are special:
- Marked with `is_slam_rook = true`
- Don't participate in normal chess moves during slam
- Return to row 0 after each slam
- Can be captured by player (removes from slam array)

### Sound Assets Required
- `Rook_Slam_SFX` — Heavy slam sound
- `Mind_Control_SFX` — Eerie mind control sound

---

## Success Criteria

- [ ] Pre-match setup shifts back rank pieces correctly
- [ ] 8 rooks appear on row 0
- [ ] Rook slam animates all 8 rooks simultaneously
- [ ] Rook slam captures white pieces in path
- [ ] Rook slam stops at black pieces
- [ ] Rooks return to row 0 after slam
- [ ] Mind control selects a random player piece
- [ ] Mind control executes a "bad" move
- [ ] Player still gets their turn after mind control
- [ ] Mind control visual effects display correctly
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Load Jester boss room
2. Verify board setup (8 rooks on row 0, pieces shifted down)
3. Play until turn 3 (rook slam should trigger)
4. Verify rooks animate down, capture any white pieces
5. Verify rooks return to top
6. Wait for Mind Control trigger
7. Verify a piece moves without player input
8. Verify player CAN still move after mind control

### Debug Keys

Add to `Boss_Manager/KeyPress_82.gml` (R key):
```gml
// DEBUG: Force rook slam
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "jester") {
    rm_state = undefined;  // Reset state
    rm_setup_complete = true;  // Skip setup
    array_push(cheat_queue, "rookie_mistake");
    Game_Manager.turn = 3;
    show_debug_message("DEBUG: Forced rook slam");
}
```

Add to `Boss_Manager/KeyPress_77.gml` (M key):
```gml
// DEBUG: Force mind control
if (keyboard_check(vk_shift) && is_boss_level && current_boss_id == "jester") {
    array_push(cheat_queue, "mind_control");
    Game_Manager.turn = 3;
    show_debug_message("DEBUG: Forced mind control");
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-021** — The King final boss (two phases, most complex)
2. Test rook slam with various board states
3. Test mind control edge cases (king in check, etc.)
