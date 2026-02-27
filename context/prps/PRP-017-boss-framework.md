# PRP-017: Boss Framework & AI Adaptation

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-008 (Enemy Data Architecture — shared patterns)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Bosses are chess AI opponents with special "cheat" abilities that break normal rules. Unlike enemies (standalone hostile units), bosses control the black pieces in a standard chess match. We need:

1. **Boss data structure** — AI difficulty, cheat list, bad move frequency, cheat cooldowns
2. **Boss turn order** — Player → Boss Chess Move → Boss Cheats → back to Player
3. **AI Adaptation layer** — "Bad move" injection, variable difficulty per boss
4. **Board state re-sync** — Update virtual board after cheats mutate the board
5. **Cheat scheduling** — Which cheats fire on which turns, cooldowns, conditions
6. **Boss Manager** — Orchestrates boss behavior during boss levels

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BOSS SYSTEM ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐     ┌─────────────────────┐                        │
│  │  BOSS_DEFINITIONS   │     │    Boss_Manager     │                        │
│  │  (Global Data)      │────▶│    (Singleton)      │                        │
│  │                     │     │                     │                        │
│  │  - kings_son        │     │  - current_boss     │                        │
│  │  - queen            │     │  - boss_turn_count  │                        │
│  │  - jester           │     │  - cheat_queue[]    │                        │
│  │  - the_king         │     │  - execute_cheats() │                        │
│  └─────────────────────┘     └──────────┬──────────┘                        │
│                                         │                                    │
│                                         │ controls                           │
│                                         ▼                                    │
│                       ┌─────────────────────────────────┐                   │
│                       │        AI_Manager               │                   │
│                       │   (Modified for Boss Support)   │                   │
│                       │                                 │                   │
│                       │  + boss_difficulty_override     │                   │
│                       │  + bad_move_injection()         │                   │
│                       │  + resync_board_state()         │                   │
│                       └─────────────────────────────────┘                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     BOSS TURN ORDER (turn value 3)                      ││
│  │                                                                          ││
│  │   Player (0) ──▶ Boss AI Move (1) ──▶ Boss Cheats (3) ──▶ Player (0)   ││
│  │                                                                          ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Turn Order: Boss Levels vs Enemy Levels

```
┌───────────────────────────────────────────────────────────────────┐
│  ENEMY LEVELS (PRP-010)          │  BOSS LEVELS (this PRP)        │
├───────────────────────────────────┼─────────────────────────────────┤
│  turn=0: Player moves            │  turn=0: Player moves          │
│  turn=2: Enemies act (all)       │  turn=1: Boss AI makes move    │
│  turn=1: AI moves (if any)       │  turn=3: Boss cheats execute   │
│  Back to turn=0                  │  Back to turn=0                │
├───────────────────────────────────┼─────────────────────────────────┤
│  Has standalone enemies          │  NO standalone enemies          │
│  May/may not have AI opponent    │  Always has AI opponent         │
│  No special abilities            │  Boss has cheat abilities       │
└───────────────────────────────────┴─────────────────────────────────┘
```

---

## All Needed Context

### Documentation & References

```yaml
- file: context/design-docs/enemy-boss-system-spec.md
  why: Official design spec — boss behaviors, cheats, turn order

- file: context/AI_SYSTEM.md
  why: Current AI architecture, virtual board, state machine

- file: context/ARCHITECTURE.md
  why: Turn system, manager patterns

- file: context/prps/PRP-008-enemy-data-architecture.md
  why: Pattern for data-driven definitions
```

### Files to Reference (don't modify heavily)

```yaml
- path: objects/AI_Manager/Create_0.gml
  why: Current AI initialization, difficulty system

- path: objects/AI_Manager/Step_0.gml
  why: AI state machine, move execution

- path: scripts/ai_execute_move_animated/ai_execute_move_animated.gml
  why: Move execution with animations

- path: scripts/ai_build_virtual_world/ai_build_virtual_world.gml
  why: Virtual board construction (needs re-sync after cheats)
```

### Files to Create

