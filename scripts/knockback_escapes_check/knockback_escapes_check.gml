/// @function knockback_escapes_check(piece, target_x, target_y)
/// @desc Checks if attacking an enemy at target and knocking it back would block a check on the king
/// @param {Id.Instance} piece The attacking piece
/// @param {real} target_x Target X (enemy position)
/// @param {real} target_y Target Y (enemy position)
/// @returns {bool} True if knockback would create a blocker that escapes check
function knockback_escapes_check(_piece, _target_x, _target_y) {
    if (!instance_exists(_piece)) return false;
    
    var _ts = Board_Manager.tile_size;
    
    // 1. Find enemy at target
    var _enemy = instance_position(_target_x, _target_y, Enemy_Obj);
    if (_enemy == noone) {
        _enemy = instance_position(_target_x + _ts / 4, _target_y + _ts / 4, Enemy_Obj);
    }
    if (_enemy == noone || _enemy.is_dead) return false;
    
    // 2. Would enemy die? (1 HP = kill shot, no body to block)
    if (_enemy.current_hp <= 1) return false;
    
    // 3. Calculate knockback WITHOUT modifying state
    var _attacker_col = round((_piece.x - Object_Manager.topleft_x) / _ts);
    var _attacker_row = round((_piece.y - Object_Manager.topleft_y) / _ts);
    
    // Knight special: horizontal knockback
    var _kb_att_col = _attacker_col;
    var _kb_att_row = _attacker_row;
    if (_piece.piece_id == "knight") {
        _kb_att_row = _enemy.grid_row;
    }
    
    // Replicate knockback calculation (don't call enemy_calculate_knockback to avoid side effects)
    var _dx = _enemy.grid_col - _kb_att_col;
    var _dy = _enemy.grid_row - _kb_att_row;
    var _dir_x = sign(_dx);
    var _dir_y = sign(_dy);
    if (_dir_x == 0 && _dir_y == 0) _dir_y = 1;
    
    var _dest_col = _enemy.grid_col + _dir_x;
    var _dest_row = _enemy.grid_row + _dir_y;
    
    // 4. Check knockback validity (same logic as enemy_is_knockback_valid but read-only)
    if (_dest_col < 0 || _dest_col >= 8 || _dest_row < 0 || _dest_row >= 8) return false;
    
    var _dest_x = Object_Manager.topleft_x + _dest_col * _ts;
    var _dest_y = Object_Manager.topleft_y + _dest_row * _ts;
    
    // Other enemy blocks
    var _other = instance_position(_dest_x, _dest_y, Enemy_Obj);
    if (_other != noone && _other != _enemy) return false;
    
    // Chess piece blocks (but account for the attacking piece moving away from its current pos)
    var _blocker_piece = instance_position(_dest_x, _dest_y, Chess_Piece_Obj);
    if (_blocker_piece != noone && _blocker_piece != _piece) return false;
    
    // Stepping stone blocks
    if (instance_position(_dest_x, _dest_y, Stepping_Stone_Obj) != noone) return false;
    
    // Tile hazards block
    var _tile = instance_position(_dest_x, _dest_y, Tile_Obj);
    if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
        if (_tile.tile_type == -1) return false;
        if (_tile.tile_type == 1 && !instance_position(_dest_x, _dest_y, Bridge_Obj)) return false;
    }
    
    // 5. Knockback is valid — now simulate and check if it blocks the check
    // After this move: piece at _target_x/_target_y, enemy body at _dest_x/_dest_y
    // Use move_leaves_king_in_check_with_blocker to check
    return !move_leaves_king_in_check_with_blocker(_piece, _target_x, _target_y, _dest_x, _dest_y);
}
