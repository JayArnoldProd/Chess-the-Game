# Task Plan: Enemy & Boss System Implementation

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Design Spec:** `context/design-docs/enemy-boss-system-spec.md`

---

## Overview

This task plan covers the complete implementation of the Enemy & Boss System as specified in the design document. The system introduces:

1. **Enemies** — Standalone hostile units on the board with HP, knockback, and independent turn actions
2. **Bosses** — AI chess opponents with special "cheat" abilities that break normal chess rules

## PRP Dependency Graph

```
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                     ENEMY SYSTEM (PRP-008 to 016)                │
                    └─────────────────────────────────────────────────────────────────┘
                                                   │
                    ┌──────────────────────────────┴──────────────────────────────┐
                    │                                                              │
                    ▼                                                              │
             ┌─────────────┐                                                       │
             │  PRP-008    │  ◄─── FOUNDATION: Enemy Data Architecture             │
             │  Enemy Data │       (structs, data-driven definitions,              │
             │  Architecture│       instance state tracking)                        │
             └──────┬──────┘                                                       │
                    │                                                              │
        ┌───────────┼───────────┬───────────────────────────────┐                 │
        │           │           │                               │                 │
        ▼           ▼           ▼                               ▼                 │
 ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         ┌─────────────┐         │
 │  PRP-009    │ │  PRP-014    │ │  PRP-017    │         │  PRP-015    │         │
 │  Spawning   │ │  HP &       │ │  Boss       │         │  Multi-Tile │         │
 │  System     │ │  Knockback  │ │  Framework  │         │  Pieces     │         │
 └──────┬──────┘ └──────┬──────┘ └──────┬──────┘         └──────┬──────┘         │
        │               │               │                       │                 │
        ▼               │               │                       │                 │
 ┌─────────────┐        │               │                       │                 │
 │  PRP-010    │ ◄──────┘               │                       │                 │
 │  Turn       │                        │                       │                 │
 │  System     │                        │                       │                 │
 └──────┬──────┘                        │                       │                 │
        │                               │                       │                 │
        ├───────────────┐               │                       │                 │
        │               │               │                       │                 │
        ▼               ▼               │                       │                 │
 ┌─────────────┐ ┌─────────────┐        │                       │                 │
 │  PRP-011    │ │  PRP-012    │        │                       │                 │
 │  Movement   │ │  Melee      │        │                       │                 │
 │  System     │ │  Attack     │        │                       │                 │
 └──────┬──────┘ └──────┬──────┘        │                       │                 │
        │               │               │                       │                 │
        │               ▼               │                       │                 │
        │        ┌─────────────┐        │                       │                 │
        │        │  PRP-013    │        │                       │                 │
        │        │  Ranged     │        │                       │                 │
        │        │  Attack     │        │                       │                 │
        │        └──────┬──────┘        │                       │                 │
        │               │               │                       │                 │
        └───────────────┴───────────────┴───────────────────────┘                 │
                                        │                                         │
                                        ▼                                         │
                                 ┌─────────────┐                                  │
                                 │  PRP-016    │ ◄─────────────────────────────────┘
                                 │  Integration│   (Depends on ALL enemy PRPs)
                                 │  Test       │
                                 └─────────────┘
                                        
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                     BOSS SYSTEM (PRP-017 to 021)                 │
                    └─────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
                                            ┌─────────────┐
                                            │  PRP-017    │  ◄─── FOUNDATION
                                            │  Boss       │       (shared with enemies)
                                            │  Framework  │
                                            └──────┬──────┘
                                                   │
                    ┌──────────────────────────────┼──────────────────────────────┐
                    │                              │                              │
                    ▼                              ▼                              ▼
             ┌─────────────┐               ┌─────────────┐               ┌─────────────┐
             │  PRP-018    │               │  PRP-019    │               │  PRP-020    │
             │  Boss 1:    │               │  Boss 2:    │               │  Boss 3:    │
             │  King's Son │               │  Queen      │               │  Jester     │
             └─────────────┘               └─────────────┘               └─────────────┘
                                                   │
                                                   ▼
                                            ┌─────────────┐
                                            │  PRP-021    │  ◄─── FINAL BOSS
                                            │  Boss 4:    │       (most complex)
                                            │  The King   │
                                            └─────────────┘
```

---

## PRP Summary Table

