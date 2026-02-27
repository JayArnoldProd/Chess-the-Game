# PRP-013: Enemy Attack System (Ranged)

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** MEDIUM  
**Depends On:** PRP-012 (Enemy Melee Attack)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

Ranged attacks allow enemies to hit tiles without moving:
1. **Projectile/slash attacks:** Hit tiles within attack range
2. **No movement:** Enemy stays in place after attack
3. **Same highlight cycle:** Red glow → strike (1-turn warning)
4. **Visual effects:** Projectile animation or slash effect

This extends the melee attack system from PRP-012.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          RANGED vs MELEE COMPARISON                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   === MELEE (PRP-012) ===              === RANGED (PRP-013) ===             │
│                                                                              │
│   ┌──────────────────┐                 ┌──────────────────┐                 │
│   │ Scan attack site │                 │ Scan attack site │                 │
│   └────────┬─────────┘                 └────────┬─────────┘                 │
│            ▼                                    ▼                            │
│   ┌──────────────────┐                 ┌──────────────────┐                 │
│   │ Highlight target │                 │ Highlight target │                 │
│   └────────┬─────────┘                 └────────┬─────────┘                 │
│            ▼                                    ▼                            │
│   ┌──────────────────┐                 ┌──────────────────┐                 │
│   │ MOVE to target   │                 │ STAY in place    │                 │
│   │ tile (attack)    │                 │ Fire projectile  │                 │
│   └────────┬─────────┘                 └────────┬─────────┘                 │
│            ▼                                    ▼                            │
│   ┌──────────────────┐                 ┌──────────────────┐                 │
│   │ Enemy now on     │                 │ Enemy still at   │                 │
│   │ target tile      │                 │ original tile    │                 │
│   └──────────────────┘                 └──────────────────┘                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Enemy_Obj/Step_0.gml
  why: Existing melee attack implementation (PRP-012)
```

### Files to Modify

```yaml
- path: objects/Enemy_Obj/Step_0.gml
  changes: Add ranged attack handling in "attacking" state

- path: scripts/enemy_definitions/enemy_definitions.gml
  changes: Add ranged enemy example definition
```

### Files to Create

```yaml
- path: objects/Attack_Projectile_Obj/Attack_Projectile_Obj.yy
  purpose: Visual projectile for ranged attacks

- path: objects/Attack_Projectile_Obj/Create_0.gml
  purpose: Initialize projectile

- path: objects/Attack_Projectile_Obj/Step_0.gml
  purpose: Projectile movement

- path: objects/Attack_Projectile_Obj/Draw_0.gml
  purpose: Projectile visual

- path: scripts/enemy_execute_ranged_attack/enemy_execute_ranged_attack.gml
  purpose: Fire projectile and handle hit detection
```

---

## Implementation Blueprint

### Step 1: Add Ranged Enemy Definition

**File:** `scripts/enemy_definitions/enemy_definitions.gml` (addition)

```gml
// === RANGED PLACEHOLDER ENEMY ===
// Example ranged enemy for testing
var _ranged_placeholder = {
    enemy_id: "ranged_placeholder",
    display_name: "Ranged Placeholder",
    
    // === COMBAT STATS ===
    max_hp: 1,
    
    // === HITBOX ===
    hitbox_width: 1,
    hitbox_height: 1,
    
    // === MOVEMENT ===
    movement_type: "king",
    movement_speed: 30,
    
    // === ATTACK ===
    attack_type: "ranged",          // "ranged" instead of "melee"
    attack_site_width: 5,           // Larger detection zone
    attack_site_height: 5,
    attack_size_width: 1,
    attack_size_height: 1,
    attack_warning_turns: 1,
    projectile_speed: 8,            // Pixels per frame
    
    // === SPAWNING ===
    spawn_rules: {
        default_ranks: [5, 6, 7],
        lane_lock: -1,
        exact_tile: noone,
        avoid_occupied: true
    },
    
    // === VISUALS ===
    sprite_idle: spr_enemy_placeholder,
    sprite_attack: spr_enemy_placeholder,
    sprite_projectile: spr_attack_projectile,  // Projectile sprite
    
    // === AUDIO ===
    sound_attack: noone,
    sound_projectile_hit: noone
};

ds_map_add(global.enemy_definitions, "ranged_placeholder", _ranged_placeholder);
```

### Step 2: Create Projectile Object

**File:** `objects/Attack_Projectile_Obj/Create_0.gml`

```gml
/// Attack_Projectile_Obj Create Event
/// Visual projectile for ranged enemy attacks

// === MOVEMENT ===
start_x = x;
start_y = y;
target_x = x;
target_y = y;
projectile_speed = 8;  // Pixels per frame (overridden by spawner)
move_progress = 0;

