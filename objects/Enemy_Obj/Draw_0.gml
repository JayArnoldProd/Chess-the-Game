/// Enemy_Obj Draw Event

// Get tint color from definition (default orange)
var _tint = (enemy_def != undefined && variable_struct_exists(enemy_def, "tint_color")) 
    ? enemy_def.tint_color : make_color_rgb(255, 140, 0);

// Sprite is drawn flipped (yscale=-1) from origin (0,0 = top-left).
// So the visible sprite occupies: x to x+24, y-24 to y.
// We draw offset so sprite is centered on tile: draw at (x, y + 24)
// This makes the flipped sprite render from y+24 up to y, filling the tile.
var _draw_x = x;
var _draw_y = y + Board_Manager.tile_size;

// Death animation
if (is_dead) {
    var _alpha = 1 - (death_timer / death_duration);
    var _shake_x = irandom_range(-death_shake_intensity, death_shake_intensity);
    var _shake_y = irandom_range(-death_shake_intensity, death_shake_intensity);
    
    draw_sprite_ext(
        Pawn_Sprite, 0,
        _draw_x + _shake_x, _draw_y + _shake_y,
        1, -1, 0,
        c_red, _alpha
    );
    exit;
}

// Hit flash — blend toward red when recently damaged
if (hit_flash_timer > 0) {
    hit_flash_timer--;
    var _flash_intensity = hit_flash_timer / hit_flash_duration;
    _tint = merge_color(_tint, c_red, _flash_intensity);
}

// Normal draw — upside-down pawn tinted orange to distinguish from chess pieces
draw_sprite_ext(Pawn_Sprite, 0, _draw_x, _draw_y, 1, -1, 0, _tint, 1);

// HP bar (only if max_hp > 1)
if (draw_hp_bar && max_hp > 1) {
    var _bar_width = 20;
    var _bar_height = 4;
    var _bar_x = x + (Board_Manager.tile_size - _bar_width) / 2;  // Centered on tile
    var _bar_y = y + Board_Manager.tile_size - _bar_height - 2;  // Just inside bottom of tile
    
    // Background
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _bar_width, _bar_y + _bar_height,
        c_maroon, c_maroon, c_maroon, c_maroon, false
    );
    
    // HP fill
    var _hp_ratio = current_hp / max_hp;
    var _fill_width = _bar_width * _hp_ratio;
    var _hp_color = merge_color(c_red, c_lime, _hp_ratio);
    
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _fill_width, _bar_y + _bar_height,
        _hp_color, _hp_color, _hp_color, _hp_color, false
    );
    
    // Border
    draw_rectangle_color(
        _bar_x, _bar_y,
        _bar_x + _bar_width, _bar_y + _bar_height,
        c_black, c_black, c_black, c_black, true
    );
}
