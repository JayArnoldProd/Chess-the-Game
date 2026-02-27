# Enemy & Boss System — Design Spec (FINAL v2)

*Designed by Jas. Interpreted and structured by Arnold. All questions resolved.*

---

## PART 1: Enemy System (Non-Boss Hostile Units)

Enemies are standalone hostile units that exist on the board alongside the player's chess pieces. They follow their own movement/attack rules, separate from standard chess.

### HP System
- Each enemy has an HP value
- Player pieces capture enemies by **moving onto them**, dealing **1 damage** (not instant kill)
- On hit: enemy is **knocked back 1 tile** in the direction the capturing piece came from
  - Bishop capture → diagonal knockback (smooth diagonal motion in-game)
  - Rook capture → straight knockback (1 tile in the direction of attack)
- If knockback tile is blocked (wall, corner, or another enemy): enemy stays on its current tile (treated like hitting a wall)
- Enemy dies at 0 HP → **shakes red and fades away**
- **Player pieces do NOT have HP** — they use standard chess capture rules (one capture = dead). No HP tracking needed for regular pieces.

### Turn Order
1. **Player moves** (standard chess move)
2. **Enemies act** (each independently, in sequence)
3. Back to player

### Enemy Attack Types
Enemies have **two types of attacks**:

1. **Melee (Move-to-Capture)** — Enemy moves onto the target's tile to capture it. Standard capture behavior.
2. **Ranged (Projectile/Slash)** — Enemy fires a projectile or performs a slash hitting tiles within its attack range **without moving**. The enemy stays in place.

Each enemy type defines which attack type(s) it uses.

### Turn Cycle (per enemy, independent)
1. Scan **attack site** (vision range) for player pieces
2. **Found →** Highlight the **specific tile(s) the target occupies** in red. Next turn: strike (melee or ranged depending on enemy type)
3. **Not found →** Move according to movement AI
4. Attack is **committed** — if player dodges, enemy still executes the attack on the highlighted tile(s)

> **Attack site vs attack size:** The attack site (e.g. 3×3) is the enemy's *detection/vision zone*. The attack size (e.g. 1×1) is how many tiles the actual strike hits. The enemy picks a target within its site and strikes only that target's tile(s) — it does NOT strike the entire detection zone.

### Enemy Collision Rules
- **Enemies CANNOT occupy the same tile as another enemy**
- If an enemy tries to move onto another enemy's tile, it gets **pushed back to its original square**
- **Enemies cannot capture other enemies** — knockback into another enemy treats that enemy as an immovable wall (knocked-back enemy stays put)
- **Multiple enemies targeting the same piece:** The first enemy to highlight gets priority and strikes first. The second enemy then tries to move toward the (now empty) tile; if another enemy is already there, it gets pushed back to its square

### Spawning
- **Default:** Enemies spawn randomly on **ranks 8, 7, or 6** (the back three rows)
- **Customizable:** Some enemies can have special spawn conditions:
  - Locked to a specific lane (column)
  - Locked to an exact tile
  - Custom spawn zones
- Spawn system should be **data-driven** so spawn rules are easily configurable per enemy type

### Piece Sizes
- Pieces can have different sizes (e.g. 1×1, 1×2, 2×2)
- A piece occupies ALL tiles of its size and can be hit on ANY of those tiles
- **Knockback for multi-tile pieces:** Same as 1×1 — the whole piece shifts 1 tile in the direction it was hit. Smooth diagonal/straight motion in-game regardless of size.
- Each enemy also has its own hitbox size (placeholder = 1×1)

### Placeholder Test Enemy

| Stat | Value |
|------|-------|
| **HP** | 2 |
| **Hitbox** | 1×1 |
| **Movement** | King-style (1 tile, 8 directions), toward closest player piece |
| **Attack Site (vision)** | 3×3 around itself |
| **Attack Type** | Melee (move onto to capture) |
| **Attack Size (strike)** | 1×1 |
| **Spawn** | Random, ranks 8-6 |
| **Death Animation** | Shake red, fade away |
| **Level Scaling** | Levels 1-2 = 1 enemy, Levels 3-4 = 2-3 enemies |

---

## PART 2: Boss System (Chess AI Opponents with Cheat Abilities)

Bosses are **chess AI opponents** — both the player and the boss have full standard chess piece sets (8 pawns, 2 knights, 2 bishops, 2 rooks, 1 queen, 1 king). The boss plays standard chess but has **special cheat abilities** that break normal rules. Win condition: **checkmate the boss's king**.

**The boss is NOT a piece on the board** — it's the AI controlling the black pieces. There are **no standalone enemies during boss fights**, just the chess match plus gimmicks.

### Boss Turn Order
1. **Player moves** (standard chess)
2. **Boss moves** (standard chess, AI-controlled)
3. **Boss cheats activate** (if any are applicable this turn)
4. Back to player

---

