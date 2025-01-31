//Foreground_Obj Draw
width = sprite_get_width(sprite_index);
height = sprite_get_height(sprite_index);

// Layer 1 (always draw)
draw_sprite_ext(sprite_index, 0, x1, y1, 1, 1, 0, image_blend, image_alpha*.5);  // Changed image_index to 0
draw_sprite_ext(sprite_index, 0, x1-width, y1-height, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1-width, y1, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1-width, y1+height, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1, y1-height, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1, y1+height, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1+width, y1-height, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1+width, y1, 1, 1, 0, image_blend, image_alpha*.5);
draw_sprite_ext(sprite_index, 0, x1+width, y1+height, 1, 1, 0, image_blend, image_alpha*.5);

// Layer 2
draw_sprite_ext(sprite_index, 1, x2, y2, 1, 1, 0, image_blend, image_alpha*.75);  // Changed image_index to 1
draw_sprite_ext(sprite_index, 1, x2-width, y2-height, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2-width, y2, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2-width, y2+height, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2, y2-height, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2, y2+height, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2+width, y2-height, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2+width, y2, 1, 1, 0, image_blend, image_alpha*.75);
draw_sprite_ext(sprite_index, 1, x2+width, y2+height, 1, 1, 0, image_blend, image_alpha*.75);

// Layer 3
draw_sprite_ext(sprite_index, 2, x3, y3, 1, 1, 0, image_blend, image_alpha);  // Changed image_index to 2
draw_sprite_ext(sprite_index, 2, x3-width, y3-height, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3-width, y3, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3-width, y3+height, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3, y3-height, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3, y3+height, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3+width, y3-height, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3+width, y3, 1, 1, 0, image_blend, image_alpha);
draw_sprite_ext(sprite_index, 2, x3+width, y3+height, 1, 1, 0, image_blend, image_alpha);