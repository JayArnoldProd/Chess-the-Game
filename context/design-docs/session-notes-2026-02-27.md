# Session Notes — Feb 27, 2026

Quick summary of what we captured from tonight's conversation and where things stand.

---

## What's Being Built Now
- **14 PRPs** (detailed implementation plans) covering the full enemy + boss system
- PRP-008 through PRP-016 (enemy system) are done
- PRP-017 through PRP-021 (boss framework + all 4 bosses) are being generated now
- All PRPs include GML code examples, architecture diagrams, and success criteria
- **First implementation target:** Placeholder test enemy (PRP-016) — get 1 enemy spawning and working before anything else

## World/Level Structure (Future — NOT Implementing Yet)
- Current rooms (Ruined Overworld, Pirate Seas, etc.) = **Worlds**
- Each world has 6 levels:
  - Level 1: 1 enemy
  - Level 2: 1 enemy
  - Level 3: 2 enemies
  - Level 4: 3 enemies
  - Level 5: Miniboss (1 special enemy)
  - Level 6: Bonus Level (boss fight)
- 4 worlds total
- Secret miniboss if player beats all 4 bosses

## Bonus Level (Still Being Designed)
- No punishment for losing boss fights (for now)
- Winning gives a **Crown** reward — if your king gets captured later, it revives on a free back-rank tile (one-time extra life)
- Losing/punishment mechanics intentionally deferred — Jas is still thinking through it

## Design Philosophy
- Keep it simple — don't over-punish, progression should feel natural
- Don't require text explanations for mechanics
- Reward winning rather than punishing losing
- Replaying the level is punishment enough
- Global progression that persists across sessions is key
- The system will evolve as the game develops

## What's NOT Changing
- All existing mechanics stay (stepping stones, water, conveyors, void, lava, carnival spawns)
- AI system stays — we're extending it for bosses, not rewriting it
- Current levels/rooms stay as-is for now

## Next Steps
1. Boss PRPs finish generating (tonight)
2. Full cross-reference review of all PRPs against code
3. Begin implementation starting with PRP-008 (enemy data architecture)
4. Build up through the placeholder enemy test (PRP-016)
5. Then tackle bosses (PRP-017+)
