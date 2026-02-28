/// Enemy_Obj Step Event

// Update audio emitter position
audio_emitter_position(audio_emitter, x, y, 0);

// Movement interpolation
if (is_moving) {
    move_progress += 1 / move_duration;
    if (move_progress >= 1) {
        move_progress = 1;
        is_moving = false;
        x = move_target_x;
        y = move_target_y;
        
        if (instance_exists(Object_Manager) && instance_exists(Board_Manager)) {
            grid_col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            grid_row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        }
        
        // Hazard check after landing (e.g. conveyor pushed onto water/void)
        var _cx = x + Board_Manager.tile_size / 2;
        var _cy = y + Board_Manager.tile_size / 2;
        // Prefer world tile map (align with AI/world system)
        var _world = ai_build_virtual_world();
        var _tiles = (_world != undefined) ? _world.tiles : undefined;
        var _bridges = (_world != undefined) ? _world.objects.bridges : undefined;
        
        if (_tiles != undefined && grid_col >= 0 && grid_col < 8 && grid_row >= 0 && grid_row < 8) {
            var _tile_type = _tiles[grid_row][grid_col];
            if (_tile_type == 1) {
                var _has_bridge = false;
                if (_bridges != undefined) {
                    for (var b = 0; b < array_length(_bridges); b++) {
                        if (_bridges[b].col == grid_col && _bridges[b].row == grid_row) { _has_bridge = true; break; }
                    }
                }
                if (!_has_bridge) {
                    show_debug_message("Enemy drowned at (" + string(grid_col) + "," + string(grid_row) + ")");
                    audio_play_sound(Piece_Drowning_SFX, 0, false);
                    is_dead = true;
                }
            } else if (_tile_type == -1) {
                show_debug_message("Enemy fell into void at (" + string(grid_col) + "," + string(grid_row) + ")");
                is_dead = true;
            }
        } else {
            // Fallback: instance checks
            var _landed_tile = instance_place(_cx, _cy, Tile_Obj);
            if (_landed_tile == noone) _landed_tile = instance_place(x + Board_Manager.tile_size / 4, y + Board_Manager.tile_size / 4, Tile_Obj);
            if (_landed_tile == noone) _landed_tile = instance_place(x, y, Tile_Obj);
            
            if (_landed_tile != noone && variable_instance_exists(_landed_tile, "tile_type")) {
                if (_landed_tile.tile_type == 1) {
                    var _bridge = instance_place(_cx, _cy, Bridge_Obj);
                    if (_bridge == noone) _bridge = instance_place(x + Board_Manager.tile_size / 4, y + Board_Manager.tile_size / 4, Bridge_Obj);
                    if (_bridge == noone) _bridge = instance_place(x, y, Bridge_Obj);
                    if (_bridge == noone) {
                        show_debug_message("Enemy drowned at (" + string(grid_col) + "," + string(grid_row) + ")");
                        audio_play_sound(Piece_Drowning_SFX, 0, false);
                        is_dead = true;
                    }
                } else if (_landed_tile.tile_type == -1) {
                    show_debug_message("Enemy fell into void at (" + string(grid_col) + "," + string(grid_row) + ")");
                    is_dead = true;
                }
            } else {
                var _bridge = instance_place(_cx, _cy, Bridge_Obj);
                if (_bridge == noone) _bridge = instance_place(x + Board_Manager.tile_size / 4, y + Board_Manager.tile_size / 4, Bridge_Obj);
                if (_bridge == noone) _bridge = instance_place(x, y, Bridge_Obj);
                if (_bridge == noone) {
                    show_debug_message("Enemy drowned at (" + string(grid_col) + "," + string(grid_row) + ") — no tile + no bridge");
                    audio_play_sound(Piece_Drowning_SFX, 0, false);
                    is_dead = true;
                }
            }
        }
        
        // Check if pushed off the board entirely
        if (grid_col < 0 || grid_col > 7 || grid_row < 0 || grid_row > 7) {
            show_debug_message("Enemy pushed off board at (" + string(grid_col) + "," + string(grid_row) + ")");
            is_dead = true;
        }
    } else {
        var _t = easeInOutQuad(move_progress);
        x = lerp(move_start_x, move_target_x, _t);
        y = lerp(move_start_y, move_target_y, _t);
    }
}

// Death animation
if (is_dead && !is_moving) {
    death_timer++;
    if (death_timer >= death_duration) {
        if (instance_exists(Enemy_Manager)) {
            var _idx = array_get_index(Enemy_Manager.enemy_list, id);
            if (_idx >= 0) {
                array_delete(Enemy_Manager.enemy_list, _idx, 1);
            }
        }
        instance_destroy();
    }
}
