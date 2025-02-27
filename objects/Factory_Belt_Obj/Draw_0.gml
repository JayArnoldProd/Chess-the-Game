// -----------------------------
// Factory_Belt_Obj Draw Event
// -----------------------------
var tile_size = Board_Manager.tile_size;   // e.g., 24 pixels
var total_tiles = 6;
var belt_width = total_tiles * tile_size;    // e.g., 144 pixels
var belt_height = tile_size;                 // e.g., 24 pixels

// Compute effective_position in tile-units depending on belt direction.
var effective_position;
if (!right_direction) {
    // Left-facing: position increases.
    // Compute positive difference, accounting for wrapping.
    var diff = ((target_position - old_position) + total_tiles) mod total_tiles;
    effective_position = old_position + belt_anim_progress * diff;
} else {
    // Right-facing: position decreases.
    var diff = ((old_position - target_position) + total_tiles) mod total_tiles;
    effective_position = old_position - belt_anim_progress * diff;
}

// Convert effective_position to a pixel offset.
var effective_offset = effective_position * tile_size;
// Normalize offset to be within [0, belt_width)
if (effective_offset < 0) {
    effective_offset += belt_width;
}
if (effective_offset >= belt_width) {
    effective_offset -= belt_width;
}

// Compute width of first part.
var part1_width = belt_width - effective_offset;

// Draw the first part: from effective_offset to the end of the sprite.
draw_sprite_part_ext(Factory_Belt_Sprite, 0, effective_offset, 0, part1_width, belt_height, 
    x, y, 1, 1, c_white, 1);

// Draw the second part: from the beginning up to effective_offset.
draw_sprite_part_ext(Factory_Belt_Sprite, 0, 0, 0, effective_offset, belt_height, 
    x + part1_width, y, 1, 1, c_white, 1);