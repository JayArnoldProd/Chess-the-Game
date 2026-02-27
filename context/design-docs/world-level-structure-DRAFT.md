# World & Level Structure — DRAFT (Not Implementing Yet)

*Early design notes from Jas + Jay. Needs further refinement before PRPs are created.*

---

## Terminology
- **Worlds** = the current rooms (Ruined Overworld, Pirate Seas, Volcanic Wasteland, etc.)
- **Levels** = stages within each world (enemy encounters + boss)
- 4 worlds total

## Level Structure Per World

| Level | Content |
|-------|---------|
| 1 | 1 Enemy |
| 2 | 1 Enemy |
| 3 | 2 Enemies |
| 4 | 3 Enemies |
| 5 | Miniboss (1 special enemy) |
| 6 | Bonus Level (Boss fight) |

## Bonus Level (Boss Fight) Rules
- Losing does **NOT** result in game over — player keeps going
- Winning gives a **Crown** reward
- **Crown effect:** If your king is captured, it revives on a free tile on the back rank (one-time extra life)
- No punishment for losing (for now — may evolve)
- **Bosses are OFF-SCREEN** — they are NOT pieces on the board. You just see their black chess pieces. Bosses may have dialogue sprites in the future but no board sprites.
- Minibosses (Level 5) are different — they ARE on the board as enemy units

## Secret Content
- If a player wins all 4 boss fights, they unlock a **secret miniboss** instead of the final boss

## Progression Rules (Confirmed by Jas)
- **Losing sends you back to World 1** (roguelike reset — at least for now)
- **All pieces get revived after Level 5** (full restore before the bonus boss level)
- No punishment for losing the Level 6 bonus boss fight specifically

## Open Design Questions
- Global progression: Jay strongly recommends permanent progress that persists across sessions (unlocked worlds, etc.)
- Reward-over-punishment philosophy: Rather than punishing losses, reward wins
- Losing penalty may be softened over time — roguelike reset is harsh for casual players
- Mobile port: Jas planning art for top/bottom of screen (grass or detailed backgrounds)

## Design Philosophy (from Jay)
- Keep mechanics simple — don't require text explanations
- Progression should feel natural and intuitive
- Don't over-punish — replaying the level IS the punishment
- The system will evolve as the game develops
- Simpler mechanics benefit the game as a whole

---

*This document will be expanded into proper PRPs once the enemy/boss foundation is built and tested.*