```yaml
- path: scripts/boss_definitions/boss_definitions.gml
  purpose: All boss type definitions (data-driven)

- path: scripts/boss_get_definition/boss_get_definition.gml
  purpose: Lookup boss definition by ID

- path: scripts/boss_get_level_config/boss_get_level_config.gml
  purpose: Get boss config for current room

- path: scripts/boss_execute_cheat/boss_execute_cheat.gml
  purpose: Execute a specific cheat by ID

- path: scripts/boss_bad_move_injection/boss_bad_move_injection.gml
  purpose: Post-search filter for intentionally suboptimal moves

- path: scripts/boss_resync_board_state/boss_resync_board_state.gml
  purpose: Re-sync virtual board after cheats mutate the board

- path: objects/Boss_Manager/Boss_Manager.yy
  purpose: Object definition file

- path: objects/Boss_Manager/Create_0.gml
  purpose: Initialize boss state and load definitions

- path: objects/Boss_Manager/Step_0.gml
  purpose: Boss turn processing, cheat scheduling

- path: objects/Boss_Manager/Draw_64.gml
  purpose: Boss UI (portrait, cheat announcements)
```

### Files to Modify

```yaml
- path: objects/AI_Manager/Create_0.gml
  changes: Add boss difficulty override variables

- path: objects/AI_Manager/Step_0.gml
  changes: Integrate bad move injection, boss turn flow

- path: objects/Game_Manager/Create_0.gml
  changes: Spawn Boss_Manager for boss levels

- path: objects/Game_Manager/Step_0.gml
  changes: Handle turn=3 (boss cheat phase)
```

---

## Implementation Blueprint

### Step 1: Boss Definitions Script

**File:** `scripts/boss_definitions/boss_definitions.gml`

