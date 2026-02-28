/// @function enemy_find_target(_enemy)
/// @param {Id.Instance} _enemy The enemy instance
/// @returns {Id.Instance} The closest player piece, or noone
function enemy_find_target(_enemy) {
    var _best_target = noone;
    var _best_dist = 999999;
    var _tile_size = Board_Manager.tile_size;
    var _ox = Object_Manager.topleft_x;
    var _oy = Object_Manager.topleft_y;
    
    with (Chess_Piece_Obj) {
        // Only target player pieces (piece_type == 0)
        if (piece_type != 0) continue;
        // Skip pieces that are being destroyed
        if (variable_instance_exists(id, "destroy_pending") && destroy_pending) continue;
        
        var _pcol = round((x - _ox) / _tile_size);
        var _prow = round((y - _oy) / _tile_size);
        var _dist = abs(_pcol - _enemy.grid_col) + abs(_prow - _enemy.grid_row);
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best_target = id;
        }
    }
    
    return _best_target;
}
