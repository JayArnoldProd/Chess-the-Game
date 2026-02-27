# Chess-the-Game — Architecture Overview

**Last Updated:** 2026-02-27

---

## High-Level Architecture

Chess-the-Game is a chess variant with world-specific mechanics built in GameMaker Studio 2. The architecture follows a manager-based pattern with inheritance for pieces and tiles.

```
┌─────────────────────────────────────────────────────────────────────┐
│                           GAME FLOW                                  │
├─────────────────────────────────────────────────────────────────────┤
│  Room Load → Managers Init → Armies Spawn → Turn Loop → Game Over   │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Game_Manager │  │  AI_Manager  │  │Board_Manager │  │Object_Manager│
│              │  │              │  │              │  │              │
│ - Turn state │  │ - AI search  │  │ - Tile size  │  │ - Grid origin│
│ - Selection  │  │ - State mach │  │ - World theme│  │ - Object spawn│
│ - En passant │  │ - Difficulty │  │ - Colors     │  │ - Locations  │
│ - Game over  │  │ - Step stones│  │              │  │              │
│ - Settings   │  │ - Zobrist TT │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
        │                │                │                │
        └────────────────┴────────────────┴────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
            ┌──────────────┐           ┌──────────────┐
            │Chess_Piece_Obj│           │   Tile_Obj   │
            │   (Parent)    │           │   (Parent)   │
            ├──────────────┤           ├──────────────┤
            │ - piece_type │           │ - tile_type  │
            │ - piece_id   │           │ - valid_move │
            │ - valid_moves│           │ - grid_x/y   │
            │ - is_moving  │           │              │
            │ - stepping   │           │              │
            └──────────────┘           └──────────────┘
                    │                           │
        ┌───────────┼───────────┐       ┌───────┼───────┐
        ▼           ▼           ▼       ▼       ▼       ▼
    ┌────────┐ ┌────────┐ ┌────────┐ ┌─────┐ ┌─────┐ ┌─────┐
    │Pawn_Obj│ │Knight  │ │King_Obj│ │Black│ │White│ │Void │
    │        │ │_Obj    │ │        │ │Tile │ │Tile │ │Tile │
    └────────┘ └────────┘ └────────┘ └─────┘ └─────┘ └─────┘
```

---

## Object Hierarchy

### Core Managers (Persistent, one per room)

| Object | Purpose | Key Variables |
|--------|---------|---------------|
| `Game_Manager` | Turn system, selection, en passant, game over, settings | `turn`, `selected_piece`, `game_over`, `settings_open` |
| `AI_Manager` | AI search engine, stepping stone handler | `ai_state`, `ai_time_limit`, `ai_stepping_phase` |
| `Board_Manager` | Board dimensions, world theming | `tile_size` (24px), `white_color`, `black_color` |
| `Object_Manager` | Grid coordinate system, object spawning | `topleft_x`, `topleft_y`, `object_locations` |
| `Audio_Manager` | Sound system (ambient, SFX) | — |

### Piece Hierarchy

All pieces inherit from `Chess_Piece_Obj`:

```
Chess_Piece_Obj (Parent)
├── Pawn_Obj      — Forward moves, diagonal captures, en passant, promotion
├── Knight_Obj    — L-shaped jumps, no sliding
├── Bishop_Obj    — Diagonal sliding
├── Rook_Obj      — Orthogonal sliding
├── Queen_Obj     — Diagonal + orthogonal sliding
└── King_Obj      — Single square, castling, check indicator
```

### Tile Hierarchy

All tiles inherit from `Tile_Obj`:

```
Tile_Obj (Parent)
├── Tile_White    — Standard white tile (tile_type=0)
├── Tile_Black    — Standard black tile (tile_type=0)
├── Tile_Void     — Impassable/destructive (tile_type=-1)
└── Tile_Black_Question — Carnival random spawn tile
```

### World Mechanic Objects

| Object | World | Purpose |
|--------|-------|---------|
| `Stepping_Stone_Obj` | Ruined Overworld | Grants 2-phase bonus movement |
| `Bridge_Obj` | Pirate Seas | Allows crossing water safely |
| `Bridge_Row` | Pirate Seas | Spawns row of bridges |
| `Factory_Belt_Obj` | Fear Factory | Conveyor belt (moves pieces each turn) |
| `Factory_Dropper_Obj` | Fear Factory | Void/trash can at belt edges |
| `Background_Obj` | Twisted Carnival | Animated background |
| `Foreground_Obj` | All | Foreground decorations |

---

## Turn System

