# PRP-022: Knockback Check Escape

## Summary
When the king is in check, allow moves where a player piece attacks an enemy and knocks it into the threat line, blocking the check. These moves show a **yellow indicator** (risky move) instead of green, because the enemy may move away on its turn, reopening the threat.

## Rules
1. **Knockback block = valid check escape (yellow)** — piece attacks enemy, enemy survives and gets knocked into the threat path between attacking piece and king. Yellow highlight warns "risky."
2. **Kill shot ≠ block** — if enemy has 1 HP and would die, no body remains to block. Not a valid escape (unless the attacking piece itself ends up blocking, which is already handled by normal check validation).
3. **Knockback blocked ≠ escape** — if knockback destination is invalid (wall, piece, edge), enemy stays put, piece bounces back. No check escape.
4. **Enemy moves away = your problem** — if the blocking enemy moves on its turn, the threat reopens. Game over if no other escape exists.

## Implementation

### New Script: `knockback_escapes_check(piece, target_x, target_y)`
- Returns `true` if attacking the enemy at target would knock it into the check threat line
- Steps:
  1. Find enemy at target position
  2. If enemy HP <= 1: return false (would die, no body)
  3. Calculate knockback direction + destination (reuse `enemy_calculate_knockback` logic without modifying state)
  4. If knockback invalid: return false
  5. Simulate: piece at target, enemy at knockback dest. Run check detection with enemy position as extra blocker in ray-casting.

### Modified: `move_leaves_king_in_check` → add optional `_extra_blocker_x/y` parameter
- Ray-casting checks now also consider an extra blocker position (the knocked-back enemy)

### Modified: `Chess_Piece_Obj/Draw_0.gml`
- When `move_is_legal == false` (normal check blocks it), check `knockback_escapes_check`
- If true: draw **yellow** indicator (`c_yellow`, alpha 0.5), set `tileInst.valid_move = true`, mark tile as `risky_knockback_move = true`

### Modified: `Tile_Obj/Mouse_7.gml`
- Check enforcement: if `move_leaves_king_in_check` would block, also check `knockback_escapes_check` — allow the move if knockback escape is valid

## Files
- NEW: `scripts/knockback_escapes_check/knockback_escapes_check.gml`
- MODIFY: `scripts/move_leaves_king_in_check/move_leaves_king_in_check.gml`
- MODIFY: `objects/Chess_Piece_Obj/Draw_0.gml`
- MODIFY: `objects/Tile_Obj/Mouse_7.gml`

## Dependencies
- PRP-008 (enemy data), PRP-014 (knockback) — both complete