| PRP | Name | Priority | Dependencies | Est. Complexity |
|-----|------|----------|--------------|-----------------|
| **008** | Enemy Data Architecture | HIGH | None | Medium |
| **009** | Enemy Spawning System | HIGH | 008 | Low |
| **010** | Enemy Turn System | HIGH | 008, 009 | Medium |
| **011** | Enemy Movement System | HIGH | 010 | Medium |
| **012** | Enemy Attack (Melee) | HIGH | 010, 011 | High |
| **013** | Enemy Attack (Ranged) | MEDIUM | 012 | Medium |
| **014** | Enemy HP & Knockback | HIGH | 008 | Medium |
| **015** | Multi-Tile Piece Support | LOW | 008, 014 | High |
| **016** | Integration Test | HIGH | 008-015 | Low |
| **017** | Boss Framework | HIGH | 008 | Medium |
| **018** | Boss 1: King's Son | MEDIUM | 017 | Medium |
| **019** | Boss 2: Queen | MEDIUM | 017 | High |
| **020** | Boss 3: Jester | MEDIUM | 017 | High |
| **021** | Boss 4: The King | LOW | 017 | Very High |

---

## Implementation Order

### Phase 1: Enemy Core (PRPs 008, 009, 010)
Build the foundation for enemies: data structures, spawning, and turn integration.

**Deliverables:**
- Enemy_Obj parent object with data-driven properties
- Enemy_Manager singleton
- Spawn system with configurable rules
- Turn order: Player → Enemies → Player

### Phase 2: Enemy Behavior (PRPs 011, 012, 013, 014)
Implement movement, attacks, HP, and knockback.

**Deliverables:**
- Movement toward closest player piece
- Melee attack with 1-turn warning highlights
- Ranged attack without movement
- HP tracking with knockback on damage
- Death animation (shake red, fade)

### Phase 3: Advanced Features (PRP 015)
Optional multi-tile piece support.

**Deliverables:**
- Pieces occupying multiple tiles
- Hitbox detection across all tiles
- Knockback for large pieces

### Phase 4: Enemy Integration (PRP 016)
End-to-end test with placeholder enemy.

**Deliverables:**
- Placeholder enemy on Ruined Overworld
- Full turn cycle verification
- Level scaling (1-3 enemies based on level)

### Phase 5: Boss Framework (PRP 017)
Build the boss system architecture.

**Deliverables:**
- Boss data structure
- Turn order: Player → Boss Move → Boss Cheats
- "Bad move" frequency system
- Integration with existing AI

### Phase 6: Individual Bosses (PRPs 018-021)
Implement each boss with unique cheats.

**Deliverables:**
- 4 unique bosses with special abilities
- Progressive difficulty scaling
- Final boss with 2 phases

#### PRP-018: Boss 1 — King's Son (Overworld)
- Medium AI + bad move every 3 turns
- **"Go! My Horses!"** — Knights pulse yellow, revive from capture, teleport to home squares
  - 5-turn duration with only knights moving
  - Cancellation on knight capture + boss loses turn
- **"Wah Wah Wah!"** — Board shakes, removes 1 random white + 1 random black piece
  - Cannot remove queens/kings
  - Removing a horse disables future horse cheats

#### PRP-019: Boss 2 — Queen (Pirate Seas)
- Low AI + bad move every 5 turns
- **"Cut the Slack!"** — Sacrifice 3 pawns → spawn 1 queen at middle position
  - Repeats every 3 turns if pawns available
  - Selection: left → right → middle
- **"Enchant!"** — Purple shield on piece; 3×3 explosion when captured
  - Damages BOTH sides, kings immune
  - Turn 2: enchant first Cut queen; every 3 turns: random non-pawn

#### PRP-020: Boss 3 — Jester (Volcanic Wasteland)
- Medium AI + bad move every 4 turns
- **"Rookie Mistake!"** — Pre-match: shift back rank down, fill row 0 with 8 rooks
  - Every 3 turns: all 8 rooks slam down simultaneously
  - Captures white pieces in path, stops at black pieces
- **"Mind Control!"** — Move random player piece with depth-1 AI
  - Player can't see which piece beforehand
  - Does NOT skip player's turn

#### PRP-021: Boss 4 — The King (Final Boss)
- Strong AI (highest difficulty, no bad moves)
- **Phase 1: "Look Who's on Top Now!"**
  - Pre-match: all pawns → kings (visual transformation)
  - Track extra kings vs original king
  - Phase transition when only original king remains
- **Phase 2: "Back Off!"**
  - Board reset, pawn revival
  - Every 2 turns, random ability:
    - "I'm Invulnerable Now!" — king untargetable 3 turns
    - "Oh, I'll Pity You..." — give pawn to player
    - "That Move Doesn't Count!" — undo player's last move + captures
    - "I... I Don't Know..." — boss loses turn