```gml
/// @function boss_definitions_init()
/// @description Initialize all boss type definitions
function boss_definitions_init() {
    // Global map of boss definitions by ID
    global.boss_definitions = ds_map_create();
    
    // === BOSS 1: KING'S SON (Overworld) ===
    var _kings_son = {
        boss_id: "kings_son",
        display_name: "King's Son",
        world: "ruined_overworld",
        
        // === AI DIFFICULTY ===
        ai_difficulty: 3,           // Medium (1-5 scale)
        ai_time_limit: 2000,        // 2 seconds search time
        ai_search_depth_max: 6,     // Cap depth
        
        // === BAD MOVE SYSTEM ===
        bad_move_enabled: true,
        bad_move_frequency: 3,      // Every 3 turns, pick suboptimal move
        bad_move_rank_offset: 2,    // Pick 2nd or 3rd best move instead of best
        
        // === CHEATS ===
        cheats: ["go_my_horses", "wah_wah_wah"],
        cheat_schedule: {
            // go_my_horses: triggers based on conditions (horse captured, etc.)
            // wah_wah_wah: triggers after go_my_horses ends
        },
        cheat_cooldowns: {
            go_my_horses: 0,
            wah_wah_wah: 0
        },
        
        // === VISUALS ===
        portrait_sprite: spr_boss_kings_son,      // Boss portrait
        cheat_announce_sprite: spr_cheat_announce // Speech bubble
    };
    ds_map_add(global.boss_definitions, "kings_son", _kings_son);
    
    // === BOSS 2: QUEEN (Pirate Seas) ===
    var _queen = {
        boss_id: "queen",
        display_name: "The Queen",
        world: "pirate_seas",
        
        ai_difficulty: 2,           // Low
        ai_time_limit: 1000,        // 1 second
        ai_search_depth_max: 4,
        
        bad_move_enabled: true,
        bad_move_frequency: 5,      // Every 5 turns
        bad_move_rank_offset: 3,
        
        cheats: ["cut_the_slack", "enchant"],
        cheat_schedule: {
            cut_the_slack: { first_turn: 1, repeat_interval: 3 },
            enchant: { first_turn: 2, repeat_interval: 3 }
        },
        cheat_cooldowns: {
            cut_the_slack: 0,
            enchant: 0
        },
        
        portrait_sprite: spr_boss_queen,
        cheat_announce_sprite: spr_cheat_announce
    };
    ds_map_add(global.boss_definitions, "queen", _queen);
    
    // === BOSS 3: JESTER (Volcanic Wasteland) ===
    var _jester = {
        boss_id: "jester",
        display_name: "The Jester",
        world: "volcanic_wasteland",
        
        ai_difficulty: 3,           // Medium
        ai_time_limit: 2000,
        ai_search_depth_max: 6,
        
        bad_move_enabled: true,
        bad_move_frequency: 4,      // Every 4 turns
        bad_move_rank_offset: 2,
        
        cheats: ["rookie_mistake", "mind_control"],
        cheat_schedule: {
            rookie_mistake: { first_turn: 0, repeat_interval: 3 }, // 0 = pre-match setup
            mind_control: { first_turn: 3, repeat_interval: 4 }
        },
        cheat_cooldowns: {
            rookie_mistake: 0,
            mind_control: 0
        },
        
        portrait_sprite: spr_boss_jester,
        cheat_announce_sprite: spr_cheat_announce
    };
    ds_map_add(global.boss_definitions, "jester", _jester);
    
    // === BOSS 4: THE KING (Final Boss) ===
    var _the_king = {
        boss_id: "the_king",
        display_name: "The King",
        world: "final",
        
        ai_difficulty: 5,           // Strong (highest)
        ai_time_limit: 10000,       // 10 seconds
        ai_search_depth_max: 12,
        
        bad_move_enabled: false,    // No bad moves — plays optimally
        bad_move_frequency: 0,
        bad_move_rank_offset: 0,
        
        cheats: ["look_whos_on_top", "back_off"],
        cheat_schedule: {
            look_whos_on_top: { first_turn: 0, is_phase: true },  // Phase 1
            back_off: { phase_trigger: true }                      // Phase 2
        },
        cheat_cooldowns: {},
        
        // Phase tracking
        has_phases: true,
        current_phase: 1,
        phase_transition_condition: "only_original_king",
        
        portrait_sprite: spr_boss_the_king,
        cheat_announce_sprite: spr_cheat_announce
    };
    ds_map_add(global.boss_definitions, "the_king", _the_king);
    
    show_debug_message("Boss definitions initialized: " + 
        string(ds_map_size(global.boss_definitions)) + " bosses");
}

/// @function boss_definitions_cleanup()
function boss_definitions_cleanup() {
    if (ds_exists(global.boss_definitions, ds_type_map)) {
        ds_map_destroy(global.boss_definitions);
    }
}
```

### Step 2: Boss Get Definition Script

**File:** `scripts/boss_get_definition/boss_get_definition.gml`

```gml
/// @function boss_get_definition(_boss_id)
/// @param {string} _boss_id The boss type ID (e.g., "kings_son")
/// @returns {struct} Boss definition struct, or undefined if not found
function boss_get_definition(_boss_id) {
    if (!variable_global_exists("boss_definitions") ||
        !ds_exists(global.boss_definitions, ds_type_map)) {
        show_debug_message("ERROR: Boss definitions not initialized!");
        return undefined;
    }
    
    if (!ds_map_exists(global.boss_definitions, _boss_id)) {
        show_debug_message("WARNING: Unknown boss type: " + string(_boss_id));
        return undefined;
    }
    
    return ds_map_find_value(global.boss_definitions, _boss_id);
}
```

### Step 3: Boss Level Config Script

**File:** `scripts/boss_get_level_config/boss_get_level_config.gml`

