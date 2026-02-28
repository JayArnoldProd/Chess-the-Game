/// @function enemy_create(_enemy_type_id, _col, _row)
/// @param {string} _enemy_type_id The enemy type ID (e.g., "placeholder")
/// @param {real} _col Board column (0-7)
/// @param {real} _row Board row (0-7)
/// @returns {Id.Instance} The created enemy instance, or noone on failure
function enemy_create(_enemy_type_id, _col, _row) {
    var _def = enemy_get_definition(_enemy_type_id);
    if (_def == undefined) {
        show_debug_message("ERROR: Cannot create enemy - unknown type: " + _enemy_type_id);
        return noone;
    }
    
    // Calculate pixel position
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) {
        show_debug_message("ERROR: Cannot create enemy - managers not ready");
        return noone;
    }
    
    var _px = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _py = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    var _enemy = instance_create_depth(_px, _py, -1, Enemy_Obj);
    
    if (!instance_exists(_enemy)) {
        show_debug_message("ERROR: Failed to create Enemy_Obj instance");
        return noone;
    }
    
    with (_enemy) {
        enemy_type_id = _enemy_type_id;
        enemy_def = _def;
        
        max_hp = _def.max_hp;
        current_hp = max_hp;
        
        grid_col = _col;
        grid_row = _row;
        
        move_duration = _def.movement_speed;
        
        // Don't set sprite_index — Enemy_Obj Draw_0 handles all drawing manually
        // sprite_index stays -1 (set in Create_0) to prevent default GM drawing
        
        show_debug_message("Enemy created: " + _def.display_name + 
            " at (" + string(_col) + "," + string(_row) + 
            ") HP: " + string(current_hp) + "/" + string(max_hp));
    }
    
    // Register with Enemy_Manager
    if (instance_exists(Enemy_Manager)) {
        array_push(Enemy_Manager.enemy_list, _enemy);
    }
    
    return _enemy;
}
