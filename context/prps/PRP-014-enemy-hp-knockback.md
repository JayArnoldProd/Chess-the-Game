# PRP-014: Enemy HP & Knockback System

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-008 (Enemy Data Architecture)  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

When player pieces "capture" enemies, they don't instant-kill:
1. **HP tracking:** Each enemy has HP (placeholder = 2)
2. **Damage on capture:** Player piece moving onto enemy = 1 damage
3. **Knockback direction:** Based on attacking piece's approach direction
4. **Knockback collision:** Hitting wall/another enemy = stay put
5. **Death animation:** Shake red, fade away when HP reaches 0

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DAMAGE & KNOCKBACK FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Player moves onto Enemy tile                                               │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────┐                                           │
│   │ enemy_take_damage()        │  ◀── Called from Tile_Obj/Mouse_7         │
│   │ _damage = 1                │                                           │
│   │ _attacker_x, _attacker_y   │  ◀── Where piece came FROM                │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│                 ▼                                                           │
│   ┌────────────────────────────┐                                           │
│   │ Calculate knockback dir    │                                           │
│   │ (opposite of attack dir)   │                                           │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│        ┌────────┴────────┐                                                 │
│        │                 │                                                 │
│        ▼                 ▼                                                 │
│   ┌──────────────┐  ┌───────────────────┐                                  │
│   │ Knockback    │  │ Knockback tile    │                                  │
│   │ tile valid   │  │ blocked           │                                  │
│   └──────┬───────┘  └─────────┬─────────┘                                  │
│          │                    │                                            │
│          ▼                    ▼                                            │
│   ┌──────────────┐  ┌───────────────────┐                                  │
│   │ Animate to   │  │ Stay in place     │                                  │
│   │ new tile     │  │ (hit wall)        │                                  │
│   └──────┬───────┘  └───────────────────┘                                  │
│          │                                                                  │
│          ▼                                                                  │
│   ┌────────────────────────────┐                                           │
│   │ Reduce HP                  │                                           │
│   └─────────────┬──────────────┘                                           │
│                 │                                                           │
│        ┌────────┴────────┐                                                 │
│        │                 │                                                 │
│        ▼                 ▼                                                 │
│   ┌──────────────┐  ┌───────────────────┐                                  │
│   │ HP > 0       │  │ HP <= 0           │                                  │
│   │ (survive)    │  │ (death)           │                                  │
│   └──────────────┘  └─────────┬─────────┘                                  │
│                               │                                            │
│                               ▼                                            │
│                      ┌───────────────────┐                                 │
│                      │ Death animation   │                                 │
│                      │ (shake + fade)    │                                 │
│                      └───────────────────┘                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## All Needed Context

### Files to Reference

```yaml
- path: objects/Chess_Piece_Obj/Step_0.gml
  why: pending_capture pattern, animation patterns

- path: objects/Tile_Obj/Mouse_7.gml
  why: Capture handling location
```

### Files to Modify

```yaml
- path: objects/Tile_Obj/Mouse_7.gml
  changes: Detect enemy collisions, call damage function

- path: objects/Enemy_Obj/Step_0.gml
  changes: Knockback animation, death state

- path: objects/Enemy_Obj/Draw_0.gml
  changes: Death animation visuals (already partially implemented)
```

### Files to Create

```yaml
- path: scripts/enemy_take_damage/enemy_take_damage.gml
  purpose: Apply damage to enemy, calculate knockback

- path: scripts/enemy_calculate_knockback/enemy_calculate_knockback.gml
  purpose: Determine knockback direction and target tile

- path: scripts/enemy_is_knockback_valid/enemy_is_knockback_valid.gml
  purpose: Check if knockback destination is valid
```

---

## Implementation Blueprint

### Step 1: Knockback Calculation

**File:** `scripts/enemy_calculate_knockback/enemy_calculate_knockback.gml`