// === STATE ===
is_active = true;
has_hit = false;

// === SOURCE ===
source_enemy = noone;  // Set by spawner

// === VISUAL ===
image_index = 0;
image_speed = 0;
sprite_index = spr_attack_projectile;  // Fallback

// === DEPTH ===
depth = -3;  // Above pieces
```

**File:** `objects/Attack_Projectile_Obj/Step_0.gml`

```gml
/// Attack_Projectile_Obj Step Event
/// Move toward target and check for hit

if (!is_active) exit;

// Calculate total distance
var _total_dist = point_distance(start_x, start_y, target_x, target_y);
if (_total_dist < 1) {
    // Already at target
    has_hit = true;
    is_active = false;
    exit;
}

// Move toward target
var _move_dist = projectile_speed;
move_progress += _move_dist / _total_dist;

if (move_progress >= 1) {
    // Reached target
    x = target_x;
    y = target_y;
    has_hit = true;
    is_active = false;
    
    // Check for target piece
    var _victim = instance_position(x, y, Chess_Piece_Obj);
    if (_victim != noone && _victim.piece_type == 0) {
        // Hit player piece!
        audio_play_sound(Piece_Capture_SFX, 1, false);
        
        // Check for king
        if (_victim.piece_id == "king") {
            Game_Manager.game_over = true;
            Game_Manager.game_over_message = "Enemies Win!";
        }
        
        instance_destroy(_victim);
        show_debug_message("Projectile: Hit " + _victim.piece_id + "!");
    } else {
        // Missed
        show_debug_message("Projectile: Missed (target moved)");
    }
    
    // Destroy projectile after short delay (visual)
    alarm[0] = 5;
} else {
    // Interpolate position
    x = lerp(start_x, target_x, move_progress);
    y = lerp(start_y, target_y, move_progress);
}
```

**File:** `objects/Attack_Projectile_Obj/Alarm_0.gml`

```gml
/// Attack_Projectile_Obj Alarm 0
/// Destroy projectile after visual delay
instance_destroy();
```

**File:** `objects/Attack_Projectile_Obj/Draw_0.gml`

```gml
/// Attack_Projectile_Obj Draw Event
/// Draw projectile with rotation toward target

if (!is_active && has_hit) {
    // Draw hit effect (brief flash)
    draw_set_alpha(0.8);
    draw_circle_color(x, y, 8, c_red, c_orange, false);
    draw_set_alpha(1);
} else {
    // Draw projectile facing direction of travel
    var _angle = point_direction(start_x, start_y, target_x, target_y);
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, _angle, c_white, 1);
}
```

### Step 3: Update Attacking State for Ranged

**File:** `objects/Enemy_Obj/Step_0.gml` (modify "attacking" case)

```gml
case "attacking":
    // EXECUTE ATTACK (Melee or Ranged)
    var _attack_type = enemy_def.attack_type;
    
    if (_attack_type == "ranged") {
        // === RANGED ATTACK ===
        if (!attack_executed) {
            attack_executed = true;
            
            // Target tile (committed)
            var _dest_col = attack_target_col;
            var _dest_row = attack_target_row;
            
            if (_dest_col < 0 || _dest_row < 0) {
                enemy_reset_attack_state();
                enemy_state = "turn_complete";
                break;
            }
            
            // Calculate destination position
            var _dest_x = Object_Manager.topleft_x + _dest_col * Board_Manager.tile_size;
            var _dest_y = Object_Manager.topleft_y + _dest_row * Board_Manager.tile_size;
            
            // Create projectile
            var _proj = instance_create_depth(x, y, -3, Attack_Projectile_Obj);
            if (instance_exists(_proj)) {
                _proj.start_x = x;
                _proj.start_y = y;
                _proj.target_x = _dest_x;
                _proj.target_y = _dest_y;
                _proj.source_enemy = id;
                
                // Set projectile speed from definition
                if (variable_struct_exists(enemy_def, "projectile_speed")) {
                    _proj.projectile_speed = enemy_def.projectile_speed;
                }
                
                // Set projectile sprite
                if (variable_struct_exists(enemy_def, "sprite_projectile")) {
                    _proj.sprite_index = enemy_def.sprite_projectile;
                }
                
                show_debug_message("Enemy: Fired ranged attack at (" + 
                    string(_dest_col) + "," + string(_dest_row) + ")");
            }
            
            // Clear highlights
            highlighted_tiles = [];
            
            // Play attack sound
            if (variable_struct_exists(enemy_def, "sound_attack") && 
                enemy_def.sound_attack != noone) {
                audio_play_sound(enemy_def.sound_attack, 1, false);
            }
            
            // Set wait timer for projectile travel
            state_timer = 0;
        }
        
        // Wait for projectile to reach target
        state_timer++;
        var _wait_frames = 30;  // Reasonable time for projectile travel
        
        // Also check if projectile is done
        var _proj_done = true;
        with (Attack_Projectile_Obj) {
            if (source_enemy == other.id && is_active) {
                _proj_done = false;
            }
        }
        
        if (state_timer >= _wait_frames || _proj_done) {
            // Ranged attack complete
            enemy_reset_attack_state();
            enemy_state = "turn_complete";
        }
        
    } else {
        // === MELEE ATTACK (existing code from PRP-012) ===
        if (!attack_executed) {
            attack_executed = true;
            
            var _dest_col = attack_target_col;
            var _dest_row = attack_target_row;
            
            if (_dest_col < 0 || _dest_row < 0) {
                enemy_reset_attack_state();
                enemy_state = "turn_complete";
                break;
            }
            
            var _dest_x = Object_Manager.topleft_x + _dest_col * Board_Manager.tile_size;
            var _dest_y = Object_Manager.topleft_y + _dest_row * Board_Manager.tile_size;
            
            var _victim = instance_position(_dest_x, _dest_y, Chess_Piece_Obj);
            if (_victim != noone && _victim.piece_type == 0) {
                attack_hit = true;
                show_debug_message("Enemy: Melee attacking " + _victim.piece_id);
            } else {
                attack_hit = false;
                show_debug_message("Enemy: Melee attack - target moved!");
            }
            
            move_start_x = x;
            move_start_y = y;
            move_target_x = _dest_x;
            move_target_y = _dest_y;
            move_progress = 0;
            move_duration = enemy_def.movement_speed;
            is_moving = true;
            
            highlighted_tiles = [];
        }
        
        if (is_moving) break;
        
        if (attack_hit) {
            var _victim = instance_position(x, y, Chess_Piece_Obj);
            if (_victim != noone && _victim.piece_type == 0) {
                audio_play_sound(Piece_Capture_SFX, 1, false);
                
                if (_victim.piece_id == "king") {
                    Game_Manager.game_over = true;
                    Game_Manager.game_over_message = "Enemies Win!";
                }
                
                instance_destroy(_victim);
            }
        }
        
        enemy_reset_attack_state();
        enemy_state = "turn_complete";
    }
    break;
