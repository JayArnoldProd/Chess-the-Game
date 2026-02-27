# Chess-the-Game — Objects Reference

**Last Updated:** 2026-02-27

Quick reference for every object in the game.

---

## Managers

### Game_Manager

**Purpose:** Central game state controller — turns, selection, en passant, game over, settings.

| Variable | Type | Description |
|----------|------|-------------|
| `turn` | int | 0=player (white), 1=AI (black) |
| `selected_piece` | instance | Currently selected piece (or noone) |
| `hovered_piece` | instance | Piece under cursor |
| `en_passant_target_x/y` | real | En passant capture square (-1 if none) |
| `en_passant_pawn` | instance | Pawn vulnerable to en passant |
| `game_over` | bool | Game ended? |
| `game_over_message` | string | Winner text |
| `settings_open` | bool | Settings panel visible? |

**Key Events:**
- `Create_0` — Initialize state, spawn managers
- `Step_0` — Handle settings click detection
- `Draw_64` — Settings panel, gear icon, game over overlay, CHECK text
- `KeyPress_37/39` — Level navigation (left/right arrows)
- `KeyPress_82` — Restart (R key)
- `KeyPress_112` — Toggle settings (F1)
- `KeyPress_27` — Close settings (ESC)

---

### AI_Manager

**Purpose:** AI search engine with multi-frame state machine.

| Variable | Type | Description |
|----------|------|-------------|
| `ai_enabled` | bool | AI active? |
| `ai_state` | string | idle/preparing/searching/executing/waiting_turn_switch |
| `ai_time_limit` | int | Search time in ms |
| `ai_search_moves` | array | Root moves being evaluated |
| `ai_search_index` | int | Current move index |
| `ai_search_best_move` | struct | Best move found |
| `ai_search_best_score` | int | Best score found |
| `ai_search_current_depth` | int | Current iterative deepening depth |
| `ai_stepping_phase` | int | 0=none, 1=phase1, 2=phase2 |
| `ai_stepping_piece` | instance | Piece in stepping stone sequence |
| `piece_values` | ds_map | Material values by piece_id |
| `pawn_table`, `knight_table`, etc. | array[64] | Piece-square tables |

**Key Events:**
- `Create_0` — Initialize state machine, Zobrist, TT, PSTs
- `Step_0` — Main AI loop (state machine)
- `Draw_64` — Debug overlay (F2 toggle)
- `KeyPress_49-53` — Quick difficulty 1-5 (debug)
- `KeyPress_112-123` — Various debug keys

---

### Board_Manager

**Purpose:** Board configuration and world theming.

| Variable | Type | Description |
|----------|------|-------------|
| `tile_size` | int | 24 pixels |
| `white_color` | color | White tile color |
| `black_color` | color | Black tile color |
| `world_id` | int | Current world identifier |
| `special_tile_textures` | array | Per-tile texture overrides |

**Key Events:**
- `Create_0` — Initialize colors, create cursor

---

### Object_Manager

**Purpose:** Grid coordinate system and object spawning.

| Variable | Type | Description |
|----------|------|-------------|
| `topleft_x/y` | real | Board origin (top-left tile position) |
| `tile_size` | int | 24 pixels |
| `object_definitions` | array | Object type mappings |
| `object_locations` | array | Per-room spawn tables |
| `spawned_objects` | bool | Objects already spawned? |

**Key Events:**
- `Create_0` — Find board origin, load spawn tables
- `Step_0` — Spawn objects on first frame

---

### Audio_Manager

**Purpose:** Sound system (ambient, music, SFX).

| Variable | Type | Description |
|----------|------|-------------|
| — | — | (Minimal state) |

**Key Events:**
- `Create_0` — Initialize audio system
- `Step_0` — Update ambient sounds

---

## Chess Pieces

### Chess_Piece_Obj (Parent)

**Purpose:** Base piece with common behavior — movement, animation, stepping stones.

| Variable | Type | Description |
|----------|------|-------------|
| `piece_type` | int | 0=white, 1=black, 2=corrupted |
| `piece_id` | string | pawn/knight/bishop/rook/queen/king |
| `valid_moves` | array | [[dx,dy], ...] relative moves |
| `has_moved` | bool | For castling/pawn double move |
| `is_moving` | bool | Currently animating? |
| `move_start_x/y` | real | Animation start position |
| `move_target_x/y` | real | Animation target position |
| `move_progress` | real | 0.0 to 1.0 |
| `move_duration` | int | Frames (default 30) |
| `move_animation_type` | string | "linear" or "knight" |
| `stepping_chain` | int | 0=none, 2=phase1, 1=phase2 |
| `stepping_stone_instance` | instance | Stone being used |
| `stone_original_x/y` | real | Stone's home position |
| `pending_turn_switch` | int/undefined | Turn to switch to after animation |
| `pending_capture` | instance | Piece to capture after animation |
| `pending_en_passant` | bool | En passant capture pending |
| `destroy_pending` | bool | Piece marked for destruction (water/void) |
| `destroy_tile_type` | int | 1=water (drowning SFX) |
| `landing_sound_pending` | bool | Play landing sound after animation |
| `audio_emitter` | emitter | Spatial audio emitter |

