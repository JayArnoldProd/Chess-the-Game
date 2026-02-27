# Chess-the-Game — Game Mechanics Documentation

**Last Updated:** 2026-02-27

---

## Overview

Chess-the-Game follows standard chess rules with world-specific mechanics that modify gameplay. Each world introduces hazards or bonuses that affect both player and AI equally.

---

## Standard Chess Movement

### Piece Movement Patterns

| Piece | Movement | Special Rules |
|-------|----------|---------------|
| **Pawn** | Forward 1 square (2 from start), capture diagonally | En passant, promotion |
| **Knight** | L-shape (2+1), jumps over pieces | No sliding |
| **Bishop** | Diagonal any distance | Blocked by pieces |
| **Rook** | Horizontal/vertical any distance | Blocked by pieces, castling |
| **Queen** | Diagonal + horizontal/vertical | Blocked by pieces |
| **King** | 1 square any direction | Castling, cannot move into check |

### Movement Implementation

```gml
// Pawn_Obj/Step_0.gml - White pawn moves
valid_moves = [];
// Forward move (only if empty)
if (instance_position(x, y - tile_size, Chess_Piece_Obj) == noone) {
    array_push(valid_moves, [0, -1]);
    // Double move from starting position
    if (!has_moved && instance_position(x, y - 2*tile_size, Chess_Piece_Obj) == noone) {
        array_push(valid_moves, [0, -2]);
    }
}
// Diagonal captures (only if enemy piece present)
var diagLeft = instance_position(x - tile_size, y - tile_size, Chess_Piece_Obj);
if (diagLeft != noone && diagLeft.piece_type != 0) {
    array_push(valid_moves, [-1, -1]);
}
```

### Sliding Pieces (Bishop, Rook, Queen)

Sliding pieces calculate valid moves by ray-casting in each direction until blocked:

```gml
// Rook_Obj/Step_0.gml
for (var dir = 0; dir < array_length(direction_moves); dir++) {
    var dx = direction_moves[dir][0];  // e.g., [0,-1] for up
    var dy = direction_moves[dir][1];
    
    for (var dist = 1; dist <= 7; dist++) {
        var check_x = x + (dx * dist * tile_size);
        var check_y = y + (dy * dist * tile_size);
        
        var tile = instance_place(check_x, check_y, Tile_Obj);
        if (!tile) break;  // Off board
        
        array_push(valid_moves, [dx * dist, dy * dist]);
        
        var piece = instance_place(check_x, check_y, Chess_Piece_Obj);
        if (piece) break;  // Blocked by piece
        
        // Water stops sliding (unless bridge)
        if (tile.tile_type == 1) {
            if (!instance_position(check_x, check_y, Bridge_Obj)) break;
        }
    }
}
```

---

## En Passant

### Rules
- A pawn that advances 2 squares on its first move can be captured "in passing"
- The capture must happen immediately on the next turn
- The capturing pawn moves diagonally to the square the enemy pawn passed through

### Implementation

**Recording vulnerability (`Chess_Piece_Obj/Step_0.gml`):**
```gml
if (piece_id == "pawn" && abs(original_turn_y - y) == tile_size * 2) {
    Game_Manager.en_passant_target_x = x;
    Game_Manager.en_passant_target_y = (original_turn_y + y) / 2;  // Square passed through
    Game_Manager.en_passant_pawn = self;
}
```

**Adding en passant moves (`Pawn_Obj/Step_0.gml`):**
```gml
if (Game_Manager.en_passant_target_x != -1) {
    if (abs(x - Game_Manager.en_passant_target_x) == tile_size &&
        (y - Game_Manager.en_passant_target_y) == tile_size) {
        var dx = (Game_Manager.en_passant_target_x - x) / tile_size;
        var dy = (Game_Manager.en_passant_target_y - y) / tile_size;
        array_push(valid_moves, [dx, dy, "en_passant"]);
    }
}
```

**Executing capture (`Chess_Piece_Obj/Step_0.gml`):**
```gml
if (piece_id == "pawn" && pending_en_passant) {
    if (instance_exists(Game_Manager.en_passant_pawn)) {
        instance_destroy(Game_Manager.en_passant_pawn);
        audio_play_sound_on(audio_emitter, Piece_Capture_SFX, 0, false);
    }
}
```

---

## Castling

### Rules
- King and rook must not have moved
- No pieces between king and rook
- King cannot castle out of, through, or into check
- King moves 2 squares toward rook; rook jumps to other side

### Implementation (`King_Obj/Step_0.gml`)

```gml
// Check if king is in check (cannot castle out of check)
var king_in_check = ai_is_king_in_check_simple(piece_type);
if (king_in_check) {
    castle_moves = [];  // Cannot castle while in check
} else {
    // Find eligible rooks
    with (Rook_Obj) {
        if (piece_type == other.piece_type && !has_moved && !other.has_moved) {
            // Check path is clear
            var pathClear = true;
            // ... (check each square between)
            
            // Check path not attacked
            var path_attacked = false;
            for (var step = 1; step <= 2; step++) {
                var check_x = x + step * dir * tile_size;
                // Check if any enemy piece attacks this square
            }
            
            if (pathClear && !path_attacked) {
                array_push(castle_moves, [2 * dir, 0, "castle", rook.id]);
            }
        }
    }
}
```