---

## Technical Architecture

### New Objects

| Object | Parent | Purpose |
|--------|--------|---------|
| `Enemy_Manager` | — | Singleton: enemy spawning, turn processing |
| `Enemy_Obj` | — | Parent for all enemies |
| `Enemy_Placeholder_Obj` | Enemy_Obj | Test enemy (2HP, king-style movement) |
| `Boss_Manager` | — | Singleton: boss cheat execution |
| `Attack_Highlight_Obj` | — | Red warning tile overlay |

### New Scripts

| Script | Purpose |
|--------|---------|
| `enemy_data_get_definition()` | Get enemy type definition by ID |
| `enemy_spawn_for_level()` | Spawn enemies based on level config |
| `enemy_process_turn()` | Process single enemy's turn |
| `enemy_find_target()` | Find closest player piece |
| `enemy_calculate_knockback()` | Calculate knockback direction/position |
| `boss_definitions_init()` | Initialize boss type definitions (data-driven) |
| `boss_get_definition()` | Get boss definition by ID |
| `boss_get_level_config()` | Get boss config for current room |
| `boss_execute_cheat()` | Dispatch and execute boss cheat abilities |
| `boss_bad_move_injection()` | Post-search filter for suboptimal moves |
| `boss_resync_board_state()` | Re-sync AI virtual board after cheats |
| `boss_cheat_go_my_horses()` | King's Son knight cheat |
| `boss_cheat_wah_wah_wah()` | King's Son board shake cheat |
| `boss_cheat_cut_the_slack()` | Queen pawn sacrifice cheat |
| `boss_cheat_enchant()` | Queen piece explosion shield |
| `boss_trigger_explosion()` | 3×3 explosion damage system |
| `boss_cheat_rookie_mistake()` | Jester board setup + rook slam |
| `boss_cheat_mind_control()` | Jester forced player move |
| `boss_cheat_look_whos_on_top()` | The King Phase 1 (pawns→kings) |
| `boss_cheat_back_off()` | The King Phase 2 transition |
| `boss_cheat_invulnerable()` | The King invulnerability ability |
| `boss_cheat_pity()` | The King give-pawn ability |
| `boss_cheat_undo()` | The King move-undo ability |
| `boss_cheat_lose_turn()` | The King skip-turn ability |
| `boss_king_record_move()` | Track player moves for undo mechanic |

### Collision Rules — Stepping Stone Interactions
*(Added 2026-02-27, per Jas ruling)*

- `Stepping_Stone_Obj` = **immovable wall** for enemies and knockback
- Enemies cannot occupy stepping stone tiles (`enemy_is_move_valid` checks for `Stepping_Stone_Obj`)
- Enemy knockback into stepping stone = cancelled (`enemy_is_knockback_valid` checks for `Stepping_Stone_Obj`)
- Player piece on stepping stone that attacks a surviving enemy → piece pushed off stone in opposite direction of attack

### Data Structures

**Enemy Definition (data-driven):**
```gml
{
    enemy_id: "placeholder",
    display_name: "Placeholder Enemy",
    hp: 2,
    hitbox_width: 1,
    hitbox_height: 1,
    movement_type: "king",           // king, knight, rook, etc.
    attack_type: "melee",            // melee, ranged
    attack_site_width: 3,            // Detection zone
    attack_site_height: 3,
    attack_size_width: 1,            // Strike zone
    attack_size_height: 1,
    spawn_rules: {
        default_ranks: [6, 7, 8],    // Rows 6-8 (0-indexed: rows 5-7)
        lane_lock: -1,               // -1 = any, 0-7 = specific column
        exact_tile: noone            // {col, row} or noone
    },
    sprite: spr_enemy_placeholder,
    death_sprite: spr_enemy_death
}
```

**Enemy Instance State:**
```gml
{
    current_hp: 2,
    state: "idle",                   // idle, scanning, highlighting, attacking, moving
    target_piece: noone,
    highlighted_tiles: [],
    turns_until_attack: 0
}
```

**Boss Definition:**
```gml
{
    boss_id: "kings_son",
    display_name: "King's Son",
    ai_difficulty: 3,                // 1-5 scale
    bad_move_frequency: 3,           // Every N turns
    cheats: ["go_my_horses", "wah_wah_wah"],
    cheat_cooldowns: { "go_my_horses": 0, "wah_wah_wah": 0 },
    portrait_sprite: spr_boss_kings_son
}
```

