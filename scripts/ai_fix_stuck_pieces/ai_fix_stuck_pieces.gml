/// @function ai_fix_stuck_pieces()
/// @description Fixes pieces stuck in weird positions
function ai_fix_stuck_pieces() {
    show_debug_message("=== FIXING STUCK PIECES ===");
    
    var fixed_count = 0;
    
    with (Chess_Piece_Obj) {
        var old_x = x;
        var old_y = y;
        
        // Snap to nearest grid position
        x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
        y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        
        // Stop any movement
        if (is_moving) {
            is_moving = false;
            move_progress = 0;
            fixed_count++;
        }
        
        // Check if position changed
        if (abs(old_x - x) > 0.1 || abs(old_y - y) > 0.1) {
            show_debug_message("Fixed " + piece_id + " position from (" + 
                             string(old_x) + "," + string(old_y) + ") to (" +
                             string(x) + "," + string(y) + ")");
            fixed_count++;
        }
    }
    
    show_debug_message("Fixed " + string(fixed_count) + " pieces");
    return fixed_count;
}
