// Game_Manager Draw Event (world space)

// Enemy hover overlays in world space
if (!game_over && hovered_enemy != noone && instance_exists(hovered_enemy)) {
    var _en = hovered_enemy;
    var _world = ai_build_virtual_world();
    var _tiles = (_world != undefined) ? _world.tiles : undefined;
    var _bridges = (_world != undefined) ? _world.objects.bridges : undefined;
    var _board = (_world != undefined) ? _world.board : undefined;
    var _ts = Board_Manager.tile_size;
    
    var _move_map = array_create(8);
    var _attack_map = array_create(8);
    for (var r = 0; r < 8; r++) {
        _move_map[r] = array_create(8, false);
        _attack_map[r] = array_create(8, false);
    }
    
    var _move_color = make_color_rgb(120, 180, 255);
    var _attack_color = c_red;
    
    // Move range
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            var _col = _en.grid_col + dx;
            var _row = _en.grid_row + dy;
            if (_col < 0 || _col > 7 || _row < 0 || _row > 7) continue;
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
            var _stone = instance_position(_px + _ts * 0.5, _py + _ts * 0.5, Stepping_Stone_Obj);
            if (_stone != noone) continue;
            if (instance_place(_px, _py, Factory_Dropper_Obj)) continue;
            var _other_enemy = false;
            for (var e = 0; e < array_length(Enemy_Manager.enemy_list); e++) {
                var _oe = Enemy_Manager.enemy_list[e];
                if (instance_exists(_oe) && _oe != _en && _oe.grid_col == _col && _oe.grid_row == _row) { _other_enemy = true; break; }
            }
            if (_other_enemy) continue;
            var _piece_struct = (_board != undefined) ? _board[_row][_col] : noone;
            if (_piece_struct != noone) {
                // Movement should NOT include any occupied piece (player or AI)
                if (_piece_struct.piece_type == 1 || _piece_struct.piece_id == "king" || _piece_struct.piece_type == 0) continue;
            } else {
                var _piece = instance_place(_px, _py, Chess_Piece_Obj);
                if (_piece != noone && (_piece.piece_type == 1 || _piece.piece_id == "king" || _piece.piece_type == 0)) continue;
            }
            _move_map[_row][_col] = true;
        }
    }
    
    // Attack range
    var _aw = (variable_struct_exists(_en.enemy_def, "attack_site_width")) ? _en.enemy_def.attack_site_width : 1;
    var _ah = (variable_struct_exists(_en.enemy_def, "attack_site_height")) ? _en.enemy_def.attack_site_height : 1;
    var _hw = floor(_aw / 2);
    var _hh = floor(_ah / 2);
    for (var ax = -_hw; ax <= _hw; ax++) {
        for (var ay = -_hh; ay <= _hh; ay++) {
            var _col = _en.grid_col + ax;
            var _row = _en.grid_row + ay;
            if (_col < 0 || _col > 7 || _row < 0 || _row > 7) continue;
            var _skip = false;
            if (_board != undefined) {
                var _p = _board[_row][_col];
                if (_p != noone && (_p.piece_type == 1 || _p.piece_id == "enemy")) _skip = true;
            } else {
                var _pinst = instance_place(Object_Manager.topleft_x + _col * _ts, Object_Manager.topleft_y + _row * _ts, Chess_Piece_Obj);
                if (_pinst != noone && _pinst.piece_type == 1) _skip = true;
                var _einst = instance_position(Object_Manager.topleft_x + _col * _ts, Object_Manager.topleft_y + _row * _ts, Enemy_Obj);
                if (_einst != noone && _einst != _en) _skip = true;
            }
            if (_skip) continue;
            if (_tiles != undefined) {
                var _tile_type = _tiles[_row][_col];
                if (_tile_type == -1) continue;
                if (_tile_type == 1) {
                    var _has_bridge = false;
                    if (_bridges != undefined) {
                        for (var bb = 0; bb < array_length(_bridges); bb++) {
                            if (_bridges[bb].col == _col && _bridges[bb].row == _row) { _has_bridge = true; break; }
                        }
                    }
                    if (!_has_bridge) continue;
                }
            }
            var _px = Object_Manager.topleft_x + _col * _ts;
            var _py = Object_Manager.topleft_y + _ts * _row;
            var _stone = instance_position(_px + _ts * 0.5, _py + _ts * 0.5, Stepping_Stone_Obj);
            if (_stone != noone) continue;
            _attack_map[_row][_col] = true;
        }
    }
    
    // If a player piece is on a tile, force it to be attack-only (no blue/stripes)
    for (var rr = 0; rr < 8; rr++) {
        for (var cc = 0; cc < 8; cc++) {
            var _pp = (_board != undefined) ? _board[rr][cc] : noone;
            var _has_player = (_pp != noone && _pp.piece_type == 0);
            if (!_has_player) {
                var _px = Object_Manager.topleft_x + cc * _ts;
                var _py = Object_Manager.topleft_y + rr * _ts;
                var _inst = instance_place(_px, _py, Chess_Piece_Obj);
                if (_inst != noone && _inst.piece_type == 0) _has_player = true;
            }
            if (_has_player) {
                _move_map[rr][cc] = false; // no blue or stripes on player pieces
            }
        }
    }
    
    // Draw non-overlap
    draw_set_alpha(0.6); // stronger alpha for blue + red
    for (var rr = 0; rr < 8; rr++) {
        for (var cc = 0; cc < 8; cc++) {
            if (_move_map[rr][cc] && !_attack_map[rr][cc]) {
                draw_set_color(_move_color);
            } else if (_attack_map[rr][cc] && !_move_map[rr][cc]) {
                draw_set_color(_attack_color);
            } else {
                continue;
            }
            var _px = Object_Manager.topleft_x + cc * _ts;
            var _py = Object_Manager.topleft_y + rr * _ts;
            var _stone2 = instance_position(_px + _ts * 0.5, _py + _ts * 0.5, Stepping_Stone_Obj);
            if (_stone2 != noone) continue; // never draw on stepping stones
            draw_rectangle(_px, _py, _px + _ts, _py + _ts, false);
        }
    }
    
    // Overlap stripes (vertical, 3 blue / 2 red)
    var _stripe_count = 5;
    var _stripe_w = ceil(_ts / _stripe_count);
    for (var rr = 0; rr < 8; rr++) {
        for (var cc = 0; cc < 8; cc++) {
            if (!_move_map[rr][cc] || !_attack_map[rr][cc]) continue;
            var _px = Object_Manager.topleft_x + cc * _ts;
            var _py = Object_Manager.topleft_y + rr * _ts;
            var _stone2 = instance_position(_px + _ts * 0.5, _py + _ts * 0.5, Stepping_Stone_Obj);
            if (_stone2 != noone) continue; // never draw on stepping stones
            for (var i = 0; i < _stripe_count; i++) {
                var _s = i * _stripe_w;
                var _is_blue = (i mod 2 == 0); // blue, red, blue, red, blue
                draw_set_color(_is_blue ? _move_color : _attack_color);
                draw_rectangle(_px + _s, _py, _px + min(_ts, _s + _stripe_w), _py + _ts, false);
            }
        }
    }
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}