### Visual Indicator
Castling moves appear as **blue overlays** on the target square (2 squares from king).

---

## Pawn Promotion

### Current Implementation
When a pawn reaches the opposite end of the board, it automatically promotes to a Queen:

```gml
// Pawn_Obj/Step_0.gml
// White pawn at top row
if (y == Top_Row.y) {
    var temp = piece_type;
    instance_change(Queen_Obj, 1);
    piece_type = temp;  // Preserve color
}
```

### Known Limitation
Currently no piece choice is offered. Standard chess allows promoting to Queen, Rook, Bishop, or Knight.

---

## Check and Checkmate

### Check Detection

The `move_leaves_king_in_check()` function simulates a move and checks if the player's king would be attacked:

```gml
// 1. Simulate the move (temporarily move piece)
piece.x = target_x;
piece.y = target_y;

// 2. Find king position
var king_x, king_y;
with (King_Obj) {
    if (piece_type == my_color) {
        king_x = x; king_y = y;
    }
}

// 3. Check if any enemy piece attacks the king
// (Uses dynamic calculation, not cached valid_moves)
with (Chess_Piece_Obj) {
    if (piece_type == enemy_color) {
        // Calculate if this piece can reach the king
    }
}

// 4. Restore original positions
```

### Check Indicators

**King visual (`King_Obj/Draw_0.gml`):**
```gml
var am_in_check = ai_is_king_in_check_simple(piece_type);
if (am_in_check) {
    var pulse = 0.5 + 0.3 * sin(current_time / 200);
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_red, pulse);
}
```

**Screen warning (`Game_Manager/Draw_64.gml`):**
```gml
if (!game_over && turn == 0 && ai_is_king_in_check_simple(0)) {
    draw_text_transformed(gui_w/2, 20, "CHECK!", 2, 2, 0);
}
```

### Move Filtering

Illegal moves (that would leave king in check) are:
1. Not shown as green overlays
2. Not marked as `valid_move` on tiles
3. Blocked if player attempts them

### Game Over

Currently triggered by king capture (not true checkmate position):

```gml
// King_Obj/Destroy_0.gml
Game_Manager.game_over = true;
Game_Manager.game_over_message = (piece_type == 0) ? "Black Wins!" : "White Wins!";
```

---

## World Mechanics

### Stepping Stones (Ruined Overworld)

**Mechanic:** Landing on a stepping stone grants a 2-phase bonus move.

**Phase 1 — 8-Directional Movement:**
- Piece can move 1 square in any of 8 directions
- Must move to an empty square (no captures)
- Stepping stone moves with the piece

**Phase 2 — Normal Movement:**
- Piece makes its normal move
- Stepping stone returns to original position
- Turn ends after this move

**Implementation:**
```gml
// Chess_Piece_Obj/Step_0.gml
if (stepping_chain == 0 && piece_type == 0) {  // Player pieces only auto-detect
    var stone = instance_position(x, y, Stepping_Stone_Obj);
    if (stone != noone) {
        stepping_chain = 2;  // Phase 1 pending
        stepping_stone_instance = stone;
        stone_original_x = stone.x;
        stone_original_y = stone.y;
    }
}

// Override valid_moves during phase 1
if (stepping_chain == 2) {
    valid_moves = [];
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx != 0 || dy != 0) {
                array_push(valid_moves, [dx, dy]);
            }
        }
    }
}
```

---

### Water and Bridges (Pirate Seas)

**Water Tiles (`tile_type = 1`):**
- Pieces that land on water without a bridge are destroyed (drowned)
- Sliding pieces cannot slide through water

**Bridges:**
- Allow safe crossing of water tiles
- Placed at fixed positions in the room

**Implementation:**
```gml
// Tile_Obj/Mouse_7.gml
if (tile_type == 1) {  // Water
    var has_bridge = instance_position(x + tile_size/4, y + tile_size/4, Bridge_Obj);
    if (!has_bridge) {
        piece.destroy_pending = true;
        piece.destroy_target_x = x;
        piece.destroy_target_y = y;
        piece.destroy_tile_type = 1;  // For drowning sound
    }
}
```

**Sliding through water (`Rook_Obj/Step_0.gml`):**
```gml
if (tile.tile_type == 1) {
    if (!instance_position(check_x + tile_size/4, check_y + tile_size/4, Bridge_Obj)) {
        break;  // Cannot slide through water
    }
}
```

---

### Conveyor Belts (Fear Factory)

**Mechanic:** Conveyor belts shift all pieces on them by 1 tile each turn change.