```gml
/// @function enemy_calculate_knockback(_enemy, _attacker_col, _attacker_row)
/// @param {Id.Instance} _enemy The enemy being knocked back
/// @param {real} _attacker_col Column the attack came FROM
/// @param {real} _attacker_row Row the attack came FROM
/// @returns {struct} { dir_x, dir_y, dest_col, dest_row, valid }
/// @description Calculates knockback direction and destination
function enemy_calculate_knockback(_enemy, _attacker_col, _attacker_row) {
    var _result = {
        dir_x: 0,
        dir_y: 0,
        dest_col: _enemy.grid_col,
        dest_row: _enemy.grid_row,
        valid: false
    };
    
    if (!instance_exists(_enemy)) return _result;
    
    // Calculate attack direction (from attacker to enemy)
    var _dx = _enemy.grid_col - _attacker_col;
    var _dy = _enemy.grid_row - _attacker_row;
    
    // Knockback is in the SAME direction as attack
    // (enemy gets pushed away from attacker)
    // Normalize to -1, 0, or 1
    _result.dir_x = sign(_dx);
    _result.dir_y = sign(_dy);
    
    // Handle edge case: attacker on same tile (shouldn't happen)
    if (_result.dir_x == 0 && _result.dir_y == 0) {
        // Default to pushing down
        _result.dir_y = 1;
    }
    
    // Calculate destination
    _result.dest_col = _enemy.grid_col + _result.dir_x;
    _result.dest_row = _enemy.grid_row + _result.dir_y;
    
    // Check if destination is valid
    _result.valid = enemy_is_knockback_valid(_enemy, _result.dest_col, _result.dest_row);
    
    // If not valid, enemy stays in place (hit wall/edge/another enemy)
    if (!_result.valid) {
        _result.dest_col = _enemy.grid_col;
        _result.dest_row = _enemy.grid_row;
    }
    
    return _result;
}
```

### Step 2: Knockback Validation

**File:** `scripts/enemy_is_knockback_valid/enemy_is_knockback_valid.gml`

```gml
/// @function enemy_is_knockback_valid(_enemy, _col, _row)
/// @param {Id.Instance} _enemy The enemy being knocked back
/// @param {real} _col Target column
/// @param {real} _row Target row
/// @returns {bool} True if the knockback destination is valid
/// @description Checks if an enemy can be knocked back to the specified tile
function enemy_is_knockback_valid(_enemy, _col, _row) {
    // === BOUNDS CHECK ===
    // Per design spec: "hitting wall = stay put"
    if (_col < 0 || _col >= 8 || _row < 0 || _row >= 8) {
        return false;  // Edge of board = wall
    }
    
    // Calculate pixel position
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // === OTHER ENEMY CHECK ===
    // Per design spec: "hitting another enemy = stay put"
    var _other = instance_position(_x, _y, Enemy_Obj);
    if (_other != noone && _other != _enemy) {
        return false;
    }
    
    // === CHESS PIECE CHECK ===
    // Can't be knocked into a chess piece (treat as wall)
    var _piece = instance_position(_x, _y, Chess_Piece_Obj);
    if (_piece != noone) {
        return false;
    }
    
    // === STEPPING STONE CHECK ===
    // Stepping stones are immovable walls for knockback purposes (2026-02-27 ruling)
    var _stone = instance_position(_x, _y, Stepping_Stone_Obj);
    if (_stone != noone) {
        return false;
    }
    
    // === HAZARD CHECK ===
    // Don't knock into void - treat as wall (enemy stays put)
    // Note: Could alternatively knock into void and kill, but design says "stay put"
    var _tile = instance_position(_x, _y, Tile_Obj);
    if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
        if (_tile.tile_type == -1) {  // Void
            return false;
        }
        // Water without bridge
        if (_tile.tile_type == 1) {
            var _bridge = instance_position(_x, _y, Bridge_Obj);
            if (_bridge == noone) {
                return false;
            }
        }
    }
    
    return true;
}
```

### Step 3: Damage Function

**File:** `scripts/enemy_take_damage/enemy_take_damage.gml`

```gml
/// @function enemy_take_damage(_enemy, _damage, _attacker_col, _attacker_row)
/// @param {Id.Instance} _enemy The enemy taking damage
/// @param {real} _damage Amount of damage (typically 1)
/// @param {real} _attacker_col Column the attack came from
/// @param {real} _attacker_row Row the attack came from
/// @returns {bool} True if enemy died
/// @description Applies damage to enemy with knockback
function enemy_take_damage(_enemy, _damage, _attacker_col, _attacker_row) {
    if (!instance_exists(_enemy)) return false;
    if (_enemy.is_dead) return false;
    
    show_debug_message("Enemy taking " + string(_damage) + " damage from (" + 
        string(_attacker_col) + "," + string(_attacker_row) + ")");
    
    // === CALCULATE KNOCKBACK ===
    var _knockback = enemy_calculate_knockback(_enemy, _attacker_col, _attacker_row);
    
    // Store knockback info on enemy
    _enemy.knockback_pending = true;
    _enemy.knockback_dir_x = _knockback.dir_x;
    _enemy.knockback_dir_y = _knockback.dir_y;
    
    // === APPLY KNOCKBACK (if valid) ===
    if (_knockback.valid) {
        // Calculate destination pixel position
        var _dest_x = Object_Manager.topleft_x + _knockback.dest_col * Board_Manager.tile_size;
        var _dest_y = Object_Manager.topleft_y + _knockback.dest_row * Board_Manager.tile_size;
        
        // Start knockback animation
        _enemy.move_start_x = _enemy.x;
        _enemy.move_start_y = _enemy.y;
        _enemy.move_target_x = _dest_x;
        _enemy.move_target_y = _dest_y;
        _enemy.move_progress = 0;
        _enemy.move_duration = 15;  // Fast knockback (quarter second)
        _enemy.is_moving = true;
        
        show_debug_message("Enemy knocked back to (" + string(_knockback.dest_col) + "," + 
            string(_knockback.dest_row) + ")");
    } else {
        show_debug_message("Enemy knockback blocked (hit wall/edge/enemy)");
    }
    
    // === APPLY DAMAGE ===
    _enemy.current_hp -= _damage;
    
    // Play hurt sound
    if (variable_struct_exists(_enemy.enemy_def, "sound_hurt") && 
        _enemy.enemy_def.sound_hurt != noone) {
        audio_play_sound(_enemy.enemy_def.sound_hurt, 1, false);
    }
    
    // === CHECK DEATH ===
    if (_enemy.current_hp <= 0) {
        _enemy.is_dead = true;
        _enemy.death_timer = 0;
        
        // Play death sound
        if (variable_struct_exists(_enemy.enemy_def, "sound_death") && 
            _enemy.enemy_def.sound_death != noone) {
            audio_play_sound(_enemy.enemy_def.sound_death, 1, false);
        }
        
        show_debug_message("Enemy killed!");
        return true;
    }
    
    show_debug_message("Enemy HP: " + string(_enemy.current_hp) + "/" + string(_enemy.max_hp));
    return false;
}
```

