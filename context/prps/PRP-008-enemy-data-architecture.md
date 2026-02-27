# PRP-008: Enemy Data Architecture

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** None  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

We need a data-driven architecture for enemies that allows:
1. New enemy types to be added as data definitions, not new code
2. Each enemy instance to track its own state (HP, current action, targets)
3. Clean integration with the existing turn system
4. Separation of enemy logic from chess piece logic

The design spec defines enemies as standalone hostile units with HP, movement types, attack sites, and spawn rules — all of which should be configurable per enemy type.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ENEMY DATA ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐     ┌─────────────────────┐                        │
│  │  ENEMY_DEFINITIONS  │     │   Enemy_Manager     │                        │
│  │  (Global Data)      │────▶│   (Singleton)       │                        │
│  │                     │     │                     │                        │
│  │  - placeholder      │     │  - enemy_list[]     │                        │
│  │  - (future types)   │     │  - process_turns()  │                        │
│  │                     │     │  - spawn_enemies()  │                        │
│  └─────────────────────┘     └──────────┬──────────┘                        │
│                                         │                                    │
│                                         │ creates/manages                    │
│                                         ▼                                    │
│                              ┌─────────────────────┐                        │
│                              │    Enemy_Obj        │                        │
│                              │    (Parent)         │                        │
│                              │                     │                        │
│                              │  - enemy_type_id    │                        │
│                              │  - enemy_def        │ ◄── ref to definition  │
│                              │  - current_hp       │                        │
│                              │  - enemy_state      │                        │
│                              │  - target_piece     │                        │
│                              │  - highlighted_tiles│                        │
│                              └──────────┬──────────┘                        │
│                                         │                                    │
│                                         │ inherits                           │
│                                         ▼                                    │
│                         ┌───────────────────────────────┐                   │
│                         │   Enemy_Placeholder_Obj       │                   │
│                         │   (Child - specific visuals)  │                   │
│                         └───────────────────────────────┘                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Documentation & References

```yaml
- file: context/design-docs/enemy-boss-system-spec.md
  why: Official design spec - enemy stats, behaviors, rules

- file: context/ARCHITECTURE.md
  why: Existing manager patterns, object hierarchy

- file: context/OBJECTS_REFERENCE.md
  why: How other objects are structured

- file: context/AI_SYSTEM.md
  why: Virtual board patterns, state machine approach
```

### Files to Reference (don't modify)

```yaml
- path: objects/Game_Manager/Create_0.gml
  why: Pattern for singleton initialization, variable setup

- path: objects/Chess_Piece_Obj/Create_0.gml
  why: Pattern for piece state variables

- path: scripts/ai_build_virtual_board/ai_build_virtual_board.gml
  why: Pattern for building data structures from game state
```

### Files to Create

```yaml
- path: objects/Enemy_Manager/Enemy_Manager.yy
  purpose: Object definition file

- path: objects/Enemy_Manager/Create_0.gml
  purpose: Initialize enemy definitions and manager state

- path: objects/Enemy_Manager/Step_0.gml
  purpose: (Stub for now - turn processing in PRP-010)

- path: objects/Enemy_Obj/Enemy_Obj.yy
  purpose: Parent enemy object definition

- path: objects/Enemy_Obj/Create_0.gml
  purpose: Initialize enemy instance state

- path: objects/Enemy_Obj/Step_0.gml
  purpose: (Stub for now - behavior in PRP-010/011/012)

- path: objects/Enemy_Obj/Draw_0.gml
  purpose: Draw enemy sprite with HP bar

- path: scripts/enemy_definitions/enemy_definitions.gml
  purpose: All enemy type definitions (data-driven)

- path: scripts/enemy_get_definition/enemy_get_definition.gml
  purpose: Lookup enemy definition by type ID

- path: scripts/enemy_create/enemy_create.gml
  purpose: Spawn an enemy of a given type at a position
```

---

## Implementation Blueprint

### Step 1: Create Enemy Definitions Script

**File:** `scripts/enemy_definitions/enemy_definitions.gml`

This script initializes all enemy type definitions as a global map. New enemy types are added here without modifying other code.

