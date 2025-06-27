/// @function ai_execute_move_fast(move)
/// @param {struct} move The move to execute
/// @description Executes AI move quickly - FIXED VERSION

function ai_execute_move_fast(move) {
    if (move == undefined || !instance_exists(move.piece)) {
        show_debug_message("AI Error: Invalid move or piece");
        Game_Manager.turn = 0;
        return;
    }
    
    var piece = move.piece;
    
    // Handle capture - FIX: Get piece info BEFORE destroying
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        var captured_piece_id = move.captured_piece.piece_id; // Store BEFORE destroy
        instance_destroy(move.captured_piece);
        show_debug_message("AI: Captured " + captured_piece_id); // Use stored value
    }
    
    // Move the piece with animation
    piece.move_start_x = piece.x;
    piece.move_start_y = piece.y;
    piece.move_target_x = move.to_x;
    piece.move_target_y = move.to_y;
    piece.move_progress = 0;
    piece.move_duration = 20; // Fast animation
    piece.is_moving = true;
    piece.has_moved = true;
    
    // Set animation type
    piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
    
    // Set landing sound
    piece.landing_sound = Piece_Landing_SFX;
    piece.landing_sound_pending = true;
    
    // Switch turns after move
    piece.pending_turn_switch = 0;
    piece.pending_normal_move = true;
    
    Game_Manager.selected_piece = noone;
    
    show_debug_message("AI: Moved " + piece.piece_id + " from (" + 
                      string(move.from_x) + "," + string(move.from_y) + ") to (" + 
                      string(move.to_x) + "," + string(move.to_y) + ")");
}