### Turn Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        TURN CYCLE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ Player   │    │ Piece    │    │  Turn    │    │   AI     │  │
│  │ Selects  │───▶│ Moves    │───▶│ Switches │───▶│  Thinks  │  │
│  │  Piece   │    │(animate) │    │ (turn=1) │    │          │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       ▲                                               │         │
│       │              ┌──────────┐    ┌──────────┐    │         │
│       │              │   Turn   │    │   AI     │    │         │
│       └──────────────│ Switches │◀───│ Executes │◀───┘         │
│                      │ (turn=0) │    │  Move    │              │
│                      └──────────┘    └──────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Turn Variable (`Game_Manager.turn`)

| Value | Meaning |
|-------|---------|
| `0` | Player's turn (white) |
| `1` | AI's turn (black) |

### Turn Switch Mechanism

1. **Player moves:** `Tile_Obj/Mouse_7.gml` sets `piece.pending_turn_switch = 1`
2. **Animation completes:** `Chess_Piece_Obj/Step_0.gml` processes `pending_turn_switch`
3. **Turn flips:** `Game_Manager.turn = pending_turn_switch`
4. **AI activates:** `AI_Manager/Step_0.gml` detects `turn == 1` and begins search

---

## AI State Machine

The AI uses a multi-frame state machine to prevent game freezes during search:

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI STATE MACHINE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────┐   turn=1   ┌───────────┐   moves    ┌───────────┐    │
│  │ IDLE │───────────▶│ PREPARING │──────────▶│ SEARCHING │    │
│  └──────┘            └───────────┘            └───────────┘    │
│      ▲                     │                       │            │
│      │                     │ 0 moves               │ time up    │
│      │                     ▼                       ▼            │
│      │               ┌───────────┐           ┌───────────┐     │
│      │               │ CHECKMATE │           │ EXECUTING │     │
│      │               │ /STALEMATE│           └───────────┘     │
│      │               └───────────┘                 │            │
│      │                                             ▼            │
│      │                                    ┌────────────────┐   │
│      └────────────────────────────────────│WAITING_TURN_  │   │
│                      turn=0               │   SWITCH      │   │
│                                           └────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### State Details

| State | Purpose | Duration |
|-------|---------|----------|
| `idle` | Wait for AI turn, wait for animations/belts | Until turn=1 + no animations |
| `preparing` | Build virtual world, generate root moves | Single frame |
| `searching` | Process root moves within 14ms frame budget | Until time limit or all moves searched |
| `executing` | Execute best move with animation | Single frame |
| `waiting_turn_switch` | Wait for turn to actually switch | Until turn=0 |

---

## Room/Level Structure

### Worlds (Rooms)

| Room | World | Mechanics |
|------|-------|-----------|
| `Ruined_Overworld` | World 1 | Stepping stones (2-phase movement) |
| `Pirate_Seas` | World 2 | Water tiles, bridges |
| `Fear_Factory` | World 3 | Conveyor belts, void/trash tiles |
| `Volcanic_Wasteland` | World 4 | Lava hazards |
| `Volcanic_Wasteland_Boss` | World 4 Boss | Boss encounter (planned) |
| `Twisted_Carnival` | World 5 | Random pawn spawns, animated background |
| `Void_Dimension` | World 6 | Void tiles, reduced board (6 columns) |

### Navigation

- **Left Arrow:** Go to previous room (wraps to last)
- **Right Arrow:** Go to next room (wraps to first)

### Room Initialization Order

1. Room loads, objects placed from room editor
2. `Game_Manager` creates (initializes turn, spawns other managers)
3. `Board_Manager` creates cursor
4. `Object_Manager` spawns stepping stones/bridges based on room
5. `Player_Army_Manager` spawns white pieces (bottom)
6. `Enemy_Army_Manager` spawns black pieces (top)
7. `AI_Manager` initializes Zobrist tables and TT

---

## World Mechanics Integration

### How World Mechanics Flow Into Game Logic

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORLD MECHANICS FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐         ┌────────────┐         ┌────────────┐  │
│  │ Room Loads │────────▶│ai_get_     │────────▶│Mechanics   │  │
│  │            │         │current_    │         │Array       │  │
│  │            │         │world()     │         │            │  │
│  └────────────┘         └────────────┘         └────────────┘  │
│                                                       │         │
│                                                       ▼         │
│  ┌────────────────────────────────────────────────────────────┐│
│  │                   ai_build_virtual_world()                 ││
│  │  • Scans all Chess_Piece_Obj → board[8][8]                 ││
│  │  • Scans all Tile_Obj → tiles[8][8] (types: 0, 1, -1)      ││
│  │  • Collects stepping stones, bridges, conveyors            ││
│  └────────────────────────────────────────────────────────────┘│
│                              │                                  │
│              ┌───────────────┼───────────────┐                 │
│              ▼               ▼               ▼                 │
│       ┌──────────┐    ┌──────────┐    ┌──────────┐            │
│       │Move Gen  │    │Search    │    │Evaluation│            │
│       │(filters  │    │(applies  │    │(adds     │            │
│       │ unsafe)  │    │ effects) │    │ bonuses) │            │
│       └──────────┘    └──────────┘    └──────────┘            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Tile Types

