/// @function ai_execute_move_animated(move)
function ai_execute_move_animated(move) {
    if (!instance_exists(move.piece)) return false;
    
    var piece = move.piece;
    
    // Snap positions to grid
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
    
    // Set animation type
    piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
    
    // Set landing sound and handle stepping stones
    var target_tile = instance_place(to_x, to_y, Tile_Obj);
    var on_stepping_stone = instance_position(to_x + Board_Manager.tile_size/4, to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    
    if (on_stepping_stone) {
        piece.landing_sound = Piece_StoneLanding_SFX;
        // Prepare for stepping stone sequence - DO NOT SWITCH TURNS YET
        AI_Manager.ai_stepping_phase = 1; // Will trigger phase 1 after animation
        AI_Manager.ai_stepping_piece = piece;
        
        // CRITICAL: Do NOT set pending_turn_switch for stepping stone moves
        piece.pending_turn_switch = undefined;
        piece.pending_normal_move = false; // Don't process as normal move
        
    } else {
        piece.landing_sound = Piece_Landing_SFX;
        // Normal move - switch turns after animation
        piece.pending_turn_switch = 0;
        piece.pending_normal_move = true;
    }
    
    piece.landing_sound_pending = true;
    
    Game_Manager.selected_piece = noone;
    return true;
}
