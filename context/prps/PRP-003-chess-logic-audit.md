# PRP-003: Core Chess Logic Audit

## Overview
Before improving the AI, ensure the base chess rules are correctly implemented. This PRP audits piece movement, captures, check/checkmate, castling, en passant, and promotion.

## Current Implementation Summary

### Piece Movement

#### Pawn (Pawn_Obj)
**Location:** `objects/Pawn_Obj/Step_0.gml`

```gml
// White pawns (piece_type == 0)
- Forward 1: [0, -1] if square empty
- Forward 2: [0, -2] if !has_moved AND both squares empty  
- Diagonal capture: [-1, -1] or [1, -1] if enemy piece
- En passant: to en_passant_target if conditions met

// Black pawns (piece_type == 1)  
- Forward 1: [0, 1] if square empty
- Forward 2: [0, 2] if !has_moved AND both squares empty
- Diagonal capture: [-1, 1] or [1, 1] if enemy piece
- En passant: to en_passant_target if conditions met
```

**⚠️ Issue Found:** Pawn move validation doesn't check for pieces blocking the two-square move's intermediate square properly. Fixed in current code.

**✅ Verified:** 
- White pawns move up (-y direction)
- Black pawns move down (+y direction)
- Captures check for enemy pieces correctly

#### Knight (Knight_Obj)
**Location:** `objects/Knight_Obj/Create_0.gml`

```gml
valid_moves = [[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]];
```

**✅ Verified:** All 8 L-shaped moves defined correctly. Knight can jump over pieces (inherent in the system since it just checks destination).

#### Bishop (Bishop_Obj)
**Location:** `objects/Bishop_Obj/Step_0.gml`

```gml
// Generates diagonal rays in all 4 directions
// Stops at board edge, blocking piece, or capture
```

**⚠️ Need to verify:** Does it correctly stop at friendly pieces and capture enemy pieces?

#### Rook (Rook_Obj)
**Location:** `objects/Rook_Obj/Step_0.gml`

```gml
// Generates orthogonal rays in all 4 directions
// Stops at board edge, blocking piece, or capture
```

**⚠️ Need to verify:** Same as Bishop.

#### Queen (Queen_Obj)
**Location:** `objects/Queen_Obj/Step_0.gml`

```gml
// Combination of Rook + Bishop movement
```

**⚠️ Need to verify:** Should inherit behavior from both.

#### King (King_Obj)
**Location:** `objects/King_Obj/Create_0.gml`, `Step_0.gml`

```gml
// Create: 8 adjacent squares
valid_moves = [
    [0,-1], [1,-1], [1,0], [1,1],
    [0,1], [-1,1], [-1,0], [-1,-1]
];

// Step: Castling logic
// - Check if king hasn't moved
// - Find rooks that haven't moved
// - Check path is clear
// - Add castle_moves[] for valid castles
```

**⚠️ Issues to check:**
1. Does king avoid moving into check? (Currently relies on AI, not enforced for player)
2. Does castling check if king passes through/lands on attacked square?

### Captures
**Location:** `objects/Tile_Obj/Mouse_7.gml` (player), `scripts/ai_execute_move_animated` (AI)

```gml
// Player captures:
var enemy = instance_position(x, y, Chess_Piece_Obj);
if (enemy != noone && enemy != piece && enemy.piece_type != piece.piece_type) {
    piece.pending_capture = enemy;
}

// Capture happens in Chess_Piece_Obj Step after animation:
if (pending_capture != noone) {
    pending_capture.health_ -= 1;
    if (pending_capture.health_ <= 0) {
        instance_destroy(pending_capture);
    }
}
```

**✅ Verified:** Capture logic is sound. Health system allows for special pieces with more health.

### En Passant
**Location:** `objects/Game_Manager/Create_0.gml`, `objects/Pawn_Obj/Step_0.gml`, `objects/Chess_Piece_Obj/Step_0.gml`

