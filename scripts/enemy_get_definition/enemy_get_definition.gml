/// @function enemy_get_definition(_enemy_id)
/// @param {string} _enemy_id The enemy type ID (e.g., "placeholder")
/// @returns {struct} Enemy definition struct, or undefined if not found
function enemy_get_definition(_enemy_id) {
    if (!ds_exists(global.enemy_definitions, ds_type_map)) {
        show_debug_message("ERROR: Enemy definitions not initialized!");
        return undefined;
    }
    
    if (!ds_map_exists(global.enemy_definitions, _enemy_id)) {
        show_debug_message("WARNING: Unknown enemy type: " + string(_enemy_id));
        return undefined;
    }
    
    return ds_map_find_value(global.enemy_definitions, _enemy_id);
}
