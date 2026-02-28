/// @function enemy_process_turn(_enemy)
/// @param {Id.Instance} _enemy The enemy instance to process
/// @description Finds target and moves enemy 1 tile toward it (king-style movement)
function enemy_process_turn(_enemy) {
    if (!instance_exists(_enemy)) return;
    if (_enemy.is_dead || _enemy.is_moving) return;
    
    // Find closest player piece
    var _target = enemy_find_target(_enemy);
    if (_target == noone) {
        show_debug_message("Enemy at (" + string(_enemy.grid_col) + "," + string(_enemy.grid_row) + "): No target found");
        return;
    }
    
    var _target_col = round((_target.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _target_row = round((_target.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    // unused but kept for reference
    var _target_is_king = (_target.piece_id == "king");
    
    show_debug_message("Enemy at (" + string(_enemy.grid_col) + "," + string(_enemy.grid_row) + 
        ") targeting " + _target.piece_id + " at (" + string(_target_col) + "," + string(_target_row) + ")");
    
    // Build world tile map once (aligns with AI/world systems)
    var _world = ai_build_virtual_world();
    var _tiles = (_world != undefined) ? _world.tiles : undefined;
    var _bridges = (_world != undefined) ? _world.objects.bridges : undefined;
    var _board = (_world != undefined) ? _world.board : undefined;
    
    // Evaluate all 8 adjacent tiles, pick the one closest to target
    var _best_col = _enemy.grid_col;
    var _best_row = _enemy.grid_row;
    var _best_dist = abs(_target_col - _enemy.grid_col) + abs(_target_row - _enemy.grid_row);
    var _best_has_capture = false;
    var _valid_moves = []; // Track all valid moves for fallback
    var _blocked_reasons = ""; // Debug logging
    
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            
            var _col = _enemy.grid_col + dx;
            var _row = _enemy.grid_row + dy;
            
            // Bounds check
            if (_col < 0 || _col > 7 || _row < 0 || _row > 7) continue;
            
            var _px = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
            var _py = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
            var _cx = _px + Board_Manager.tile_size / 2;
            var _cy = _py + Board_Manager.tile_size / 2;
            
            // Tile type from world map (align with AI/world system)
            if (_tiles != undefined) {
                var _tile_type = _tiles[_row][_col];
                if (_tile_type == -1) {
                    _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=void ";
                    continue;
                }
                if (_tile_type == 1) {
                    var _has_bridge = false;
                    if (_bridges != undefined) {
                        for (var b = 0; b < array_length(_bridges); b++) {
                            if (_bridges[b].col == _col && _bridges[b].row == _row) { _has_bridge = true; break; }
                        }
                    }
                    if (!_has_bridge) {
                        _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=water ";
                        continue;
                    }
                }
            } else {
                // Fallback: instance checks if world map unavailable
                var _tile = instance_place(_cx, _cy, Tile_Obj);
                if (_tile == noone) _tile = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Tile_Obj);
                if (_tile == noone) _tile = instance_place(_px, _py, Tile_Obj);
                if (_tile == noone) {
                    var _bridge = instance_place(_cx, _cy, Bridge_Obj);
                    if (_bridge == noone) _bridge = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Bridge_Obj);
                    if (_bridge == noone) _bridge = instance_place(_px, _py, Bridge_Obj);
                    if (_bridge == noone) {
                        _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=no_tile ";
                        continue;
                    }
                } else if (variable_instance_exists(_tile, "tile_type")) {
                    if (_tile.tile_type == -1) {
                        _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=void ";
                        continue;
                    }
                    if (_tile.tile_type == 1) {
                        var _bridge = instance_place(_cx, _cy, Bridge_Obj);
                        if (_bridge == noone) _bridge = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Bridge_Obj);
                        if (_bridge == noone) _bridge = instance_place(_px, _py, Bridge_Obj);
                        if (_bridge == noone) {
                            _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=water ";
                            continue;
                        }
                    }
                }
            }
            
            // Stepping stones are walls to enemies (per Jas ruling 2026-02-27)
            var _stone = instance_place(_cx, _cy, Stepping_Stone_Obj);
            if (_stone == noone) _stone = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Stepping_Stone_Obj);
            if (_stone == noone) _stone = instance_place(_px, _py, Stepping_Stone_Obj);
            if (_stone != noone) {
                _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=stone ";
                continue;
            }
            
            // Factory droppers are deadly — avoid them
            var _dropper = instance_place(_cx, _cy, Factory_Dropper_Obj);
            if (_dropper == noone) _dropper = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Factory_Dropper_Obj);
            if (_dropper == noone) _dropper = instance_place(_px, _py, Factory_Dropper_Obj);
            if (_dropper != noone) {
                _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=dropper ";
                continue;
            }
            
            // Check for other enemies on this tile
            var _other_enemy = false;
            for (var e = 0; e < array_length(Enemy_Manager.enemy_list); e++) {
                var _oe = Enemy_Manager.enemy_list[e];
                if (instance_exists(_oe) && _oe != _enemy && _oe.grid_col == _col && _oe.grid_row == _row) {
                    _other_enemy = true;
                    break;
                }
            }
            if (_other_enemy) {
                _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=enemy ";
                continue;
            }
            
            // Check for chess pieces on this tile (use board map first, then instance checks)
            var _piece_on_tile = noone;
            var _piece_struct = (_board != undefined) ? _board[_row][_col] : noone;
            if (_piece_struct != noone) {
                // Block AI pieces, allow capture of player pieces (non-king)
                if (_piece_struct.piece_type == 1) {
                    _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=ally ";
                    continue;
                }
                if (_piece_struct.piece_id == "king") {
                    _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=king ";
                    continue;
                }
            } else {
                _piece_on_tile = instance_place(_cx, _cy, Chess_Piece_Obj);
                if (_piece_on_tile == noone) _piece_on_tile = instance_place(_px + Board_Manager.tile_size / 4, _py + Board_Manager.tile_size / 4, Chess_Piece_Obj);
                if (_piece_on_tile == noone) _piece_on_tile = instance_place(_px, _py, Chess_Piece_Obj);
            }
            
            // If there's a piece on the tile
            var _is_capture = false;
            if (_piece_struct != noone || _piece_on_tile != noone) {
                if (_piece_struct != noone) {
                    _is_capture = (_piece_struct.piece_type == 0 && _piece_struct.piece_id != "king");
                } else {
                    // Don't move onto AI pieces (piece_type == 1)
                    if (_piece_on_tile.piece_type == 1) {
                        _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=ally ";
                        continue;
                    }
                    // Don't capture the king directly
                    if (_piece_on_tile.piece_id == "king") {
                        _blocked_reasons += "(" + string(_col) + "," + string(_row) + ")=king ";
                        continue;
                    }
                    // Can capture player pieces (piece_type == 0, not king)
                    _is_capture = true;
                }
            }
            
            var _dist = abs(_target_col - _col) + abs(_target_row - _row);
            
            // Conveyor belt danger assessment — simulate future belt pushes
            var _belt_danger = 0;
            var _on_belt = false;
            with (Factory_Belt_Obj) {
                var _belt_left = x;
                var _belt_top = y;
                var _belt_right = x + 6 * Board_Manager.tile_size;
                var _belt_bottom = y + Board_Manager.tile_size;
                var _check_cx = _px + Board_Manager.tile_size / 2;
                var _check_cy = _py + Board_Manager.tile_size / 2;
                if (_check_cx >= _belt_left && _check_cx <= _belt_right &&
                    _check_cy >= _belt_top && _check_cy <= _belt_bottom) {
                    _on_belt = true;
                    // Simulate where the belt pushes over 1-3 turns
                    var _push_dir = right_direction ? 1 : -1; // belt push direction in tiles (right_direction=true pushes pieces RIGHT)
                    for (var _turns = 1; _turns <= 3; _turns++) {
                        var _future_px = _px + _push_dir * _turns * Board_Manager.tile_size;
                        var _future_py = _py;
                        // Check if future position has a dropper
                        var _future_dropper = instance_position(_future_px, _future_py, Factory_Dropper_Obj);
                        if (_future_dropper == noone) _future_dropper = instance_position(_future_px + Board_Manager.tile_size / 4, _future_py + Board_Manager.tile_size / 4, Factory_Dropper_Obj);
                        if (_future_dropper != noone) {
                            _belt_danger = max(_belt_danger, 4 - _turns); // Closer = more dangerous (3, 2, 1)
                            break;
                        }
                        // Also check if pushed off the belt (off board)
                        if (_future_px < _belt_left || _future_px >= _belt_right) {
                            break; // Will be pushed off belt, but not necessarily into dropper
                        }
                    }
                    break; // Only check one belt
                }
            }
            
            // Apply belt danger as distance penalty (makes tile less attractive)
            var _effective_dist = _dist + _belt_danger * 2;
            
            array_push(_valid_moves, { col: _col, row: _row, dist: _effective_dist, is_capture: _is_capture });
            
            // Prefer captures, then closest effective distance
            if (_is_capture && !_best_has_capture) {
                _best_dist = _effective_dist;
                _best_col = _col;
                _best_row = _row;
                _best_has_capture = true;
            } else if (_is_capture == _best_has_capture && _effective_dist < _best_dist) {
                _best_dist = _effective_dist;
                _best_col = _col;
                _best_row = _row;
            }
        }
    }
    
    // If no closer tile found but we have valid moves, pick a lateral one (same distance)
    // This prevents enemies from getting stuck when the direct path is blocked
    if (_best_col == _enemy.grid_col && _best_row == _enemy.grid_row && array_length(_valid_moves) > 0) {
        // Pick a random valid move from the closest available options
        var _min_dist = 9999;
        for (var _v = 0; _v < array_length(_valid_moves); _v++) {
            if (_valid_moves[_v].dist < _min_dist) _min_dist = _valid_moves[_v].dist;
        }
        // Gather all moves at that distance
        var _candidates = [];
        for (var _v = 0; _v < array_length(_valid_moves); _v++) {
            if (_valid_moves[_v].dist == _min_dist) array_push(_candidates, _valid_moves[_v]);
        }
        var _pick = _candidates[irandom(array_length(_candidates) - 1)];
        _best_col = _pick.col;
        _best_row = _pick.row;
        show_debug_message("Enemy at (" + string(_enemy.grid_col) + "," + string(_enemy.grid_row) + "): No closer tile, lateral move to (" + string(_best_col) + "," + string(_best_row) + ")");
    }
    
    // If no valid tile found at all, enemy stays put
    if (_best_col == _enemy.grid_col && _best_row == _enemy.grid_row) {
        show_debug_message("Enemy at (" + string(_enemy.grid_col) + "," + string(_enemy.grid_row) + "): Stuck! Blocked by: " + _blocked_reasons);
        return;
    }
    
    // Check if there's a player piece to capture on the destination
    var _dest_px = Object_Manager.topleft_x + _best_col * Board_Manager.tile_size;
    var _dest_py = Object_Manager.topleft_y + _best_row * Board_Manager.tile_size;
    var _capture_piece = instance_position(_dest_px, _dest_py, Chess_Piece_Obj);
    
    if (_capture_piece != noone && _capture_piece.piece_type == 0 && _capture_piece.piece_id != "king") {
        // Capture the player piece
        show_debug_message("Enemy capturing " + _capture_piece.piece_id + " at (" + string(_best_col) + "," + string(_best_row) + ")");
        instance_destroy(_capture_piece);
        audio_play_sound(Piece_Capture_SFX, 0, false);
    }
    
    // Start movement animation
    _enemy.move_start_x = _enemy.x;
    _enemy.move_start_y = _enemy.y;
    _enemy.move_target_x = _dest_px;
    _enemy.move_target_y = _dest_py;
    _enemy.move_progress = 0;
    _enemy.is_moving = true;
    _enemy.grid_col = _best_col;
    _enemy.grid_row = _best_row;
    
    show_debug_message("Enemy moving to (" + string(_best_col) + "," + string(_best_row) + ")");
}