### Step 4: Integrate with Tile Click (Player Captures Enemy)

**File:** `objects/Tile_Obj/Mouse_7.gml` (modification)

Find the section that handles normal captures (around where `pending_capture` is set):

```gml
// BEFORE (in normal move section):
var enemy = instance_position(x, y, Chess_Piece_Obj);
if (enemy != noone && enemy != piece && enemy.piece_type != piece.piece_type) {
    piece.pending_capture = enemy;
}

// AFTER - ADD enemy damage handling:
// Check for enemy collision FIRST (before checking for chess pieces)
var enemy_unit = instance_position(x, y, Enemy_Obj);
if (enemy_unit != noone && !enemy_unit.is_dead) {
    // Player is attacking an enemy unit
    // Calculate attacker's starting position (grid coordinates)
    var _attacker_col = round((piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _attacker_row = round((piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Deal damage and knockback
    var _killed = enemy_take_damage(enemy_unit, 1, _attacker_col, _attacker_row);
    
    // Play capture sound
    audio_play_sound(Piece_Capture_SFX, 1, false);
    
    // If enemy was knocked back, player piece lands on the tile
    // If enemy died, same thing
    // If enemy stayed (wall), player still lands on the tile but enemy is there...
    // Actually per chess rules, the piece should occupy the tile
    // But enemy knockback means enemy moves first
    
    // The piece will still move to this tile normally
    // Enemy has already been knocked back (or died)
}

// Normal chess piece capture check (existing code)
var enemy_piece = instance_position(x, y, Chess_Piece_Obj);
if (enemy_piece != noone && enemy_piece != piece && enemy_piece.piece_type != piece.piece_type) {
    piece.pending_capture = enemy_piece;
}
```

### Step 5: Update Enemy Death Animation

**File:** `objects/Enemy_Obj/Draw_0.gml` (update death section)

```gml
// === DEATH ANIMATION ===
if (is_dead) {
    // Calculate animation progress
    var _progress = death_timer / death_duration;
    var _alpha = 1 - _progress;
    
    // Red tint intensity (pulses then fades)
    var _red_pulse = 0.5 + 0.5 * sin(_progress * 3.14159 * 4);  // 4 pulses
    var _tint = merge_color(c_white, c_red, _red_pulse * (1 - _progress));
    
    // Shake intensity (decreases over time)
    var _shake = death_shake_intensity * (1 - _progress);
    var _shake_x = irandom_range(-_shake, _shake);
    var _shake_y = irandom_range(-_shake, _shake);
    
    // Scale (slightly grows then shrinks)
    var _scale = 1 + sin(_progress * 3.14159) * 0.2;
    
    draw_sprite_ext(
        sprite_index, image_index,
        x + _shake_x, y + _shake_y,
        _scale, _scale, 0,
        _tint, _alpha
    );
    exit;
}
```

### Step 6: Handle Knockback in Enemy Step

**File:** `objects/Enemy_Obj/Step_0.gml` (update movement section)

The existing movement interpolation already handles knockback (same animation system). Add a completion handler:

```gml
// === KNOCKBACK COMPLETION ===
if (knockback_pending && !is_moving) {
    knockback_pending = false;
    
    // Update grid position after knockback
    grid_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    grid_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    show_debug_message("Enemy knockback complete, now at (" + 
        string(grid_col) + "," + string(grid_row) + ")");
}
```