**Key Events:**
- `Create_0` — Initialize all state variables
- `Step_0` — Animation interpolation, stepping stone detection, deferred actions
- `Draw_0` — Sprite, hover overlay, valid move overlays
- `Mouse_4` — Left click selection
- `Mouse_10/11` — Hover enter/exit

---

### Pawn_Obj

**Purpose:** Pawn-specific movement (forward, capture, en passant, promotion).

**Inherits:** Chess_Piece_Obj

**Key Events:**
- `Create_0` — Set `piece_id = "pawn"`
- `Step_0` — Calculate valid_moves (forward, diagonal captures, en passant), handle promotion
- `Draw_0` — (None, uses parent)

**Special Rules:**
- Forward only if empty
- Capture only diagonally
- Double move from starting row (if both squares empty)
- Promotes to Queen at opposite end

---

### Knight_Obj

**Purpose:** Knight L-shaped movement.

**Inherits:** Chess_Piece_Obj

**Default `valid_moves`:** `[[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]]`

**Key Events:**
- `Create_0` — Set piece_id, direction_moves
- `Step_0` — Restore normal moves after stepping stone phase 2

---

### Bishop_Obj

**Purpose:** Diagonal sliding movement.

**Inherits:** Chess_Piece_Obj

**Default `direction_moves`:** `[[-1,-1],[-1,1],[1,-1],[1,1]]`  
**`max_distance`:** 7

**Key Events:**
- `Create_0` — Set piece_id, direction_moves
- `Step_0` — Calculate sliding moves (stops at pieces, water)

---

### Rook_Obj

**Purpose:** Orthogonal sliding movement.

**Inherits:** Chess_Piece_Obj

**Default `direction_moves`:** `[[0,-1],[0,1],[-1,0],[1,0]]`  
**`max_distance`:** 7

**Key Events:**
- `Create_0` — Set piece_id, direction_moves
- `Step_0` — Calculate sliding moves

---

### Queen_Obj

**Purpose:** Combined diagonal + orthogonal sliding.

**Inherits:** Chess_Piece_Obj

**Default `direction_moves`:** All 8 directions  
**`max_distance`:** 7

**Key Events:**
- `Create_0` — Set piece_id, direction_moves
- `Step_0` — Calculate sliding moves

---

### King_Obj

**Purpose:** King movement + castling + check indicator.

**Inherits:** Chess_Piece_Obj

| Variable | Type | Description |
|----------|------|-------------|
| `castle_moves` | array | [[dx, 0, "castle", rook_id], ...] |

**Key Events:**
- `Create_0` — Set piece_id, valid_moves (8 directions)
- `Step_0` — Check castling eligibility
- `Draw_0` — Castle move overlays (blue), check pulse (red)
- `Destroy_0` — Set game_over when captured

---

## Tiles

### Tile_Obj (Parent)

**Purpose:** Base tile with click handling for moves.

| Variable | Type | Description |
|----------|------|-------------|
| `tile_type` | int | 0=normal, 1=water, -1=void |
| `valid_move` | bool | Is this a valid move for selected piece? |
| `white` | bool | White or black tile |
| `grid_x/y` | int | Board coordinates |
| `audio_emitter` | emitter | Spatial audio |

**Key Events:**
- `Create_0` — Initialize state
- `Step_0` — Update appearance
- `Draw_0` — Draw tile sprite
- `Mouse_7` — Handle move execution on left release

---

### Tile_Black / Tile_White

**Purpose:** Standard playable tiles.

**Inherits:** Tile_Obj

**`tile_type`:** 0 (normal)

---

### Tile_Void

**Purpose:** Impassable/destructive tiles.

**Inherits:** Tile_Obj

**`tile_type`:** -1 (void)

---

### Tile_Black_Question

**Purpose:** Carnival random spawn tiles.

**Inherits:** Tile_Obj

---

## World Mechanic Objects

### Stepping_Stone_Obj

**Purpose:** Grants 2-phase bonus movement when landed on.

| Variable | Type | Description |
|----------|------|-------------|
| `is_moving` | bool | Currently animating? |
| `move_start_x/y` | real | Animation start |
| `move_target_x/y` | real | Animation target |
| `move_progress` | real | 0.0 to 1.0 |
| `move_duration` | int | Frames |