```

### Step 4: Projectile Object Definition

**File:** `objects/Attack_Projectile_Obj/Attack_Projectile_Obj.yy`

```json
{
  "$GMObject":"",
  "%Name":"Attack_Projectile_Obj",
  "eventList":[
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":0,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":3,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":8,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
    {"$GMEvent":"","%Name":"","collisionObjectId":null,"eventNum":0,"eventType":2,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},
  ],
  "managed":true,
  "name":"Attack_Projectile_Obj",
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

## Ranged Attack Characteristics

| Aspect | Melee | Ranged |
|--------|-------|--------|
| Movement | Moves to target tile | Stays in place |
| Visual | Enemy animates to tile | Projectile flies to tile |
| After Attack | Enemy at new position | Enemy at same position |
| Range | Typically short (3×3) | Can be longer (5×5+) |

---

## Known Gotchas

### Projectile Lifetime
Projectiles auto-destroy after hitting or 5 frames post-hit. Don't leave orphaned projectiles.

### Multiple Projectiles
If multiple ranged enemies fire, each creates its own projectile. Track via `source_enemy`.

### No Sprite Fallback
If `spr_attack_projectile` doesn't exist, projectile may be invisible. Create a placeholder sprite or use shape drawing.

---

## Success Criteria

- [ ] Ranged enemy stays in place when attacking
- [ ] Projectile flies from enemy to target tile
- [ ] Projectile captures piece if target present
- [ ] Projectile misses if target moved (no capture)
- [ ] Projectile visual displays correctly
- [ ] Hit effect shows on impact
- [ ] Enemy turn completes after projectile lands
- [ ] Multiple projectiles work independently
- [ ] Code compiles without errors

---

## Validation

### Ranged Attack Test

1. Spawn a ranged enemy (modify `enemy_get_level_config` temporarily)
2. Place player piece in range (5×5 zone)
3. Verify highlight appears
4. Verify projectile fires on next turn
5. Verify piece is captured, enemy didn't move

### Miss Test

1. Ranged enemy highlights target
2. Move target piece before enemy's attack turn
3. Verify projectile fires at old position
4. Verify projectile misses (no capture)

### Visual Test

1. Fire projectile
2. Verify projectile rotates toward target
3. Verify hit effect shows on impact

---

## Next Steps

After this PRP is implemented:
1. **PRP-014** — Implement HP and knockback (damage TO enemies)
2. **PRP-015** — Multi-tile piece support
