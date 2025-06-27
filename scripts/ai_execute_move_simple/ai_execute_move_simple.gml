/// @function ai_execute_move_simple(move)
function ai_execute_move_simple(move) {
    if (!instance_exists(move.piece)) return false;
    
    var piece = move.piece;
    
    // Stop all animations
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    // Snap positions
    var to_x = round(move.to_x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var to_y = round(move.to_y / Board_Manager.tile_size) * Board_Manager.tile_size;
    
    // Handle capture
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        instance_destroy(move.captured_piece);
    }
    
    // Set up animated move
    piece.move_start_x = piece.x;
    piece.move_start_y = piece.y;
    piece.move_target_x = to_x;
    piece.move_target_y = to_y;
    piece.move_progress = 0;
    piece.move_duration = 30;
    piece.is_moving = true;
    piece.has_moved = true;
    piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
    
    // Set landing sound  
    piece.landing_sound = Piece_Landing_SFX;
    piece.landing_sound_pending = true;
    
    // Switch turns after animation
    piece.pending_turn_switch = 0;
    piece.pending_normal_move = true;
    
    Game_Manager.selected_piece = noone;
    return true;
}