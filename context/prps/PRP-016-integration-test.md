# PRP-016: Placeholder Enemy Integration Test

**Author:** Arnold (AI Co-Architect)  
**Date:** 2026-02-27  
**Status:** PROPOSED  
**Priority:** HIGH  
**Depends On:** PRP-008 through PRP-015  
**Part Of:** Enemy & Boss System (see TASK_PLAN_ENEMY_BOSS_SYSTEM.md)

---

## Problem Statement

All enemy system components have been built. This PRP:
1. **Integration verification:** Ensure all components work together
2. **Full turn cycle test:** Player → Enemies → AI → repeat
3. **HP/knockback verification:** Damage, knockback, death animation
4. **Level scaling test:** Different enemy counts per level

---

## Test Checklist

### Core Turn Cycle

| # | Test | Expected Result | ✓ |
|---|------|-----------------|---|
| 1 | Player moves piece | Turn switches to 2 (enemies) | ☐ |
| 2 | Enemy turn begins | Enemy_Manager processes queue | ☐ |
| 3 | Enemy scans | Finds/doesn't find target | ☐ |
| 4 | Enemy no target | Moves toward closest player piece | ☐ |
| 5 | Enemy with target | Highlights tile, waits | ☐ |
| 6 | Enemy attack turn | Moves to highlighted tile | ☐ |
| 7 | All enemies done | Turn switches to 1 (AI) | ☐ |
| 8 | AI makes move | Normal AI behavior | ☐ |
| 9 | AI move done | Turn switches to 0 (player) | ☐ |
| 10 | Cycle repeats | No stuck states | ☐ |

### Enemy Spawning

| # | Test | Expected Result | ✓ |
|---|------|-----------------|---|
| 11 | Level loads | Enemies spawn after 1 second | ☐ |
| 12 | Spawn count | Within min/max range | ☐ |
| 13 | Spawn position | On rows 6-8, not on pieces | ☐ |
| 14 | Multiple spawns | No overlapping enemies | ☐ |
| 15 | Boss level | No enemies (boss only) | ☐ |

### Combat

| # | Test | Expected Result | ✓ |
|---|------|-----------------|---|
| 16 | Player attacks enemy | Enemy takes 1 damage | ☐ |
| 17 | Knockback direction | Away from attacker | ☐ |
| 18 | Knockback blocked | Enemy stays put (wall/enemy) | ☐ |
| 19 | Enemy at 0 HP | Death animation plays | ☐ |
| 20 | Enemy dies | Removed from enemy_list | ☐ |
| 21 | Enemy captures piece | Player piece destroyed | ☐ |
| 22 | Enemy captures king | Game over (enemies win) | ☐ |

### Visual

| # | Test | Expected Result | ✓ |
|---|------|-----------------|---|
| 23 | HP bar | Shows above enemy | ☐ |
| 24 | HP bar updates | Decreases with damage | ☐ |
| 25 | Attack highlight | Red pulse on target tile | ☐ |
| 26 | Death animation | Shake red, fade out | ☐ |
| 27 | Movement animation | Smooth tile-to-tile | ☐ |

---

## Test Setup

### Level Configuration

Modify `scripts/enemy_get_level_config/enemy_get_level_config.gml` to enable testing:

```gml
case Ruined_Overworld:
    _config.has_enemies = true;
    _config.enemy_count_min = 1;
    _config.enemy_count_max = 2;  // 1-2 for initial testing
    _config.enemy_types = ["placeholder"];
    break;
```

### Debug Controls

Add debug key handlers for testing:

**File:** `objects/Game_Manager/KeyPress_69.gml` (E key)

```gml
/// E key - Debug enemy controls
if (keyboard_check(vk_shift)) {
    // Shift+E: Spawn enemy at random position
    var _col = irandom_range(0, 7);
    var _row = irandom_range(5, 7);
    enemy_create("placeholder", _col, _row);
    show_debug_message("DEBUG: Spawned enemy at (" + string(_col) + "," + string(_row) + ")");
} else if (keyboard_check(vk_control)) {
    // Ctrl+E: Kill all enemies
    with (Enemy_Obj) {
        current_hp = 0;
        is_dead = true;
        death_timer = 0;
    }
    show_debug_message("DEBUG: Killed all enemies");
} else {
    // E: Toggle enemy debug info
    global.enemy_debug_visible = !global.enemy_debug_visible;
    show_debug_message("DEBUG: Enemy info " + (global.enemy_debug_visible ? "ON" : "OFF"));
}
```