| Value | Type | Effect |
|-------|------|--------|
| `0` | Normal | Standard chess tile |
| `1` | Water | Destroys pieces (unless Bridge present) |
| `-1` | Void | Destroys any piece that lands on it |

---

## Input Flow

### Player Input Chain

```
Mouse Click on Piece
        │
        ▼
Chess_Piece_Obj/Mouse_4.gml
  • Check: game_over? settings_open? ai_stepping_phase?
  • Check: Is it this piece's color's turn?
  • Set: Game_Manager.selected_piece = self
        │
        ▼
Chess_Piece_Obj/Draw_0.gml
  • Calculate valid_moves for selected piece
  • Check: Would move leave king in check?
  • Draw: Green overlays on legal tiles
  • Set: Tile_Obj.valid_move = true for legal tiles
        │
        ▼
Mouse Release on Tile
        │
        ▼
Tile_Obj/Mouse_7.gml
  • Check: valid_move? selected_piece exists?
  • Check: move_leaves_king_in_check()?
  • Handle: Stepping stones, castling, normal moves
  • Set: piece.pending_turn_switch, piece.is_moving
  • Handle: Water/void destruction
```

---

## File Organization

```
Chess-the-Game/
├── objects/
│   ├── AI_Manager/           # AI engine
│   ├── Audio_Manager/        # Sound system
│   ├── Board_Manager/        # Board config
│   ├── Game_Manager/         # Turn system, UI
│   ├── Object_Manager/       # Grid/spawning
│   ├── Chess_Piece_Obj/      # Base piece (parent)
│   ├── Pawn_Obj/             # Piece types...
│   ├── Knight_Obj/
│   ├── Bishop_Obj/
│   ├── Rook_Obj/
│   ├── Queen_Obj/
│   ├── King_Obj/
│   ├── Tile_Obj/             # Base tile (parent)
│   ├── Tile_Black/
│   ├── Tile_White/
│   ├── Tile_Void/
│   ├── Stepping_Stone_Obj/   # World mechanics...
│   ├── Bridge_Obj/
│   ├── Factory_Belt_Obj/
│   └── ...
├── scripts/
│   ├── ai_*.gml              # AI system (36 scripts)
│   ├── move_leaves_king_in_check.gml
│   ├── easeInOutQuad.gml     # Animation easing
│   └── ...
├── rooms/
│   ├── Ruined_Overworld/
│   ├── Pirate_Seas/
│   ├── Fear_Factory/
│   └── ...
├── sprites/                  # All sprite assets
├── sounds/                   # All audio assets
└── context/                  # Documentation
    ├── ARCHITECTURE.md       # This file
    ├── GAME_MECHANICS.md
    ├── AI_SYSTEM.md
    ├── OBJECTS_REFERENCE.md
    ├── KNOWN_ISSUES.md
    ├── BUILD_GUIDE.md
    ├── RESUME.md
    └── design-docs/
```

---

## Key Architectural Decisions

### 1. Virtual Board for AI Search
The AI never manipulates real game objects during search. It builds a virtual board (2D array of structs) and simulates moves on copies. This prevents visual glitches and allows deep search without side effects.

### 2. Multi-Frame AI
Long AI searches (up to 30 seconds at max difficulty) don't freeze the game. The state machine yields after 14ms each frame, allowing cursor movement, animations, and UI updates to continue.

### 3. Parent-Child Inheritance
All pieces inherit common behavior from `Chess_Piece_Obj` (movement animation, stepping stones, selection). Piece-specific logic (move patterns, promotion) lives in child objects.

### 4. World-Aware Move Generation
The AI filters moves through `ai_is_tile_safe()` before adding them to the search. Water without bridges and void tiles are excluded at move generation time, not just evaluation time.

### 5. Deferred Turn Switch
Turns don't switch instantly on move execution. The piece stores `pending_turn_switch` and processes it after animation completes. This ensures visual consistency and prevents race conditions.