---

## Integration Points

### Game_Manager Changes
- New turn value: `2` = enemy turn (between player and AI)
- Track enemy phase in turn cycle
- Boss level detection flag

### Turn Order (Enemy Levels)
```
Player (turn=0) → Enemies (turn=2) → AI (turn=1) → repeat
```

### Turn Order (Boss Levels)
```
Player (turn=0) → Boss AI Move (turn=1) → Boss Cheats (turn=3) → repeat
```

### Level Configuration
- Room variable `room_has_enemies` (bool)
- Room variable `room_is_boss_level` (bool)
- Room variable `room_boss_id` (string)
- Room variable `enemy_count_min`, `enemy_count_max` (int)

---

## Risk Areas

| Risk | Mitigation |
|------|------------|
| Turn system complexity | Add detailed state machine logging |
| Enemy-enemy collision edge cases | Comprehensive unit tests |
| Knockback into hazards (water/void) | Reuse existing hazard detection from AI |
| Boss cheat timing conflicts | Clear state machine with queued actions |
| Multi-tile piece complexity | Defer to later if time-constrained |
| Performance with many enemies | Cap at 5 enemies per level |
| Stepping stone + knockback interaction complexity | Stepping stones are immovable walls for ALL collision; piece bounce-back off stones needs dedicated handling (2026-02-27 ruling) |

---

## Success Metrics

1. **Enemy Turn Cycle** — Player can complete full turn cycle with 1+ enemies
2. **Attack Warning** — Red highlight appears 1 turn before attack
3. **Knockback** — Enemy moves 1 tile when damaged (not killed)
4. **Death Animation** — Enemy shakes red and fades on HP=0
5. **Boss Cheats** — Each boss executes unique cheats per design spec
6. **Game Stability** — No crashes during 10 consecutive games with enemies/bosses

---

## Files Changed Summary

### Objects Created
- `objects/Enemy_Manager/`
- `objects/Enemy_Obj/`
- `objects/Enemy_Placeholder_Obj/`
- `objects/Boss_Manager/`
- `objects/Attack_Highlight_Obj/`

### Scripts Created
- `scripts/enemy_*.gml` (10-15 scripts)
- `scripts/boss_*.gml` (25+ scripts):
  - `boss_definitions.gml`, `boss_get_definition.gml`, `boss_get_level_config.gml`
  - `boss_execute_cheat.gml`, `boss_bad_move_injection.gml`, `boss_resync_board_state.gml`
  - `boss_cheat_go_my_horses.gml`, `boss_cheat_wah_wah_wah.gml` (King's Son)
  - `boss_cheat_cut_the_slack.gml`, `boss_cheat_enchant.gml`, `boss_trigger_explosion.gml` (Queen)
  - `boss_cheat_rookie_mistake.gml`, `boss_jester_rook_slam.gml`, `boss_cheat_mind_control.gml` (Jester)
  - `boss_cheat_look_whos_on_top.gml`, `boss_cheat_back_off.gml` (The King - Phase)
  - `boss_cheat_invulnerable.gml`, `boss_cheat_pity.gml`, `boss_cheat_undo.gml`, `boss_cheat_lose_turn.gml` (The King - Abilities)
  - `boss_kings_son_utils.gml`, `boss_queen_utils.gml`, `boss_jester_utils.gml`, `boss_king_utils.gml`

### Objects Modified
- `objects/Game_Manager/` — Turn system expansion
- `objects/Chess_Piece_Obj/` — Enemy damage integration
- `objects/Tile_Obj/` — Attack highlight rendering

### Rooms Modified
- All existing rooms — Add enemy/boss configuration variables

---

## Timeline Estimate

| Phase | PRPs | Estimated Time |
|-------|------|----------------|
| Enemy Core | 008-010 | 2-3 sessions |
| Enemy Behavior | 011-014 | 3-4 sessions |
| Multi-Tile | 015 | 1-2 sessions |
| Integration | 016 | 1 session |
| Boss Framework | 017 | 1-2 sessions |
| Boss 1-4 | 018-021 | 4-6 sessions |
| **Total** | **008-021** | **12-18 sessions** |

---

## Notes

- All code examples use modern GML (structs, method(), etc.)
- Avoid reserved variable names: `score`, `board`, `health`, `depth`, `sign`
- Use `_` prefix for local variables that might conflict
- Test with Igor CLI after each PRP: see `clawd/memory/gamemaker-igor-setup.md`
