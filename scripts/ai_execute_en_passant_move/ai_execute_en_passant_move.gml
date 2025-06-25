/// @function ai_execute_en_passant_move(move, target_tile)
/// @param {struct} move The en passant move to execute
/// @param {id} target_tile The target tile instance

function ai_execute_en_passant_move(move, target_tile) {
    var pawn = ai_find_piece_at_position(move.from_x, move.from_y, move.piece_data.piece_type, move.piece_data.piece_id);
    if (pawn == noone) return;
    
    // Set up the animated move
    pawn.move_start_x = pawn.x;
    pawn.move_start_y = pawn.y;
    pawn.move_target_x = move.to_x;
    pawn.move_target_y = move.to_y;
    pawn.move_progress = 0;
    pawn.move_duration = 30;
    pawn.is_moving = true;
    pawn.move_animation_type = "linear";
    pawn.has_moved = true;
    pawn.landing_sound = Piece_Landing_SFX;
    pawn.landing_sound_pending = true;
    
    // Mark en passant for processing
    pawn.pending_en_passant = true;
    pawn.pending_normal_move = true;
    pawn.pending_turn_switch = 0; // Switch to white's turn
    
    Game_Manager.selected_piece = noone;
}