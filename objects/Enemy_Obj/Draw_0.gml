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

// Hovered enemy move + attack range preview
if (instance_exists(Game_Manager) && Game_Manager.hovered_enemy == self && !is_dead && !is_moving) {
    var _world = ai_build_virtual_world();
    var _tiles = (_world != undefined) ? _world.tiles : undefined;
    var _bridges = (_world != undefined) ? _world.objects.bridges : undefined;
    var _board = (_world != undefined) ? _world.board : undefined;
    var _ts = Board_Manager.tile_size;
    
    // --- Move range (light blue)
    draw_set_alpha(0.35);
    draw_set_color(make_color_rgb(120, 180, 255));
    
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            var _col = grid_col + dx;
            var _row = grid_row + dy;
            if (_col < 0 || _col > 7 || _row < 0 || _row > 7) continue;
            
            // Water/void checks via world tile map
            if (_tiles != undefined) {
                var _tile_type = _tiles[_row][_col];
                if (_tile_type == -1) continue;
                if (_tile_type == 1) {
                    var _has_bridge = false;
                    if (_bridges != undefined) {
                        for (var b = 0; b < array_length(_bridges); b++) {
                            if (_bridges[b].col == _col && _bridges[b].row == _row) { _has_bridge = true; break; }
                        }
                    }
                    if (!_has_bridge) continue;
                }
            }
            
            var _px = Object_Manager.topleft_x + _col * _ts;
            var _py = Object_Manager.topleft_y + _row * _ts;
            
            // Stepping stones are walls
            if (instance_place(_px, _py, Stepping_Stone_Obj)) continue;
            // Factory droppers are deadly — avoid them
            if (instance_place(_px, _py, Factory_Dropper_Obj)) continue;
            
            // Other enemies block
            var _other_enemy = false;
            for (var e = 0; e < array_length(Enemy_Manager.enemy_list); e++) {
                var _oe = Enemy_Manager.enemy_list[e];
                if (instance_exists(_oe) && _oe != self && _oe.grid_col == _col && _oe.grid_row == _row) { _other_enemy = true; break; }
            }
            if (_other_enemy) continue;
            
            // Chess pieces block (AI pieces + king), player pieces are capturable
            var _piece_struct = (_board != undefined) ? _board[_row][_col] : noone;
            if (_piece_struct != noone) {
                if (_piece_struct.piece_type == 1 || _piece_struct.piece_id == "king") continue;
            } else {
                var _piece = instance_place(_px, _py, Chess_Piece_Obj);
                if (_piece != noone && (_piece.piece_type == 1 || _piece.piece_id == "king")) continue;
            }
            
            draw_rectangle(_px, _py, _px + _ts, _py + _ts, false);
        }
    }
    
    // --- Attack range (red)
    draw_set_alpha(0.35);
    draw_set_color(c_red);
    var _aw = (enemy_def != undefined && variable_struct_exists(enemy_def, "attack_site_width")) ? enemy_def.attack_site_width : 1;
    var _ah = (enemy_def != undefined && variable_struct_exists(enemy_def, "attack_site_height")) ? enemy_def.attack_site_height : 1;
    var _hw = floor(_aw / 2);
    var _hh = floor(_ah / 2);
    
    for (var ax = -_hw; ax <= _hw; ax++) {
        for (var ay = -_hh; ay <= _hh; ay++) {
            var _col = grid_col + ax;
            var _row = grid_row + ay;
            if (_col < 0 || _col > 7 || _row < 0 || _row > 7) continue;
            
            // Skip tiles occupied by enemy-controlled pieces (AI pieces or other enemies)
            var _skip = false;
            if (_board != undefined) {
                var _p = _board[_row][_col];
                if (_p != noone && (_p.piece_type == 1 || _p.piece_id == "enemy")) _skip = true;
            } else {
                var _pinst = instance_place(Object_Manager.topleft_x + _col * _ts, Object_Manager.topleft_y + _row * _ts, Chess_Piece_Obj);
                if (_pinst != noone && _pinst.piece_type == 1) _skip = true;
                var _einst = instance_position(Object_Manager.topleft_x + _col * _ts, Object_Manager.topleft_y + _row * _ts, Enemy_Obj);
                if (_einst != noone && _einst != self) _skip = true;
            }
            if (_skip) continue;
            
            var _px = Object_Manager.topleft_x + _col * _ts;
            var _py = Object_Manager.topleft_y + _row * _ts;
            // Stepping stones are walls — don't show on them
            if (instance_place(_px, _py, Stepping_Stone_Obj)) continue;
            
            draw_rectangle(_px, _py, _px + _ts, _py + _ts, false);
        }
    }
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}

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