```gml
/// @function enemy_definitions_init()
/// @description Initialize all enemy type definitions
function enemy_definitions_init() {
    // Global map of enemy definitions by type ID
    global.enemy_definitions = ds_map_create();
    
    // === PLACEHOLDER ENEMY ===
    // The test enemy defined in the design spec
    var _placeholder = {
        enemy_id: "placeholder",
        display_name: "Placeholder Enemy",
        
        // === COMBAT STATS ===
        max_hp: 2,
        
        // === HITBOX (tiles occupied) ===
        hitbox_width: 1,
        hitbox_height: 1,
        
        // === MOVEMENT ===
        movement_type: "king",  // Moves like a king: 1 tile, 8 directions
        movement_speed: 30,     // Animation frames (same as chess pieces)
        
        // === ATTACK ===
        attack_type: "melee",   // "melee" = move onto target, "ranged" = projectile
        attack_site_width: 3,   // Detection zone: 3x3 around self
        attack_site_height: 3,
        attack_size_width: 1,   // Strike zone: 1x1 (single tile)
        attack_size_height: 1,
        attack_warning_turns: 1, // Turns of red highlight before strike
        
        // === SPAWNING ===
        spawn_rules: {
            default_ranks: [0, 1, 2],  // Rows 0-2 = Ranks 8-6 (black's top 3 rows)
            lane_lock: -1,              // -1 = any column, 0-7 = specific
            exact_tile: noone,          // {col, row} for fixed spawn, or noone
            avoid_occupied: true        // Don't spawn on occupied tiles
        },
        
        // === VISUALS ===
        sprite_idle: spr_enemy_placeholder,
        sprite_attack: spr_enemy_placeholder,  // Can be different for attack wind-up
        sprite_hurt: spr_enemy_placeholder,
        sprite_death: spr_enemy_placeholder,
        
        // === AUDIO ===
        sound_attack: noone,   // Will be added when sounds exist
        sound_hurt: noone,
        sound_death: noone
    };
    
    ds_map_add(global.enemy_definitions, "placeholder", _placeholder);
    
    // === FUTURE ENEMIES ===
    // Add more enemy definitions here following the same pattern:
    // var _slime = { ... };
    // ds_map_add(global.enemy_definitions, "slime", _slime);
    
    show_debug_message("Enemy definitions initialized: " + string(ds_map_size(global.enemy_definitions)) + " types");
}

/// @function enemy_definitions_cleanup()
/// @description Clean up enemy definitions (call on game exit)
function enemy_definitions_cleanup() {
    if (ds_exists(global.enemy_definitions, ds_type_map)) {
        ds_map_destroy(global.enemy_definitions);
    }
}
```

### Step 2: Create Enemy Get Definition Script

**File:** `scripts/enemy_get_definition/enemy_get_definition.gml`

```gml
/// @function enemy_get_definition(_enemy_id)
/// @param {string} _enemy_id The enemy type ID (e.g., "placeholder")
/// @returns {struct} Enemy definition struct, or undefined if not found
/// @description Retrieves an enemy type definition by ID
function enemy_get_definition(_enemy_id) {
    if (!ds_exists(global.enemy_definitions, ds_type_map)) {
        show_debug_message("ERROR: Enemy definitions not initialized!");
        return undefined;
    }
    
    if (!ds_map_exists(global.enemy_definitions, _enemy_id)) {
        show_debug_message("WARNING: Unknown enemy type: " + string(_enemy_id));
        return undefined;
    }
    
    return ds_map_find_value(global.enemy_definitions, _enemy_id);
}
```

### Step 3: Create Enemy_Manager Object

**File:** `objects/Enemy_Manager/Create_0.gml`

```gml
/// Enemy_Manager Create Event
/// Singleton manager for all enemies on the current level
show_debug_message("Enemy_Manager: Initializing...");

// === INITIALIZE ENEMY DEFINITIONS ===
if (!variable_global_exists("enemy_definitions") || 
    !ds_exists(global.enemy_definitions, ds_type_map)) {
    enemy_definitions_init();
}

// === ENEMY TRACKING ===
// List of all active enemy instances (updated by enemy_create/destroy)
enemy_list = [];

// === LEVEL CONFIGURATION ===
// These can be overridden per-room
level_enemy_min = 0;       // Minimum enemies to spawn
level_enemy_max = 0;       // Maximum enemies to spawn
level_enemy_types = [];    // Array of enemy type IDs that can spawn

// === TURN PROCESSING STATE ===
// Used by PRP-010 for sequential enemy turns
enemies_to_process = [];   // Queue of enemies waiting to act
current_enemy_index = 0;   // Index in queue
enemy_turn_active = false; // Is it currently enemy turn phase?
enemy_turn_state = "idle"; // State machine: idle, processing, waiting_animation

// === SPAWNING STATE ===
// Used by PRP-009 for spawn timing
spawn_complete = false;    // Have enemies spawned for this level?
spawn_delay_timer = 0;     // Delay before spawning (visual effect)

show_debug_message("Enemy_Manager: Ready (definitions: " + 
    string(ds_map_size(global.enemy_definitions)) + " types)");
```

