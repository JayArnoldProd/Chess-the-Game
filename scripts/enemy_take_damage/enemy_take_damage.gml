/// @function enemy_take_damage(_enemy, _damage, _attacker_col, _attacker_row, _attacker_piece)
/// @param {Id.Instance} _enemy The enemy taking damage
/// @param {real} _damage Amount of damage (typically 1)
/// @param {real} _attacker_col Column the attack came from
/// @param {real} _attacker_row Row the attack came from
/// @param {Id.Instance} _attacker_piece (optional) The piece doing the attacking — used for knight knockback direction
/// @returns {struct} { died: bool, knocked_back: bool }
///   died = true: enemy killed, piece occupies tile (standard capture)
///   knocked_back = true: enemy pushed away, piece occupies enemy's old tile
///   knocked_back = false + died = false: knockback blocked, piece must bounce back
function enemy_take_damage(_enemy, _damage, _attacker_col, _attacker_row, _attacker_piece) {
    var _result = { died: false, knocked_back: false };
    
    if (!instance_exists(_enemy)) return _result;
    if (_enemy.is_dead) return _result;
    
    show_debug_message("Enemy taking " + string(_damage) + " damage from (" + 
        string(_attacker_col) + "," + string(_attacker_row) + ")");
    
    // Apply damage first — determine if enemy survives
    _enemy.current_hp -= _damage;
    
    // Check death BEFORE knockback — no knockback on kill, just capture
    if (_enemy.current_hp <= 0) {
        _enemy.is_dead = true;
        _enemy.death_timer = 0;
        show_debug_message("Enemy killed! No knockback — capturing.");
        audio_play_sound(Piece_Capture_SFX, 1, false);
        _result.died = true;
        return _result;
    }
    
    // Hit flash
    _enemy.hit_flash_timer = _enemy.hit_flash_duration;
    
    // Enemy survived — apply knockback
    // For knights: knockback is along the SECOND leg of the L-shape (horizontal sweep)
    var _kb_attacker_col = _attacker_col;
    var _kb_attacker_row = _attacker_row;
    
    if (_attacker_piece != undefined && instance_exists(_attacker_piece) 
        && _attacker_piece.piece_id == "knight") {
        _kb_attacker_col = _attacker_col;
        _kb_attacker_row = _enemy.grid_row;
        show_debug_message("Knight attack: knockback forced horizontal (col " + 
            string(_attacker_col) + " → " + string(_enemy.grid_col) + ")");
    }
    
    var _kb = enemy_calculate_knockback(_enemy, _kb_attacker_col, _kb_attacker_row);
    
    if (_kb.valid) {
        var _dest_x = Object_Manager.topleft_x + _kb.dest_col * Board_Manager.tile_size;
        var _dest_y = Object_Manager.topleft_y + _kb.dest_row * Board_Manager.tile_size;
        
        _enemy.move_start_x = _enemy.x;
        _enemy.move_start_y = _enemy.y;
        _enemy.move_target_x = _dest_x;
        _enemy.move_target_y = _dest_y;
        _enemy.move_progress = 0;
        _enemy.move_duration = 15;
        _enemy.is_moving = true;
        _enemy.knockback_pending = true;
        _enemy.knockback_dir_x = _kb.dir_x;
        _enemy.knockback_dir_y = _kb.dir_y;
        
        _enemy.grid_col = _kb.dest_col;
        _enemy.grid_row = _kb.dest_row;
        
        _result.knocked_back = true;
        show_debug_message("Enemy knocked back to (" + string(_kb.dest_col) + "," + string(_kb.dest_row) + ")");
    } else {
        show_debug_message("Enemy knockback blocked — stays put, piece must bounce back");
    }
    
    show_debug_message("Enemy HP: " + string(_enemy.current_hp) + "/" + string(_enemy.max_hp));
    return _result;
}