---

## Knockback Direction Examples

### Straight Attacks (Rook)

```
Rook attacks from left:      Rook attacks from above:
                             
  R → E → (knockback)          R
                               ↓
                               E
                               ↓
                          (knockback)
```

### Diagonal Attacks (Bishop)

```
Bishop attacks from top-left:
    
    B
      ↘
        E
          ↘
        (knockback)
```

The knockback direction is determined by the sign of (enemy_pos - attacker_pos), giving smooth diagonal motion.

### Stepping Stone Knockback Rules
*(Added 2026-02-27, per Jas ruling)*

Stepping stones (`Stepping_Stone_Obj`) are **immovable walls** for ALL collision/knockback purposes.

**Rule 1: Enemy knockback into stepping stone = cancelled**
```
  R → E → [Stone]     Rook attacks enemy, enemy can't be knocked into stone
         E stays put   (stepping stone = wall)
```

**Rule 2: Piece bounce-back is always a simple revert**
When a piece attacks an immovable target (enemy survives, knockback blocked, etc.), the piece simply **reverts to its pre-attack position**. No secondary knockback calculations. This applies whether the piece is on a stepping stone or not.
```
  [Stone+R] → E       Rook on stone attacks enemy right, enemy survives
  [Stone+R]   E       Rook reverts to its original tile (on the stone)
```

**Rule 3: Complex chain — same simple revert**
```
  [Stone+R]  E1 E2    Stone under rook, two enemies ahead
  [Stone+R]  E1 E2    Rook attacks E1 → E1 knockback cancelled (E2 blocks)
  [Stone+R]  E1 E2    Rook reverts to its original tile — no cascading checks
```

**Implementation Note:** Bounce-back always returns the piece to `bounce_back_x/y` (its position before the attack). No directional push-off logic needed. This keeps AI complexity low (per Jas, 2026-02-27).

---

## Known Gotchas

### Knockback Order
Knockback animation starts IMMEDIATELY when damage is dealt, before the attacking piece finishes moving. This is intentional for visual clarity.

### Player Piece Landing
The player piece still lands on the enemy's ORIGINAL tile, even if enemy was knocked back. This matches standard chess capture.

### Grid Position Update
`grid_col` and `grid_row` must be updated AFTER knockback animation completes, not when it starts.

### Wall = Board Edge
The design spec says "hitting wall = stay put". In our implementation, board edges (columns 0/7, rows 0/7) act as walls.

---

## Success Criteria

- [ ] Player piece "capturing" enemy deals 1 damage
- [ ] Enemy HP decreases correctly
- [ ] Enemy is knocked back in direction away from attacker
- [ ] Diagonal attacks cause diagonal knockback
- [ ] Knockback blocked by board edge (stay put)
- [ ] Knockback blocked by other enemies (stay put)
- [ ] Knockback blocked by hazards (stay put)
- [ ] HP bar updates after damage
- [ ] Enemy dies at 0 HP
- [ ] Death animation plays (shake red, fade)
- [ ] Dead enemy is removed from game
- [ ] Code compiles without errors

---

## Validation

### Basic Damage Test

1. Spawn enemy with 2 HP
2. Move player piece onto enemy
3. Verify enemy takes 1 damage (HP: 1/2)
4. Verify enemy is knocked back

### Kill Test

1. Enemy at 1 HP
2. Attack enemy
3. Verify death animation plays
4. Verify enemy disappears after animation

### Knockback Direction Test

1. Attack enemy from left → verify knockback right
2. Attack enemy from top-right → verify knockback bottom-left
3. Verify smooth diagonal animation

### Wall Collision Test

1. Position enemy at board edge (column 7)
2. Attack from left
3. Verify enemy stays at column 7 (blocked by wall)

### Enemy Collision Test

1. Place two enemies adjacent
2. Attack first enemy
3. Verify first enemy stays put (blocked by second enemy)

### Stepping Stone Knockback Test
*(Added 2026-02-27)*

1. Place enemy adjacent to a stepping stone
2. Attack enemy so knockback would push into stone
3. Verify enemy stays put (stepping stone = wall)

### Stepping Stone Bounce-Back Test

1. Place player piece ON a stepping stone
2. Attack an enemy with 2+ HP (survives the hit)
3. Verify player piece reverts to its original position (on the stepping stone)
4. Verify stepping stone remains in place (immovable)

### Stepping Stone Chain Test

1. Set up: stepping stone under rook, enemy ahead, second enemy behind first
2. Rook attacks forward
3. Verify: first enemy knockback cancelled (blocked by second enemy)
4. Verify: rook reverts to its original tile (on the stepping stone) — no cascading push

---

## Next Steps

After this PRP is implemented:
1. **PRP-015** — Multi-tile piece support
2. **PRP-016** — Integration test