```gml
/// @function boss_get_level_config()
/// @returns {struct} Boss configuration for current room, or undefined if not a boss level
function boss_get_level_config() {
    var _config = {
        is_boss_level: false,
        boss_id: "",
        boss_def: undefined
    };
    
    switch (room) {
        case Volcanic_Wasteland_Boss:
            // World 4 Boss: The Jester
            _config.is_boss_level = true;
            _config.boss_id = "jester";
            break;
            
        // Future boss rooms would be added here:
        // case Ruined_Overworld_Boss:
        //     _config.is_boss_level = true;
        //     _config.boss_id = "kings_son";
        //     break;
        //
        // case Pirate_Seas_Boss:
        //     _config.is_boss_level = true;
        //     _config.boss_id = "queen";
        //     break;
        //
        // case Final_Boss:
        //     _config.is_boss_level = true;
        //     _config.boss_id = "the_king";
        //     break;
            
        default:
            _config.is_boss_level = false;
            break;
    }
    
    // Load boss definition if this is a boss level
    if (_config.is_boss_level && _config.boss_id != "") {
        _config.boss_def = boss_get_definition(_config.boss_id);
    }
    
    return _config;
}
```

### Step 4: Boss Manager Object

**File:** `objects/Boss_Manager/Create_0.gml`

```gml
/// Boss_Manager Create Event
/// Singleton manager for boss encounters
show_debug_message("Boss_Manager: Initializing...");

// === INITIALIZE BOSS DEFINITIONS ===
if (!variable_global_exists("boss_definitions") ||
    !ds_exists(global.boss_definitions, ds_type_map)) {
    boss_definitions_init();
}

// === LEVEL CONFIGURATION ===
level_config = boss_get_level_config();
is_boss_level = level_config.is_boss_level;
current_boss_id = level_config.boss_id;
current_boss_def = level_config.boss_def;

// === BOSS STATE ===
boss_turn_count = 0;              // Turns since boss fight started
boss_cheat_phase_active = false;  // Is it currently cheat phase (turn=3)?
cheat_queue = [];                 // Cheats scheduled to execute this turn
current_cheat_index = 0;          // Which cheat in queue is executing
cheat_state = "idle";             // idle, announcing, executing, complete

// === CHEAT EXECUTION STATE ===
cheat_animation_timer = 0;
cheat_announcement_text = "";
cheat_announcement_timer = 0;
cheat_announcement_duration = 90; // 1.5 seconds

// === BAD MOVE TRACKING ===
bad_move_counter = 0;             // Counts up to bad_move_frequency

// === PHASE TRACKING (for multi-phase bosses) ===
current_phase = 1;
phase_transition_pending = false;

// === BOSS-SPECIFIC STATE ===
// King's Son
horses_cheat_active = false;
horses_cheat_turns_remaining = 0;
horses_captured_during_cheat = false;

// Queen
enchanted_pieces = [];            // Array of {piece_id, instance}
cut_the_slack_count = 0;          // How many times triggered

// Jester
rook_slam_positions = [];         // Track the 8 rooks
mind_controlled_piece = noone;

// The King
extra_kings = [];                 // Track pawns-turned-kings
invulnerable_turns_remaining = 0;
last_player_move = undefined;     // For undo mechanic

// === APPLY BOSS DIFFICULTY TO AI ===
if (is_boss_level && current_boss_def != undefined) {
    // Override AI settings
    if (instance_exists(AI_Manager)) {
        AI_Manager.boss_mode = true;
        AI_Manager.boss_time_limit = current_boss_def.ai_time_limit;
        AI_Manager.boss_depth_max = current_boss_def.ai_search_depth_max;
        AI_Manager.bad_move_enabled = current_boss_def.bad_move_enabled;
        AI_Manager.bad_move_frequency = current_boss_def.bad_move_frequency;
        AI_Manager.bad_move_rank_offset = current_boss_def.bad_move_rank_offset;
        
        // Apply time limit
        AI_Manager.ai_time_limit = current_boss_def.ai_time_limit;
        
        show_debug_message("Boss_Manager: Applied boss AI settings - " +
            "time=" + string(current_boss_def.ai_time_limit) + "ms, " +
            "bad_move_freq=" + string(current_boss_def.bad_move_frequency));
    }
    
    show_debug_message("Boss_Manager: Boss level detected - " + 
        current_boss_def.display_name);
} else {
    show_debug_message("Boss_Manager: Not a boss level");
}
```

**File:** `objects/Boss_Manager/Step_0.gml`

