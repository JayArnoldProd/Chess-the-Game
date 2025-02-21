// Factory_Belt_Obj Draw Event

// Belt dimensions (in pixels)
var belt_width = 144;  // 6 tiles * 24 pixels per tile
var belt_height = 24;  // height of one tile

// Compute pixel offset (in pixels)
var pixel_offset = position * 24;
var part1_width = belt_width - pixel_offset;

// Draw the first part: from pixel_offset to the end of the sprite.
draw_sprite_part_ext(Factory_Belt_Sprite, 0, pixel_offset, 0, part1_width, belt_height, 
    x, y, 1, 1, c_white, 1);

// Draw the second part: from the beginning up to pixel_offset.
draw_sprite_part_ext(Factory_Belt_Sprite, 0, 0, 0, pixel_offset, belt_height, 
    x + part1_width, y, 1, 1, c_white, 1);