```gml
// Game_Manager tracks:
en_passant_target_x = -1;
en_passant_target_y = -1;
en_passant_pawn = noone;

// Set in Chess_Piece_Obj Step when pawn moves 2 squares:
if (piece_id == "pawn" && abs(original_turn_y - y) == Board_Manager.tile_size * 2) {
    Game_Manager.en_passant_target_x = x;
    Game_Manager.en_passant_target_y = (original_turn_y + y) / 2;
    en_passant_vulnerable = true;
    Game_Manager.en_passant_pawn = self;
}

// Cleared otherwise

// Pawn Step adds en passant capture as valid move:
if (abs(x - Game_Manager.en_passant_target_x) == Board_Manager.tile_size &&
    abs(y - Game_Manager.en_passant_target_y) == Board_Manager.tile_size) {
    array_push(valid_moves, [dx, dy, "en_passant"]);
}

// Capture executed in Chess_Piece_Obj Step:
if (pending_en_passant) {
    instance_destroy(Game_Manager.en_passant_pawn);
}
```

**⚠️ Issues to check:**
1. Is en passant target cleared after opponent's move? (Should only be valid for one turn)
2. Does AI properly consider en passant moves?

### Castling
**Location:** `objects/King_Obj/Step_0.gml`, `objects/Tile_Obj/Mouse_7.gml`

**Current logic:**
1. King hasn't moved (`!has_moved`)
2. Rook hasn't moved (`!rook.has_moved`)
3. Same row (`abs(y - rook.y) < tile_size/2`)
4. Path clear between them
5. King moves 2 squares, rook moves to other side

**⚠️ Missing checks:**
1. ❌ King is not currently in check
2. ❌ King does not pass through check
3. ❌ King does not land in check

**Fix needed in King_Obj Step:**
```gml
// Before adding castle move, check:
// 1. King not in check
var in_check = false;
with (Chess_Piece_Obj) {
    if (piece_type != other.piece_type) {
        for (var m = 0; m < array_length(valid_moves); m++) {
            var ax = x + valid_moves[m][0] * Board_Manager.tile_size;
            var ay = y + valid_moves[m][1] * Board_Manager.tile_size;
            if (point_distance(ax, ay, other.x, other.y) < Board_Manager.tile_size/2) {
                in_check = true;
                break;
            }
        }
    }
    if (in_check) break;
}

if (in_check) {
    // Can't castle while in check
    continue; // Skip this rook
}

// 2. Check intermediate squares aren't attacked
var safe_path = true;
for (var s = 1; s <= 2; s++) {
    var check_x = x + s * dir * Board_Manager.tile_size;
    with (Chess_Piece_Obj) {
        if (piece_type != other.piece_type) {
            for (var m = 0; m < array_length(valid_moves); m++) {
                var ax = x + valid_moves[m][0] * Board_Manager.tile_size;
                var ay = y + valid_moves[m][1] * Board_Manager.tile_size;
                if (point_distance(ax, ay, check_x, other.y) < Board_Manager.tile_size/2) {
                    safe_path = false;
                    break;
                }
            }
        }
        if (!safe_path) break;
    }
    if (!safe_path) break;
}

if (!safe_path) continue;
```

### Promotion
**Location:** `objects/Pawn_Obj/Step_0.gml`

```gml
// White pawn at top row:
if (y == Top_Row.y) {
    var temp = piece_type;
    instance_change(Queen_Obj, 1);
    piece_type = temp;
}

// Black pawn at bottom row:
if (y == Bottom_Row.y) {
    var temp = piece_type;
    instance_change(Queen_Obj, 1);
    piece_type = temp;
}
```

**⚠️ Issues:**
1. Auto-promotes to Queen only (no choice)
2. Should this be a player choice? (Knight promotion is sometimes better)
3. Does `instance_change` preserve all necessary variables?

**Consider:** For simplicity, auto-Queen is fine. Add underpromotion later if needed.

### Check Detection

**AI's current method:** `ai_is_king_in_check_simple(color)`
```gml
function ai_is_king_in_check_simple(color) {
    var king = noone;
    with (King_Obj) {
        if (piece_type == color) {
            king = id;
            break;
        }
    }
    
    if (king == noone) return true;
    
    // Check if any enemy piece attacks king
    with (Chess_Piece_Obj) {
        if (piece_type != color) {
            for (var i = 0; i < array_length(valid_moves); i++) {
                var move = valid_moves[i];
                var attack_x = x + move[0] * Board_Manager.tile_size;
                var attack_y = y + move[1] * Board_Manager.tile_size;
                
                if (point_distance(attack_x, attack_y, king.x, king.y) < Board_Manager.tile_size / 2) {
                    return true;
                }
            }
        }
    }
    
    return false;
}
```