```gml
/// Boss_Manager Step Event
/// Handles boss turn processing and cheat scheduling

if (!is_boss_level || current_boss_def == undefined) exit;

// === CHEAT PHASE PROCESSING (turn=3) ===
if (Game_Manager.turn == 3) {
    boss_cheat_phase_active = true;
    
    switch (cheat_state) {
        case "idle":
            // Build cheat queue for this turn
            cheat_queue = boss_get_scheduled_cheats(boss_turn_count);
            current_cheat_index = 0;
            
            if (array_length(cheat_queue) > 0) {
                cheat_state = "announcing";
                var _cheat = cheat_queue[0];
                cheat_announcement_text = boss_get_cheat_name(_cheat);
                cheat_announcement_timer = cheat_announcement_duration;
                show_debug_message("Boss: Announcing cheat - " + cheat_announcement_text);
            } else {
                // No cheats this turn — end cheat phase
                cheat_state = "complete";
            }
            break;
            
        case "announcing":
            // Show cheat name announcement
            cheat_announcement_timer--;
            if (cheat_announcement_timer <= 0) {
                cheat_state = "executing";
            }
            break;
            
        case "executing":
            // Execute current cheat
            var _cheat_id = cheat_queue[current_cheat_index];
            var _complete = boss_execute_cheat(_cheat_id);
            
            if (_complete) {
                current_cheat_index++;
                if (current_cheat_index >= array_length(cheat_queue)) {
                    cheat_state = "complete";
                } else {
                    // Announce next cheat
                    cheat_state = "announcing";
                    cheat_announcement_text = boss_get_cheat_name(cheat_queue[current_cheat_index]);
                    cheat_announcement_timer = cheat_announcement_duration;
                }
            }
            break;
            
        case "complete":
            // All cheats executed — end cheat phase
            boss_turn_count++;
            bad_move_counter++;
            cheat_state = "idle";
            boss_cheat_phase_active = false;
            
            // Re-sync board state after cheats may have mutated it
            boss_resync_board_state();
            
            // Return to player turn
            Game_Manager.turn = 0;
            show_debug_message("Boss: Cheat phase complete, turn=" + string(boss_turn_count));
            break;
    }
}

// === MONITOR FOR AI TURN COMPLETION ===
// After AI finishes its move (turn switches from 1), trigger cheat phase
if (Game_Manager.turn == 0 && boss_cheat_phase_active == false) {
    // Check if we just came from AI turn
    if (variable_instance_exists(id, "last_turn") && last_turn == 1) {
        // AI just finished — now do cheat phase
        Game_Manager.turn = 3;
        show_debug_message("Boss: AI move complete, entering cheat phase");
    }
}
last_turn = Game_Manager.turn;

// === TRACK PLAYER MOVES FOR UNDO MECHANIC ===
if (Game_Manager.turn == 0 && !variable_instance_exists(id, "tracking_player_move")) {
    tracking_player_move = true;
    // Will be updated by move execution hooks
}
```

### Step 5: Bad Move Injection Script

**File:** `scripts/boss_bad_move_injection/boss_bad_move_injection.gml`

