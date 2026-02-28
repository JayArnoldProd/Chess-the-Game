/// @function enemy_is_knockback_valid(_enemy, _col, _row)
/// @param {Id.Instance} _enemy The enemy being knocked back
/// @param {real} _col Target column
/// @param {real} _row Target row
/// @returns {bool} True if the knockback destination is valid
/// @description Checks if an enemy can be knocked back to the specified tile
function enemy_is_knockback_valid(_enemy, _col, _row) {
    // Bounds check — board edge = wall
    if (_col < 0 || _col >= 8 || _row < 0 || _row >= 8) {
        return false;
    }
    
    // Calculate pixel position
    var _x = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _y = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    // Other enemy = wall
    var _other = instance_position(_x, _y, Enemy_Obj);
    if (_other != noone && _other != _enemy) {
        return false;
    }
    
    // Chess piece = wall
    var _piece = instance_position(_x, _y, Chess_Piece_Obj);
    if (_piece != noone) {
        return false;
    }
    
    // Stepping stone = wall (immovable, per Jas ruling 2026-02-27)
    var _stone = instance_position(_x, _y, Stepping_Stone_Obj);
    if (_stone != noone) {
        return false;
    }
    
    // Tile hazards
    var _tile = instance_position(_x, _y, Tile_Obj);
    if (_tile != noone && variable_instance_exists(_tile, "tile_type")) {
        // Void tile blocks knockback
        if (_tile.tile_type == -1) {
            return false;
        }
        // Water is allowed for knockback (enemy will drown after landing if no bridge)
        // Bridge presence does not block knockback
    }
    
    return true;
}
