/// Enemy_Obj collision with Factory_Dropper_Obj (trash can)
/// Destroy enemy when it lands on a dropper tile
if (abs(x - other.x) < Board_Manager.tile_size * 0.5 && abs(y - other.y) < Board_Manager.tile_size * 0.5) {
    audio_play_sound(Trap_Door_SFX, 0, false);
    is_dead = true;
    
    // Remove from enemy list
    if (instance_exists(Enemy_Manager)) {
        var _idx = array_get_index(Enemy_Manager.enemy_list, id);
        if (_idx >= 0) {
            array_delete(Enemy_Manager.enemy_list, _idx, 1);
        }
    }
    
    show_debug_message("Enemy destroyed by trash can at (" + string(grid_col) + "," + string(grid_row) + ")");
    instance_destroy();
}