```gml
/// @function boss_bad_move_injection(_sorted_moves, _scores)
/// @param {array} _sorted_moves Array of moves sorted by score (best first)
/// @param {array} _scores Corresponding scores
/// @returns {struct} The move to play (possibly suboptimal)
/// @description Post-search filter that occasionally picks a lower-ranked move
function boss_bad_move_injection(_sorted_moves, _scores) {
    // Safety check
    if (array_length(_sorted_moves) == 0) {
        return undefined;
    }
    
    // Check if boss mode and bad moves enabled
    if (!instance_exists(Boss_Manager) || 
        !Boss_Manager.is_boss_level ||
        !AI_Manager.bad_move_enabled) {
        // Return best move normally
        return _sorted_moves[0];
    }
    
    var _frequency = AI_Manager.bad_move_frequency;
    var _offset = AI_Manager.bad_move_rank_offset;
    
    // Check if this turn should have a bad move
    if (_frequency <= 0 || Boss_Manager.bad_move_counter < _frequency) {
        // Not time for bad move yet
        return _sorted_moves[0];
    }
    
    // Reset counter
    Boss_Manager.bad_move_counter = 0;
    
    // Pick a suboptimal move
    // _offset = 2 means pick 2nd or 3rd best move
    var _target_index = irandom_range(1, min(_offset, array_length(_sorted_moves) - 1));
    
    // Safety: don't pick a move that loses the queen or king for free
    // (even bad moves shouldn't be suicidal)
    for (var i = _target_index; i < min(_target_index + 3, array_length(_sorted_moves)); i++) {
        var _move = _sorted_moves[i];
        var _score = _scores[i];
        var _best_score = _scores[0];
        
        // Don't pick a move more than 300 centipawns worse than best
        // (roughly a minor piece blunder)
        if (_best_score - _score < 300) {
            show_debug_message("Boss: Making BAD MOVE (rank " + string(i+1) + 
                ", score " + string(_score) + " vs best " + string(_best_score) + ")");
            return _move;
        }
    }
    
    // Couldn't find acceptable bad move — play best
    show_debug_message("Boss: Bad move rejected (all alternatives too bad)");
    return _sorted_moves[0];
}
```

### Step 6: Board State Re-sync Script

**File:** `scripts/boss_resync_board_state/boss_resync_board_state.gml`

```gml
/// @function boss_resync_board_state()
/// @description Re-syncs the AI's virtual board after cheats mutate the real board
function boss_resync_board_state() {
    show_debug_message("Boss: Re-syncing board state after cheats...");
    
    // Clear transposition table (positions are no longer valid)
    if (variable_global_exists("tt_entries")) {
        ai_tt_clear();
    }
    
    // Rebuild Zobrist hash for current position
    // The AI will do this naturally when it starts searching,
    // but we clear the TT to prevent stale entries
    
    // Force AI to rebuild virtual world on next search
    if (instance_exists(AI_Manager)) {
        AI_Manager.ai_search_world_state = undefined;
        AI_Manager.ai_search_board = undefined;
    }
    
    show_debug_message("Boss: Board state re-sync complete (TT cleared)");
}
```

### Step 7: Cheat Execution Framework

**File:** `scripts/boss_execute_cheat/boss_execute_cheat.gml`