**File:** `objects/Enemy_Manager/Step_0.gml`

```gml
/// Enemy_Manager Step Event
/// (Stub for now - full implementation in PRP-010)

// TODO: Process enemy turns when enemy_turn_active == true
// See PRP-010 for full implementation
```

**File:** `objects/Enemy_Manager/CleanUp_0.gml`

```gml
/// Enemy_Manager CleanUp Event
/// Clean up when leaving room

// Clear enemy list (instances are destroyed by room change)
enemy_list = [];

show_debug_message("Enemy_Manager: Cleaned up");
```

### Step 4: Create Enemy_Obj Parent Object

**File:** `objects/Enemy_Obj/Create_0.gml`

```gml
/// Enemy_Obj Create Event
/// Base enemy object - all enemy types inherit from this
show_debug_message("Enemy_Obj: Creating instance...");

// === IDENTITY ===
enemy_type_id = "placeholder";  // Set by enemy_create() or child object
enemy_def = undefined;          // Reference to definition struct (set after create)

// === COMBAT STATE ===
current_hp = 1;                 // Current HP (set from definition)
max_hp = 1;                     // Max HP (set from definition)
is_dead = false;                // Death flag (prevents double-death)

// === POSITION ===
// Grid coordinates (0-7 for 8x8 board)
grid_col = 0;
grid_row = 0;
// Pixel position (set to match grid)
// Uses built-in x, y

// === TURN STATE ===
// State machine for enemy behavior (PRP-010)
enemy_state = "idle";           // idle, scanning, highlighting, attacking, moving
state_timer = 0;                // General-purpose timer for state transitions

// === TARGETING ===
target_piece = noone;           // Currently targeted player piece
target_col = -1;                // Target tile column
target_row = -1;                // Target tile row
highlighted_tiles = [];         // Array of {col, row} for attack warning

// === MOVEMENT/ANIMATION ===
is_moving = false;
move_start_x = 0;
move_start_y = 0;
move_target_x = 0;
move_target_y = 0;
move_progress = 0;
move_duration = 30;             // Frames (0.5 seconds at 60fps)

// === KNOCKBACK ===
knockback_pending = false;
knockback_dir_x = 0;            // -1, 0, or 1
knockback_dir_y = 0;            // -1, 0, or 1

// === DEATH ANIMATION ===
death_timer = 0;
death_duration = 60;            // 1 second death animation
death_shake_intensity = 4;      // Pixels of shake

// === VISUAL ===
image_index = 0;
image_speed = 0;
draw_hp_bar = true;
hp_bar_offset_y = -8;           // Above sprite

// === AUDIO ===
audio_emitter = audio_emitter_create();
audio_emitter_position(audio_emitter, x, y, 0);
audio_emitter_falloff(audio_emitter, 32, 400, 1);

// === DEPTH ===
depth = -1;                     // Same layer as chess pieces

show_debug_message("Enemy_Obj: Instance created (type: " + enemy_type_id + ")");
```

**File:** `objects/Enemy_Obj/Step_0.gml`

```gml
/// Enemy_Obj Step Event
/// (Basic animation - full behavior in PRP-010/011/012)

// Update audio emitter position
audio_emitter_position(audio_emitter, x, y, 0);

// === MOVEMENT INTERPOLATION ===
if (is_moving) {
    move_progress += 1 / move_duration;
    if (move_progress >= 1) {
        move_progress = 1;
        is_moving = false;
        x = move_target_x;
        y = move_target_y;
        
        // Update grid position
        grid_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        grid_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    } else {
        var t = easeInOutQuad(move_progress);
        x = lerp(move_start_x, move_target_x, t);
        y = lerp(move_start_y, move_target_y, t);
    }
}

// === DEATH ANIMATION ===
if (is_dead && !is_moving) {
    death_timer++;
    if (death_timer >= death_duration) {
        // Remove from Enemy_Manager's list
        if (instance_exists(Enemy_Manager)) {
            var _idx = array_get_index(Enemy_Manager.enemy_list, id);
            if (_idx >= 0) {
                array_delete(Enemy_Manager.enemy_list, _idx, 1);
            }
        }
        instance_destroy();
    }
}
```

**File:** `objects/Enemy_Obj/Draw_0.gml`

