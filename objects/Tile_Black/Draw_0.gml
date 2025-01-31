//Tile_White Draw Event
var center_x = x;
var center_y = y;

// Adjust center based on rotation
switch (image_angle_) {
    case 0:   // No rotation
        center_x = x;
        center_y = y;
        break;
    case 90:  // 90 degrees
        center_x = x;
        center_y = y + sprite_width;
        break;
    case 180: // 180 degrees
        center_x = x + sprite_width;
        center_y = y + sprite_height;
        break;
    case 270: // 270 degrees
        center_x = x + sprite_height;
        center_y = y;
        break;
}

draw_sprite_ext(
    sprite_index,
    image_index,
    center_x,
    center_y,
    1,
    1,
    image_angle_,
    color,
    image_alpha
);