```gml
/// @function boss_execute_cheat(_cheat_id)
/// @param {string} _cheat_id The cheat to execute
/// @returns {bool} True if cheat execution is complete, false if still in progress
/// @description Executes a boss cheat ability (dispatches to specific implementations)
function boss_execute_cheat(_cheat_id) {
    switch (_cheat_id) {
        // King's Son cheats
        case "go_my_horses":
            return boss_cheat_go_my_horses();
        case "wah_wah_wah":
            return boss_cheat_wah_wah_wah();
            
        // Queen cheats
        case "cut_the_slack":
            return boss_cheat_cut_the_slack();
        case "enchant":
            return boss_cheat_enchant();
            
        // Jester cheats
        case "rookie_mistake":
            return boss_cheat_rookie_mistake();
        case "mind_control":
            return boss_cheat_mind_control();
            
        // The King cheats
        case "look_whos_on_top":
            return boss_cheat_look_whos_on_top();
        case "back_off":
            return boss_cheat_back_off();
        case "invulnerable":
            return boss_cheat_invulnerable();
        case "pity":
            return boss_cheat_pity();
        case "undo":
            return boss_cheat_undo();
        case "lose_turn":
            return boss_cheat_lose_turn();
            
        default:
            show_debug_message("WARNING: Unknown cheat ID: " + _cheat_id);
            return true;  // Unknown cheat = skip it
    }
}

/// @function boss_get_scheduled_cheats(_turn)
/// @param {real} _turn Current boss turn count
/// @returns {array} Array of cheat IDs to execute this turn
function boss_get_scheduled_cheats(_turn) {
    var _cheats = [];
    var _def = Boss_Manager.current_boss_def;
    
    if (_def == undefined) return _cheats;
    
    var _schedule = _def.cheat_schedule;
    
    // Check each cheat's schedule
    var _cheat_list = _def.cheats;
    for (var i = 0; i < array_length(_cheat_list); i++) {
        var _cheat_id = _cheat_list[i];
        
        // Get schedule for this cheat
        if (!variable_struct_exists(_schedule, _cheat_id)) continue;
        
        var _cheat_sched = _schedule[$ _cheat_id];
        
        // Check if it's time for this cheat
        var _first = variable_struct_exists(_cheat_sched, "first_turn") ? 
                     _cheat_sched.first_turn : 1;
        var _interval = variable_struct_exists(_cheat_sched, "repeat_interval") ?
                        _cheat_sched.repeat_interval : 0;
        
        if (_turn == _first) {
            array_push(_cheats, _cheat_id);
        } else if (_interval > 0 && _turn > _first) {
            if ((_turn - _first) % _interval == 0) {
                array_push(_cheats, _cheat_id);
            }
        }
    }
    
    return _cheats;
}

/// @function boss_get_cheat_name(_cheat_id)
/// @param {string} _cheat_id The cheat ID
/// @returns {string} Display name for the cheat
function boss_get_cheat_name(_cheat_id) {
    switch (_cheat_id) {
        case "go_my_horses": return "Go! My Horses!";
        case "wah_wah_wah": return "Wah Wah Wah!";
        case "cut_the_slack": return "Cut the Slack!";
        case "enchant": return "Enchant!";
        case "rookie_mistake": return "Rookie Mistake!";
        case "mind_control": return "Mind Control!";
        case "look_whos_on_top": return "Look Who's on Top Now!";
        case "back_off": return "Back Off!";
        case "invulnerable": return "I'm Invulnerable Now!";
        case "pity": return "Oh, I'll Pity You...";
        case "undo": return "That Move Doesn't Count!";
        case "lose_turn": return "I... I Don't Know...";
        default: return _cheat_id;
    }
}
```

### Step 8: AI Manager Modifications

**Add to `objects/AI_Manager/Create_0.gml`:**

```gml
// === BOSS MODE VARIABLES ===
boss_mode = false;
boss_time_limit = 2000;
boss_depth_max = 6;
bad_move_enabled = false;
bad_move_frequency = 0;
bad_move_rank_offset = 0;

// Track sorted moves and scores for bad move injection
ai_sorted_moves = [];
ai_sorted_scores = [];
```

**Modify `objects/AI_Manager/Step_0.gml` - in `ai_finalize_search()`:**

```gml
/// In ai_finalize_search(), add before setting ai_state = "executing":

// === BOSS BAD MOVE INJECTION ===
if (boss_mode && bad_move_enabled && array_length(ai_sorted_moves) > 1) {
    ai_search_best_move = boss_bad_move_injection(ai_sorted_moves, ai_sorted_scores);
}
```

### Step 9: Game Manager Turn Flow Update

**Add to `objects/Game_Manager/Step_0.gml`:**

```gml
// === BOSS CHEAT PHASE (turn=3) ===
// Handled by Boss_Manager — just ensure we don't process other logic
if (turn == 3 && instance_exists(Boss_Manager)) {
    // Boss_Manager handles cheat execution
    exit;
}
```

### Step 10: Boss Manager Draw (UI)

**File:** `objects/Boss_Manager/Draw_64.gml`