```gml
/// Enemy_Obj Draw Event
/// Draw enemy sprite with HP bar and death effects

// === DEATH ANIMATION ===
if (is_dead) {
    // Red tint that fades out
    var _alpha = 1 - (death_timer / death_duration);
    var _shake_x = irandom_range(-death_shake_intensity, death_shake_intensity);
    var _shake_y = irandom_range(-death_shake_intensity, death_shake_intensity);
    
    draw_sprite_ext(
        sprite_index, image_index,
        x + _shake_x, y + _shake_y,
        1, 1, 0,
        c_red, _alpha
    );
    exit;
}

// === NORMAL DRAW ===
draw_sprite(sprite_index, image_index, x, y);

// === HP BAR ===
if (draw_hp_bar && max_hp > 1) {
    var _bar_width = 20;
    var _bar_height = 4;
    var _bar_x = x - _bar_width / 2;
    var _bar_y = y + hp_bar_offset_y;
    
    // Background (dark red)
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _bar_width, _bar_y + _bar_height,
        c_maroon, c_maroon, c_maroon, c_maroon, false
    );
    
    // HP fill (green to red gradient based on HP)
    var _hp_ratio = current_hp / max_hp;
    var _fill_width = _bar_width * _hp_ratio;
    var _hp_color = merge_color(c_red, c_lime, _hp_ratio);
    
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _fill_width, _bar_y + _bar_height,
        _hp_color, _hp_color, _hp_color, _hp_color, false
    );
    
    // Border
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _bar_width, _bar_y + _bar_height,
        c_black, c_black, c_black, c_black, true
    );
}
```

**File:** `objects/Enemy_Obj/Destroy_0.gml`

```gml
/// Enemy_Obj Destroy Event
/// Clean up audio emitter

if (audio_emitter != -1) {
    audio_emitter_free(audio_emitter);
}

show_debug_message("Enemy_Obj: Destroyed (type: " + enemy_type_id + ")");
```

### Step 5: Create Enemy Spawn Script

**File:** `scripts/enemy_create/enemy_create.gml`

```gml
/// @function enemy_create(_enemy_type_id, _col, _row)
/// @param {string} _enemy_type_id The enemy type ID (e.g., "placeholder")
/// @param {real} _col Board column (0-7)
/// @param {real} _row Board row (0-7)
/// @returns {Id.Instance} The created enemy instance, or noone on failure
/// @description Creates an enemy of the specified type at the given board position
function enemy_create(_enemy_type_id, _col, _row) {
    // Get enemy definition
    var _def = enemy_get_definition(_enemy_type_id);
    if (_def == undefined) {
        show_debug_message("ERROR: Cannot create enemy - unknown type: " + _enemy_type_id);
        return noone;
    }
    
    // Calculate pixel position
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // Create the enemy instance
    // For now, always use Enemy_Obj. When child objects exist (Enemy_Placeholder_Obj),
    // we can map enemy_type_id to specific object types.
    var _enemy = instance_create_depth(_x, _y, -1, Enemy_Obj);
    
    if (!instance_exists(_enemy)) {
        show_debug_message("ERROR: Failed to create Enemy_Obj instance");
        return noone;
    }
    
    // Initialize from definition
    with (_enemy) {
        enemy_type_id = _enemy_type_id;
        enemy_def = _def;
        
        // Combat stats
        max_hp = _def.max_hp;
        current_hp = max_hp;
        
        // Position
        grid_col = _col;
        grid_row = _row;
        
        // Animation timing
        move_duration = _def.movement_speed;
        
        // Visuals
        sprite_index = _def.sprite_idle;
        
        show_debug_message("Enemy created: " + _def.display_name + 
            " at (" + string(_col) + "," + string(_row) + 
            ") HP: " + string(current_hp) + "/" + string(max_hp));
    }
    
    // Register with Enemy_Manager
    if (instance_exists(Enemy_Manager)) {
        array_push(Enemy_Manager.enemy_list, _enemy);
    }
    
    return _enemy;
}
```

### Step 6: Create Enemy_Manager .yy Files

**File:** `objects/Enemy_Manager/Enemy_Manager.yy`

```json
{
  "$GMObject":"",
  "%Name":"Enemy_Manager",
  "eventList":[
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":0,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":3,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":12,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
  ],
  "managed":true,
  "name":"Enemy_Manager",
  "overriddenProperties":[],
  "parent":{
    "name":"Managers",
    "path":"folders/Objects/Managers.yy",
  },
  "parentObjectId":null,
  "persistent":false,
  "physicsAngularDamping":0.1,
  "physicsDensity":0.5,
  "physicsFriction":0.2,
  "physicsGroup":1,
  "physicsKinematic":false,
  "physicsLinearDamping":0.1,
  "physicsObject":false,
  "physicsRestitution":0.1,
  "physicsSensor":false,
  "physicsShape":1,
  "physicsShapePoints":[],
  "physicsStartAwake":true,
  "properties":[],
  "resourceType":"GMObject",
  "resourceVersion":"2.0",
  "solid":false,
  "spriteId":null,
  "spriteMaskId":null,
  "visible":true,
}
```