**Key Events:**
- `Create_0` — Initialize animation state
- `Step_0` — Animation interpolation

---

### Bridge_Obj

**Purpose:** Allows safe crossing of water tiles.

| Variable | Type | Description |
|----------|------|-------------|
| `bridge_number` | int | Bridge identifier |
| `depth` | int | 1 (above tiles, below pieces) |

**Key Events:**
- `Create_0` — Initialize

---

### Bridge_Row

**Purpose:** Spawns a row of bridges.

---

### Factory_Belt_Obj

**Purpose:** Conveyor belt that shifts pieces each turn.

| Variable | Type | Description |
|----------|------|-------------|
| `right_direction` | bool | true=right, false=left |
| `position` | int | Current belt position (0-5) |
| `target_position` | int | Animation target position |
| `animating` | bool | Belt currently moving? |
| `belt_speed` | real | Animation speed (0.02) |
| `last_turn` | int | Last turn value (for change detection) |
| `audio_emitter` | emitter | Conveyor sound |

**Key Events:**
- `Create_0` — Initialize belt state
- `Step_0` — Turn change detection, animation, piece movement
- `Draw_0` — Belt texture scrolling

---

### Factory_Dropper_Obj

**Purpose:** Void/trash can at conveyor belt edges.

**Behavior:** Pieces pushed into this are destroyed.

---

## Army Managers

### Player_Army_Manager

**Purpose:** Spawns white pieces at game start.

| Variable | Type | Description |
|----------|------|-------------|
| `top_row` | array | Piece types for row 2 |
| `bottom_row` | array | Piece types for row 1 |
| `army_width` | int | 8 (or 6 for Void Dimension) |

**Key Events:**
- `Create_0` — Spawn pieces based on room

---

### Enemy_Army_Manager

**Purpose:** Spawns black pieces at game start.

| Variable | Type | Description |
|----------|------|-------------|
| `top_row` | array | Piece types for row 7 |
| `bottom_row` | array | Piece types for row 8 |
| `army_width` | int | 8 (or 6 for Void Dimension) |

**Key Events:**
- `Create_0` — Spawn pieces, set `piece_type = 1`

---

## Visual Objects

### Cursor_Obj

**Purpose:** Custom cursor display.

**Key Events:**
- `Create_0` — Initialize
- `Step_0` — Follow mouse
- `Draw_0` — Draw cursor sprite

---

### Background_Obj

**Purpose:** Animated background (Twisted Carnival).

**Key Events:**
- `Create_0` — Initialize animation
- `Step_0` — Update animation

---

### Foreground_Obj

**Purpose:** Foreground decorations.

**Key Events:**
- `Create_0` — Initialize
- `Step_0` — Update
- `Draw_0` — Draw foreground elements

---

## Object Depth Ordering

| Depth | Objects |
|-------|---------|
| -2 | Moving pieces |
| -1 | Stationary pieces |
| 0 | Stepping stones |
| 1 | Bridges |
| 5 | Tiles |
| 10+ | Background |

Lower depth = drawn on top.

---

## Object Relationships

```
┌────────────────────────────────────────────────────────────────┐
│                       MANAGER LAYER                            │
│  Game_Manager ←→ AI_Manager ←→ Board_Manager ←→ Object_Manager │
└────────────────────────────────────────────────────────────────┘
           │              │              │
           ▼              ▼              ▼
┌────────────────┐ ┌─────────────┐ ┌─────────────┐
│ Chess_Piece_Obj│ │   Tile_Obj  │ │World Objects│
│    (Parent)    │ │   (Parent)  │ │             │
├────────────────┤ ├─────────────┤ ├─────────────┤
│ Pawn_Obj       │ │ Tile_Black  │ │Stepping_    │
│ Knight_Obj     │ │ Tile_White  │ │Stone_Obj    │
│ Bishop_Obj     │ │ Tile_Void   │ │Bridge_Obj   │
│ Rook_Obj       │ │             │ │Factory_Belt │
│ Queen_Obj      │ │             │ │_Obj         │
│ King_Obj       │ │             │ │             │
└────────────────┘ └─────────────┘ └─────────────┘
```

---

## Common Patterns

### Movement Animation

All moving objects (pieces, stepping stones) use the same pattern:

```gml
if (is_moving) {
    move_progress += 1 / move_duration;
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

### Tile Detection

Finding tile at a position:
```gml
var tile = instance_position(x + tile_size/4, y + tile_size/4, Tile_Obj);
```

### Piece Detection

Finding piece at a position:
```gml
var piece = instance_position(x, y, Chess_Piece_Obj);
// or
var piece = instance_place(x, y, Chess_Piece_Obj);
```

### Checking Object Existence

```gml
if (instance_exists(obj)) {
    // Safe to access obj.variable
}
```