```gml
/// Boss_Manager Draw GUI Event
/// Boss portrait and cheat announcements

if (!is_boss_level || current_boss_def == undefined) exit;

// === BOSS PORTRAIT (top-right corner) ===
var _portrait_x = display_get_gui_width() - 80;
var _portrait_y = 20;
var _portrait_size = 64;

// Draw portrait background
draw_set_color(c_black);
draw_rectangle(_portrait_x - 2, _portrait_y - 2, 
               _portrait_x + _portrait_size + 2, _portrait_y + _portrait_size + 2, false);

// Draw portrait sprite (if exists)
if (sprite_exists(current_boss_def.portrait_sprite)) {
    draw_sprite_stretched(current_boss_def.portrait_sprite, 0,
                         _portrait_x, _portrait_y, _portrait_size, _portrait_size);
} else {
    // Placeholder
    draw_set_color(c_purple);
    draw_rectangle(_portrait_x, _portrait_y,
                  _portrait_x + _portrait_size, _portrait_y + _portrait_size, false);
}

// Draw boss name
draw_set_font(-1);
draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(_portrait_x + _portrait_size, _portrait_y + _portrait_size + 5,
          current_boss_def.display_name);

// === CHEAT ANNOUNCEMENT (center screen) ===
if (cheat_state == "announcing" && cheat_announcement_text != "") {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 3;
    
    // Pulse effect
    var _scale = 1 + sin(current_time / 100) * 0.1;
    
    // Background
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    var _text_width = string_width(cheat_announcement_text) * _scale + 40;
    var _text_height = string_height(cheat_announcement_text) * _scale + 20;
    draw_rectangle(_cx - _text_width/2, _cy - _text_height/2,
                  _cx + _text_width/2, _cy + _text_height/2, false);
    draw_set_alpha(1);
    
    // Text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text_transformed(_cx, _cy, cheat_announcement_text, _scale, _scale, 0);
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
```

---

## Known Gotchas

### GML Reserved Names
Avoid these as variable names:
- `score` — Built-in game variable
- `depth` — Instance variable (we use it intentionally for draw order)
- `phase` — Safe to use, but be clear about context

### Turn Value 3
The new turn value (3 = boss cheat phase) must be handled everywhere that checks `turn`:
- Game_Manager doesn't process player input
- AI_Manager doesn't start thinking
- Animations can still play

### Board State Mutation
Cheats that add/remove/move pieces MUST call `boss_resync_board_state()` after completing. Otherwise:
- Zobrist hash will be stale
- Transposition table will return wrong values
- AI will make illegal moves

### Multi-Phase Bosses (The King)
Phase transitions require:
1. Detect transition condition
2. Set `phase_transition_pending = true`
3. Play transition animation
4. Reset relevant state
5. Update `current_phase`

---

## Success Criteria

- [ ] `boss_definitions_init()` runs without errors
- [ ] `boss_get_definition("kings_son")` returns correct definition
- [ ] `boss_get_level_config()` detects boss levels correctly
- [ ] Boss_Manager spawns on boss levels, not on regular levels
- [ ] AI uses boss difficulty settings (time limit, depth)
- [ ] Bad move injection picks suboptimal moves at correct frequency
- [ ] Turn order: Player (0) → Boss AI (1) → Cheats (3) → Player (0)
- [ ] Cheat announcements display on screen
- [ ] Board state re-syncs after cheats
- [ ] Code compiles without errors

---

## Validation

### Manual Test

1. Navigate to `Volcanic_Wasteland_Boss` room
2. Verify Boss_Manager spawns (debug message)
3. Verify AI plays with boss difficulty settings
4. Make moves and observe turn flow
5. Check for cheat phase (turn=3) after AI moves

### Debug Overlay

Add to `Boss_Manager/Draw_64.gml`:
```gml
// DEBUG INFO
if (global.ai_debug_visible) {
    draw_set_halign(fa_left);
    draw_text(10, display_get_gui_height() - 60, 
              "Boss Turn: " + string(boss_turn_count));
    draw_text(10, display_get_gui_height() - 45,
              "Bad Move Counter: " + string(bad_move_counter) + 
              "/" + string(AI_Manager.bad_move_frequency));
    draw_text(10, display_get_gui_height() - 30,
              "Cheat State: " + cheat_state);
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-018** — King's Son boss (Go! My Horses!, Wah Wah Wah!)
2. **PRP-019** — Queen boss (Cut the Slack!, Enchant!)
3. **PRP-020** — Jester boss (Rookie Mistake!, Mind Control!)
4. **PRP-021** — The King final boss (two phases)