**File:** `objects/Enemy_Manager/Draw_64.gml` (create if doesn't exist)

```gml
/// Enemy_Manager Draw GUI Event - Debug overlay

if (!variable_global_exists("enemy_debug_visible")) {
    global.enemy_debug_visible = false;
}

if (!global.enemy_debug_visible) exit;

var _x = 10;
var _y = 100;

draw_set_font(-1);
draw_set_color(c_white);

// Header
draw_text(_x, _y, "=== ENEMY DEBUG ===");
_y += 16;

// Turn state
draw_text(_x, _y, "Turn: " + string(Game_Manager.turn) + 
    " (" + (Game_Manager.turn == 0 ? "PLAYER" : 
           (Game_Manager.turn == 1 ? "AI" : 
           (Game_Manager.turn == 2 ? "ENEMIES" : "?"))) + ")");
_y += 14;

// Enemy count
draw_text(_x, _y, "Enemies: " + string(array_length(enemy_list)));
_y += 14;

// Enemy turn state
draw_text(_x, _y, "Enemy Turn State: " + enemy_turn_state);
_y += 14;

// Current enemy index
if (enemy_turn_state == "processing") {
    draw_text(_x, _y, "Processing: " + string(current_enemy_index + 1) + 
        "/" + string(array_length(enemies_to_process)));
    _y += 14;
}

// Individual enemy states
_y += 10;
draw_text(_x, _y, "Enemy States:");
_y += 14;

for (var i = 0; i < array_length(enemy_list); i++) {
    var _e = enemy_list[i];
    if (!instance_exists(_e)) continue;
    
    var _state_str = _e.enemy_state;
    if (_e.attack_committed) _state_str += " [ATK]";
    if (_e.is_dead) _state_str = "DEAD";
    
    draw_text(_x + 10, _y, string(i) + ": " + _state_str + 
        " HP:" + string(_e.current_hp) + "/" + string(_e.max_hp) +
        " (" + string(_e.grid_col) + "," + string(_e.grid_row) + ")");
    _y += 14;
}
```

---

## Test Scenarios

### Scenario 1: Basic Turn Cycle

**Setup:**
1. Load Ruined_Overworld
2. Wait for enemy spawn

**Steps:**
1. Move any player piece
2. Observe turn switch to enemies
3. Watch enemy act (scan → move or highlight)
4. Observe turn switch to AI
5. Watch AI move
6. Observe turn switch back to player

**Pass Criteria:**
- No freezes or stuck states
- Each phase completes in <5 seconds
- Turn indicator updates correctly

### Scenario 2: Enemy Attack

**Setup:**
1. Position player pawn near enemy (within 3×3)

**Steps:**
1. Move player piece (don't attack enemy)
2. Observe enemy highlight pawn
3. Move player piece again
4. Observe enemy attack highlighted tile

**Pass Criteria:**
- Red highlight visible on pawn's tile
- Enemy moves to pawn's original tile
- If pawn stayed → captured
- If pawn moved → enemy lands on empty tile

### Scenario 3: Combat Damage

**Setup:**
1. Spawn enemy (Shift+E if needed)

**Steps:**
1. Move player piece onto enemy
2. Observe enemy HP decrease
3. Observe knockback direction
4. Repeat until enemy dies

**Pass Criteria:**
- Enemy takes 1 damage per attack
- Enemy knocked back correctly
- Death animation plays at 0 HP
- Enemy disappears after animation

### Scenario 4: Knockback Edge Cases

**Setup:**
1. Position enemy at board edge (column 7)
2. Position another enemy adjacent to first

**Steps:**
1. Attack edge enemy from left
2. Observe knockback blocked (stays put)
3. Attack first enemy from other direction
4. Observe knockback blocked by second enemy

**Pass Criteria:**
- Enemy at edge doesn't teleport off-board
- Enemy doesn't overlap other enemy
- Damage still applies even when knockback blocked

### Scenario 5: Multiple Enemies

**Setup:**
1. Configure 3 enemies for level
2. Load level

**Steps:**
1. Move player piece
2. Watch each enemy act in sequence
3. Verify all 3 complete before AI turn

**Pass Criteria:**
- Enemies act one at a time
- Each enemy completes its turn
- Turn switches to AI after all enemies

### Scenario 6: Level Scaling

**Setup:**
1. Configure different enemy counts per level

| Level | Min | Max |
|-------|-----|-----|
| Ruined_Overworld | 1 | 1 |
| Pirate_Seas | 1 | 2 |
| Fear_Factory | 2 | 3 |

**Steps:**
1. Load each level
2. Count spawned enemies

**Pass Criteria:**
- Enemy count within configured range
- Enemies don't spawn on occupied tiles
- Enemies don't spawn on hazards

---

## Regression Tests

After integration test passes, verify these don't break:

| Feature | Test |
|---------|------|
| Normal chess | AI still plays normally |
| Stepping stones | 2-phase move still works |
| Check detection | King in check still detected |
| Settings menu | Still opens/closes correctly |
| Level navigation | Arrow keys still work |
| AI difficulty | Changing difficulty works |

---

## Bug Tracking

If issues found during testing, document in `C:\Users\jayar\clawd\memory\chess-bugs.md`:

```markdown
| # | Status | Bug | Found | Fixed | Notes |
|---|--------|-----|-------|-------|-------|
| 32 | 🔴 | [Description] | 2026-02-27 | — | [Context] |
```

---

## Performance Notes

Monitor for performance issues:
- Frame rate during enemy turn (should stay 60fps)
- Memory usage with multiple enemies
- Animation smoothness

If performance issues:
- Cap enemies at 5 per level
- Optimize pathfinding in `enemy_pick_best_move`
- Batch debug message logging

---

## Success Criteria

- [ ] All test checklist items pass
- [ ] All 6 scenarios complete without issues
- [ ] No regression in existing features
- [ ] No crashes or freezes
- [ ] Frame rate stays above 55fps
- [ ] Debug overlay provides useful info

---

## Next Steps

After integration test passes:
1. **PRP-017** — Begin boss system implementation
2. Document any bugs found in chess-bugs.md
3. Consider polish items (sounds, particles, etc.)
