/// @function ai_get_square_index(x, y)
/// @param {real} x X coordinate
/// @param {real} y Y coordinate
/// @returns {real} Square index (0-63)

function ai_get_square_index(x, y) {
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) return -1;
    
    var file = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var rank = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    if (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
        return rank * 8 + file;
    }
    return -1;
}