### BOSS 1: King's Son (Overworld) — Medium AI
*Makes a bad move every 3 turns*

#### Cheat 1 — "Go! My Horses!"
- Both knights pulse yellow and each advance forward (extra knight-only turn)
- If a knight was captured: it **revives** on its original home square and proceeds
- If a knight is elsewhere: it **teleports** back to its home square, then moves
- If a piece (even its own) occupies the home square: it gets **captured** to make room
- Safety rule: The king can never be on a square the horses can reach
- Duration: Both knights move every turn for **5 turns straight** (no other pieces move during cheat)
- **Cancellation:** If 1 horse is captured during the cheat, the cheat ends AND the boss **loses 1 turn** (player gets an extra move)

#### Cheat 2 — "Wah Wah Wah!"
- After the horse cheat ends, boss **shakes the board**
- 1 random white piece AND 1 random black piece fall off (removed from play)
- Cannot remove queens or kings
- If a horse gets knocked off, the horse cheat won't trigger next time

---

### BOSS 2: Queen (Pirate Seas / Beach) — Low AI
*Makes a bad move every 5 turns*

#### Cheat 1 — "Cut the Slack!"
- On turn 1: Sacrifices **3 pawns** to create **1 new queen** at the middle pawn's position
- Repeats every 3 turns if enough pawns remain
- Order: left pawns first, then right pawns, then middle pawns

#### Cheat 2 — "Enchant!"
- Covers a piece in a **purple glowing shield**
- When that shielded piece is captured, it **explodes in a 3×3 radius**
- Explosion kills **both black AND white pieces** in the radius
- **Kings are immune to explosion damage** (failsafe — kings can never die from explosions)
- Can only enchant **special pieces** (not pawns)
- Turn 2: Enchants the first queen created by Cut the Slack
- Every 3 turns after: Enchants a random non-pawn piece

---

### BOSS 3: Jester (Volcanic Wasteland) — Medium AI
*Makes a bad move every 4 turns*

#### Cheat 1 — "Rookie Mistake!"
- At start: All back-rank pieces shift down 1 tile (to 7th rank), freeing the 8th rank
- 8th rank fills with **8 rooks**
- Every 3 turns: All 8 rooks **slam downward simultaneously** through the board, capturing any white pieces in their path
- Rooks stop if they hit a **black piece** (won't go through their own)
- After slamming, rooks return to the 8th rank

#### Cheat 2 — "Mind Control!"
- During the player's turn, the Jester **moves one of your pieces for you** using lowest-level AI
- The player **cannot** see which piece will be moved beforehand
- This does NOT skip your turn — you still get your normal move after

---

### BOSS 4: The King (Final Boss) — Strong AI

#### Phase 1 — "Look Who's on Top Now!"
- Before the match: All pawns transform into **kings**
- Boss only moves kings until all extra kings are defeated
- Once only the original king remains → triggers Phase 2

#### Phase 2 — "Back Off!"
- All pieces reset to their original starting positions
- All pawns are revived
- Every 2 turns, the King does one of the following (random):

| Ability | Effect |
|---------|--------|
| **"I'm Invulnerable Now!"** | King levitates for 3 turns — cannot be targeted or captured |
| **"Oh, I'll Pity You..."** | King flicks one of his own pawns over to your side (you gain it) |
| **"That Move Doesn't Count!"** | Undoes your last move (captures are also undone) |
| **"I... I Don't Know..."** | King freezes — loses his turn |

---

## All Questions Resolved ✅

| # | Question | Answer |
|---|----------|--------|
| 1 | Enemy vs Boss distinction | Enemies are standalone hostiles; bosses play standard chess with cheats, no enemies on board |
| 2 | Player piece HP | No HP tracking — standard chess capture rules (one hit = dead) |
| 3 | Enemy spawn locations | Random on ranks 8-6, customizable per enemy (lane, exact tile, etc.) |
| 4 | Turn order | Player → enemies (enemy levels) / Player → boss move → boss cheats (boss levels) |
| 5 | Boss cheat timing | End of boss turn, after their chess move |
| 6 | Enchant explosion | Hits both sides, kings immune |
| 7 | Mind Control visibility | No — player can't see which piece will be moved |
| 8 | Rook slam | All 8 simultaneously |
| 9 | Multi-tile knockback | Whole piece shifts 1 tile in attack direction, smooth motion |
| 10 | Enemy attack on player pieces | Two types: melee (move onto to capture) and ranged (projectile/slash without moving) |
| 11 | Multiple enemies same target | First to highlight strikes first; second follows normal rules after |
| 12 | Enemy-on-enemy collision | Cannot share tiles; pushed back to original square if they try |
| 13 | Boss levels + enemies | Boss levels are chess-only (no standalone enemies), just pieces + gimmicks |
| 14 | Enemy death effects | Shake red, fade away |
| 15 | Knockback into other enemies | Other enemy is immovable wall; knocked-back enemy stays put |