**File:** `objects/Enemy_Obj/Enemy_Obj.yy`

```json
{
  "$GMObject":"",
  "%Name":"Enemy_Obj",
  "eventList":[
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":0,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":3,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":8,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":4,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
  ],
  "managed":true,
  "name":"Enemy_Obj",
  "overriddenProperties":[],
  "parent":{
    "name":"Enemies",
    "path":"folders/Objects/Enemies.yy",
  },
  "parentObjectId":null,
  "persistent":false,
  "physicsAngularDamping":0.1,
  "physicsDensity":0.5,
  "physicsFriction":0.2,
  "physicsGroup":1,
  "physicsKinematic":false,
  "physicsLinearDamping":0.1,
  "physicsObject":false,
  "physicsRestitution":0.1,
  "physicsSensor":false,
  "physicsShape":1,
  "physicsShapePoints":[],
  "physicsStartAwake":true,
  "properties":[],
  "resourceType":"GMObject",
  "resourceVersion":"2.0",
  "solid":false,
  "spriteId":null,
  "spriteMaskId":null,
  "visible":true,
}
```

---

## Known Gotchas

### GML Reserved Names
Avoid these as variable names:
- `score`, `health`, `lives` — Built-in game variables
- `depth`, `x`, `y`, `direction`, `speed` — Instance variables (we use `depth` intentionally)
- `sign` — Built-in function

### Instance Existence Checks
Always check `instance_exists()` before accessing instance variables:
```gml
if (instance_exists(target_piece)) {
    var _tx = target_piece.x;
}
```

### ds_map vs Struct
We use `ds_map` for `global.enemy_definitions` because:
- Can be iterated with `ds_map_find_first/next`
- Cleaner type-checking with `ds_exists()`
- Better for large data sets

Individual definitions are structs for convenient dot notation.

### Sprite Placeholder
Until `spr_enemy_placeholder` exists, use any existing sprite or `noone`. The Draw event handles missing sprites gracefully.

---

## Success Criteria

- [ ] `enemy_definitions_init()` runs without errors
- [ ] `enemy_get_definition("placeholder")` returns the placeholder definition
- [ ] `enemy_create("placeholder", 4, 0)` spawns an enemy at column 4, row 0
- [ ] Enemy appears on screen with correct sprite
- [ ] HP bar displays above enemy (when HP > 1)
- [ ] Enemy is registered in `Enemy_Manager.enemy_list`
- [ ] Enemy is removed from list when destroyed
- [ ] Death animation plays (red shake, fade out)
- [ ] Code compiles without errors or warnings
- [ ] No reserved variable name conflicts

---

## Validation

### Manual Test

1. Add `Enemy_Manager` to `Game_Manager/Create_0.gml`:
   ```gml
   if (!instance_exists(Enemy_Manager)) {
       instance_create_depth(x, y, 0, Enemy_Manager);
   }
   ```

2. Temporarily spawn a test enemy in `Enemy_Manager/Create_0.gml`:
   ```gml
   // TEST: Remove after verification
   alarm[0] = 60; // 1 second delay
   ```

3. Create `Enemy_Manager/Alarm_0.gml`:
   ```gml
   // TEST: Spawn a placeholder enemy
   enemy_create("placeholder", 4, 6);
   ```

4. Compile and run with Igor
5. Verify enemy appears on screen after 1 second
6. Check debug output for creation messages

### Automated Test (Debug Key)

Add to `Game_Manager/KeyPress_69.gml` (E key):
```gml
// DEBUG: Spawn test enemy at random position
if (keyboard_check(vk_shift)) {
    var _col = irandom(7);
    var _row = irandom_range(5, 7);
    enemy_create("placeholder", _col, _row);
    show_debug_message("DEBUG: Spawned enemy at (" + string(_col) + "," + string(_row) + ")");
}
```

---

## Next Steps

After this PRP is implemented:
1. **PRP-009** — Implement spawn system with level configuration
2. **PRP-010** — Implement enemy turn processing
3. **PRP-014** — Implement HP/knockback mechanics (can be done in parallel)