**✅ Logic is sound** but relies on `valid_moves` being up-to-date.

**⚠️ Issue:** Sliding pieces (Bishop/Rook/Queen) use dynamic valid_moves that update each step. If we call this mid-turn or before pieces recalculate, it might miss attacks.

### Checkmate Detection

**Current:** `ai_is_checkmate(color)` exists but unused.

**Logic should be:**
1. King is in check
2. No legal moves exist that escape check

### Stalemate Detection

**Current:** `ai_is_stalemate(color)` exists but unused.

**Logic should be:**
1. King is NOT in check
2. No legal moves exist

## Audit Checklist

### Piece Movement
- [ ] Pawn: Forward 1/2 squares ✅
- [ ] Pawn: Diagonal capture ✅
- [ ] Knight: L-shape ✅
- [ ] Bishop: Diagonal rays - VERIFY
- [ ] Rook: Orthogonal rays - VERIFY
- [ ] Queen: All 8 directions - VERIFY
- [ ] King: 1 square any direction ✅

### Special Rules
- [ ] En passant: Target set correctly ✅
- [ ] En passant: Capture works - VERIFY
- [ ] En passant: Clears after opponent move - VERIFY
- [ ] Castling: Path clear check ✅
- [ ] Castling: Not in check - MISSING ❌
- [ ] Castling: Not through check - MISSING ❌
- [ ] Castling: Rook/King haven't moved ✅
- [ ] Promotion: Auto-queen works ✅

### Game State
- [ ] Check detection works ✅
- [ ] Checkmate detection - NOT USED
- [ ] Stalemate detection - NOT USED
- [ ] Turn switching correct ✅

## Required Fixes

### Fix 1: Castling Through Check
**File:** `objects/King_Obj/Step_0.gml`

Add check validation before adding castle moves:

```gml
// After pathClear check, add:
if (pathClear) {
    // Check 1: King not currently in check
    var king_in_check = false;
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type != other.piece_type) {
            for (var m = 0; m < array_length(valid_moves); m++) {
                var vv = valid_moves[m];
                var ax = x + vv[0] * Board_Manager.tile_size;
                var ay = y + vv[1] * Board_Manager.tile_size;
                if (point_distance(ax, ay, other.x, other.y) < Board_Manager.tile_size * 0.5) {
                    king_in_check = true;
                    break;
                }
            }
        }
        if (king_in_check) break;
    }
    
    if (king_in_check) continue; // Can't castle out of check
    
    // Check 2: Path squares not attacked
    var path_attacked = false;
    for (var step = 1; step <= 2; step++) {
        var check_x = x + step * dir * Board_Manager.tile_size;
        
        with (Chess_Piece_Obj) {
            if (instance_exists(id) && piece_type != other.piece_type) {
                for (var m = 0; m < array_length(valid_moves); m++) {
                    var vv = valid_moves[m];
                    var ax = x + vv[0] * Board_Manager.tile_size;
                    var ay = y + vv[1] * Board_Manager.tile_size;
                    if (point_distance(ax, ay, check_x, other.y) < Board_Manager.tile_size * 0.5) {
                        path_attacked = true;
                        break;
                    }
                }
            }
            if (path_attacked) break;
        }
        if (path_attacked) break;
    }
    
    if (path_attacked) continue; // Can't castle through check
    
    // Castle is legal
    array_push(castle_moves, [castle_dx, 0, "castle", rook.id]);
}
```

### Fix 2: En Passant Clearing
**File:** `objects/Chess_Piece_Obj/Step_0.gml`

En passant target should clear when the opponent makes any move. Currently it's cleared in the `pending_normal_move` block, but verify it clears at turn end:

```gml
// In pending_normal_move block, after checking for pawn two-square:
if (piece_id != "pawn" || abs(original_turn_y - y) != Board_Manager.tile_size * 2) {
    // This was NOT a two-square pawn move, clear en passant
    Game_Manager.en_passant_target_x = -1;
    Game_Manager.en_passant_target_y = -1;
    Game_Manager.en_passant_pawn = noone;
}
```

**Verify:** This logic exists and works correctly.

### Fix 3: CRITICAL - Sliding Pieces Only Calculate Moves When Selected!

**MAJOR BUG FOUND!**

In `Bishop_Obj/Step_0.gml`, `Rook_Obj/Step_0.gml`, `Queen_Obj/Step_0.gml`:

```gml
valid_moves = [];
if (Game_Manager.selected_piece == self) {
    // ... calculate moves ...
}
```

**Problem:** Sliding pieces ONLY populate `valid_moves` when they are the selected piece!

**Impact:**
1. `ai_is_king_in_check_simple()` iterates over ALL enemy pieces and checks their `valid_moves`
2. If a Bishop/Rook/Queen is not selected, its `valid_moves` is EMPTY
3. **CHECK DETECTION IS BROKEN FOR SLIDING PIECES!**
4. AI won't see check from Queen/Rook/Bishop attacks
5. Player won't be warned about check from these pieces

**Fix:** Remove the selection check. Sliding pieces should ALWAYS calculate their moves:

```gml
// Bishop_Obj Step (also Rook and Queen)
if instance_exists(Board_Manager) {
    tile_size = Board_Manager.tile_size;
}

valid_moves = [];
// REMOVED: if (Game_Manager.selected_piece == self) {

// Check each direction
for (var dir = 0; dir < array_length(direction_moves); dir++) {
    var dx = direction_moves[dir][0];
    var dy = direction_moves[dir][1];
    
    for (var dist = 1; dist <= max_distance; dist++) {
        var check_x = x + (dx * dist * Board_Manager.tile_size);
        var check_y = y + (dy * dist * Board_Manager.tile_size);
        
        var tile = instance_place(check_x, check_y, Tile_Obj);
        if (!tile) break;
        
        var piece = instance_place(check_x, check_y, Chess_Piece_Obj);
        
        array_push(valid_moves, [dx * dist, dy * dist]);
        
        if (piece) break;
        
        if (tile.tile_type == 1) {
            if (!instance_position(check_x+tile_size/4, check_y+tile_size/4, Bridge_Obj)) {
                break;
            }
        }
    }
}

// REMOVED: closing brace for selection check

event_inherited();
```

**Note on Performance:** This may have minor performance impact since all sliding pieces will recalculate every frame. If needed, optimize later with dirty-flag system.

## Testing Plan

### Manual Tests

1. **Pawn movement**
   - Move pawn forward 1 square ✓
   - Move pawn forward 2 squares from start ✓
   - Pawn can't move 2 squares after first move ✓
   - Pawn captures diagonally ✓
   - Pawn can't capture forward ✓

2. **Knight movement**
   - Knight moves in L-shape ✓
   - Knight jumps over pieces ✓

3. **Sliding pieces**
   - Bishop moves diagonally
   - Bishop stops at edge
   - Bishop stops at friendly piece
   - Bishop captures enemy piece
   - Rook moves orthogonally (same tests)
   - Queen moves all directions (same tests)

4. **King**
   - King moves 1 square
   - King can't move into check (if enforced)

5. **Castling**
   - Kingside castle works
   - Queenside castle works
   - Can't castle after king moves
   - Can't castle after rook moves
   - Can't castle through pieces
   - Can't castle in check (AFTER FIX)
   - Can't castle through check (AFTER FIX)

6. **En passant**
   - Pawn can capture en passant
   - En passant only valid for one turn
   - Captured pawn is removed

7. **Promotion**
   - Pawn reaching back rank becomes queen

8. **Check**
   - AI responds to check
   - Player notified of check (visual?)

## Priority Fixes Summary

| Priority | Issue | File(s) | Effort |
|----------|-------|---------|--------|
| 🔴 CRITICAL | Sliding pieces only calculate moves when selected | Bishop_Obj, Rook_Obj, Queen_Obj Step_0.gml | Easy |
| 🟡 HIGH | Castling through check not validated | King_Obj Step_0.gml | Medium |
| 🟢 LOW | Promotion auto-queens (no choice) | Pawn_Obj Step_0.gml | Optional |

The critical bug means **check detection is broken for 5 out of 6 piece types** (Bishop, Rook, Queen, and by extension any discovered check). This should be fixed IMMEDIATELY before any AI work.

## Success Criteria

- [ ] **CRITICAL: Sliding pieces calculate valid_moves always** (not just when selected)
- [ ] All piece movements verified correct
- [ ] Castling fully legal (including check validation)
- [ ] En passant works correctly
- [ ] Promotion works
- [ ] No illegal moves possible
- [ ] Check/checkmate properly detected and handled