**Properties:**
- `right_direction = true` → pieces move right
- `right_direction = false` → pieces move left
- Belt spans 6 tiles
- Pieces pushed off the belt edge are destroyed (if void/off-board)

**Turn Change Animation (`Factory_Belt_Obj/Step_0.gml`):**
```gml
if (Game_Manager.turn != last_turn && !animating) {
    // Start animation
    animating = true;
    target_position = right_direction ? (position - 1) : (position + 1);
}

if (animating) {
    // Move pieces incrementally
    var piece_delta = right_direction ? -tile_size * belt_speed : tile_size * belt_speed;
    with (Chess_Piece_Obj) {
        if (on_belt) x -= piece_delta;
    }
}
```

**AI Awareness:**
- AI waits for belt animation to complete before searching
- AI penalizes positions on belt edges (danger of falling off)
- AI simulates belt movement in virtual board during search

---

### Void Tiles (Fear Factory, Void Dimension)

**Mechanic:** Pieces that land on void tiles are immediately destroyed.

**Tile Type:** `tile_type = -1`

**Implementation:**
```gml
// Tile_Obj/Mouse_7.gml
if (tile_type == -1) {
    piece.destroy_pending = true;
    piece.destroy_target_x = x;
    piece.destroy_target_y = y;
}
```

**Visual:** Void tiles typically display as empty/black spaces or trash cans (Fear Factory).

---

### Lava Tiles (Volcanic Wasteland)

**Mechanic:** Treated identically to void tiles — pieces are destroyed on contact.

**AI Treatment:** Same as void tiles in `ai_apply_lava_effect()`.

---

### Random Spawns (Twisted Carnival)

**Mechanic:** Question mark tiles can spawn random pawns during gameplay.

**AI Evaluation:** Cannot predict spawns, but AI favors:
- Central board control (more options when pawns spawn)
- Keeping pieces near friendly pieces (safety in numbers)

---

### Reduced Board (Void Dimension)

**Mechanic:** The board is only 6 columns wide instead of 8.

**Army Changes:**
```gml
// Player_Army_Manager/Create_0.gml
if (room == Void_Dimension) {
    army_width = 6;
    top_row = [Pawn_Obj, Pawn_Obj, Pawn_Obj, Pawn_Obj, Pawn_Obj, Pawn_Obj];
    bottom_row = [Knight_Obj, Bishop_Obj, Queen_Obj, King_Obj, Bishop_Obj, Rook_Obj];
}
```

---

## Level Navigation

**Left Arrow Key:** Previous level (wraps to last)
**Right Arrow Key:** Next level (wraps to first)

```gml
// Game_Manager/KeyPress_37.gml (Left)
if (room == room_first) {
    room_goto(room_last);
} else {
    room_goto_previous();
}

// Game_Manager/KeyPress_39.gml (Right)
if (room == room_last) {
    room_goto(room_first);
} else {
    room_goto_next();
}
```

---

## UI Controls

### In-Game Controls

| Control | Action |
|---------|--------|
| **Left Click** | Select piece / Move to tile |
| **Left/Right Arrows** | Navigate worlds |
| **R Key** | Restart current level |
| **F1 Key** | Toggle settings menu |
| **F2 Key** | Toggle AI debug display |
| **ESC Key** | Close settings menu |

### Settings Menu

Opened via gear icon (top-right) or F1:

- **AI Difficulty:** 5 levels (Beginner → Grandmaster)
- **Master Volume:** Mute/unmute toggle
- **Current World:** Displays room name
- **AI Think Time:** Shows search time limit

---

## Animation System

### Movement Animation

All piece movement is animated using `easeInOutQuad`:

```gml
// Chess_Piece_Obj/Step_0.gml
if (is_moving) {
    move_progress += 1 / move_duration;  // duration = 30 frames
    if (move_progress >= 1) {
        is_moving = false;
        x = move_target_x;
        y = move_target_y;
    } else {
        var t = easeInOutQuad(move_progress);
        x = lerp(move_start_x, move_target_x, t);
        y = lerp(move_start_y, move_target_y, t);
    }
}
```

### Knight Animation

Knights use a 2-phase L-shaped animation:

```gml
if (move_animation_type == "knight") {
    if (move_progress < 0.5) {
        // First half: move vertically
        y = lerp(move_start_y, move_target_y, t);
        x = move_start_x;
    } else {
        // Second half: move horizontally
        y = move_target_y;
        x = lerp(move_start_x, move_target_x, t);
    }
}
```

### Sound Effects

| Action | Sound |
|--------|-------|
| Piece selected | `Piece_Selection_SFX` |
| Piece lands | `Piece_Landing_SFX` |
| Piece captures | `Piece_Capture_SFX` |
| Piece drowns | `Piece_Drowning_SFX` |
| Stepping stone move | `Stone_Slide1_SFX`, `Stone_Slide2_SFX` |
| Lands on stone | `Piece_StoneLanding_SFX` |
| Conveyor belt | `Conveyer_SFX_1/2/3` |
