// -----------------------------
// Factory_Belt_Obj Step Event (Turn-Based Smooth Animation)
// -----------------------------
var tile_size   = Board_Manager.tile_size;      // e.g., 24 pixels per tile
var total_tiles = 6;                             // belt spans 6 tiles
var belt_width  = total_tiles * tile_size;        // e.g., 144 pixels

// --- Start a new animation cycle when the turn changes.
if (Game_Manager.turn != last_turn && !animating) {
    old_position = position;
    if (!right_direction) {
        // Belt moves one tile to the right.
        target_position = (position + 1) mod total_tiles;
    } else {
        // Belt moves one tile to the left.
        target_position = (position - 1 + total_tiles) mod total_tiles;
    }
    belt_anim_progress = 0;
    animating = true;
    
    // Randomly choose one of the three conveyor sounds.
    var rnd = irandom_range(1, 3);
    var conveyer_sound;
    if (rnd == 1) {
        conveyer_sound = Conveyer_SFX_1;
    } else if (rnd == 2) {
        conveyer_sound = Conveyer_SFX_2;
    } else {
        conveyer_sound = Conveyer_SFX_3;
    }
    audio_play_sound_on(audio_emitter, conveyer_sound, 0, false);
}

// --- Update animation progress.
if (animating) {
    belt_anim_progress += belt_speed;
    if (belt_anim_progress >= 1) {
        belt_anim_progress = 1;
        animating = false;
        // Snap belt to its new discrete position.
        position = target_position;
        last_turn = Game_Manager.turn;
        // Reset continuous offset (if used for drawing).
        last_unwrapped_offset = position * tile_size;
    }
}

// --- Compute piece movement per frame.
// We want pieces to move a constant amount each frame so that over a full cycle they move exactly tile_size pixels.
// The per-frame movement is: tile_size * belt_speed.
var piece_delta = animating ? (right_direction ? -tile_size * belt_speed : tile_size * belt_speed) : 0;

// --- Define belt boundaries. Extend horizontally by one tile so that pieces near the edges are carried.
var belt_left   = x;
var belt_top    = y;
var belt_right  = x + belt_width;
var belt_bottom = y + tile_size;

// --- Move any Chess_Piece_Obj that is on (or near) the belt.
with (Chess_Piece_Obj) {
    var cx = x + sprite_width * 0.5;
    var cy = y + sprite_height * 0.5;
    if (cx >= (belt_left - tile_size) && cx <= (belt_right + tile_size) &&
        cy >= belt_top && cy <= belt_bottom) {
        x -= piece_delta;
    }
}

// --- Final Snap: When the belt animation finishes, force pieces on the belt to be exactly on grid.
// This prevents any cumulative floating-point drift.
if (!animating) {
    with (Chess_Piece_Obj) {
        var cx = x + sprite_width * 0.5;
        var cy = y + sprite_height * 0.5;
        if (cx >= (belt_left - tile_size) && cx <= (belt_right + tile_size) &&
            cy >= belt_top && cy <= belt_bottom) {
            var offset = x - belt_left;
            offset = round(offset / tile_size) * tile_size;
            x = belt_left + offset;
        }
    }
}