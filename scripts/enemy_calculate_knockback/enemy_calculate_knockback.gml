/// @function enemy_calculate_knockback(_enemy, _attacker_col, _attacker_row)
/// @param {Id.Instance} _enemy The enemy being knocked back
/// @param {real} _attacker_col Column the attack came FROM
/// @param {real} _attacker_row Row the attack came FROM
/// @returns {struct} { dir_x, dir_y, dest_col, dest_row, valid }
/// @description Calculates knockback direction and destination (1 tile push)
function enemy_calculate_knockback(_enemy, _attacker_col, _attacker_row) {
    var _result = {
        dir_x: 0,
        dir_y: 0,
        dest_col: _enemy.grid_col,
        dest_row: _enemy.grid_row,
        valid: false
    };
    
    if (!instance_exists(_enemy)) return _result;
    
    // Knockback direction = away from attacker (same direction as attack)
    var _dx = _enemy.grid_col - _attacker_col;
    var _dy = _enemy.grid_row - _attacker_row;
    
    // Normalize to -1, 0, or 1
    _result.dir_x = sign(_dx);
    _result.dir_y = sign(_dy);
    
    // Edge case: attacker on same tile (shouldn't happen, default push down)
    if (_result.dir_x == 0 && _result.dir_y == 0) {
        _result.dir_y = 1;
    }
    
    // Calculate destination
    _result.dest_col = _enemy.grid_col + _result.dir_x;
    _result.dest_row = _enemy.grid_row + _result.dir_y;
    
    // Validate
    _result.valid = enemy_is_knockback_valid(_enemy, _result.dest_col, _result.dest_row);
    
    // If blocked, enemy stays put
    if (!_result.valid) {
        _result.dest_col = _enemy.grid_col;
        _result.dest_row = _enemy.grid_row;
    }
    
    return _result;
}
