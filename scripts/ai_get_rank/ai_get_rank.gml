/// @function ai_get_rank(y)
/// @param {real} y Y coordinate
/// @returns {real} Rank (0-7)

function ai_get_rank(y) {
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) return -1;
    return round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
}