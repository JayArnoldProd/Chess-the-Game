/// @function ai_execute_normal_move(move, target_tile)
/// @param {struct} move The move to execute
/// @param {id} target_tile The target tile instance

function ai_execute_normal_move(move, target_tile) {
    var piece = ai_find_piece_at_position(move.from_x, move.from_y, move.piece_data.piece_type, move.piece_data.piece_id);
    if (piece == noone) return;
    
    // Handle captures
    if (move.is_capture && move.captured_data != noone) {
        var captured_piece = instance_position(move.to_x, move.to_y, Chess_Piece_Obj);
        if (captured_piece != noone && captured_piece != piece) {
            piece.pending_capture = captured_piece;
        }
    }
    
    // Set up the animated move
    piece.move_start_x = piece.x;
    piece.move_start_y = piece.y;
    piece.move_target_x = move.to_x;
    piece.move_target_y = move.to_y;
    piece.move_progress = 0;
    piece.move_duration = 30;
    piece.is_moving = true;
    piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
    piece.has_moved = true;
    
    // Set landing sound based on target
    if (instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj)) {
        piece.landing_sound = Piece_StoneLanding_SFX;
    } else {
        piece.landing_sound = Piece_Landing_SFX;
    }
    piece.landing_sound_pending = true;
    
    // Mark as normal move for processing
    piece.pending_normal_move = true;
    piece.pending_turn_switch = 0; // Switch to white's turn
    
    // Check for water/void tiles (your special chess mechanics)
    if (target_tile.tile_type == -1) { // void tile
        piece.destroy_pending = true;
        piece.destroy_target_x = move.to_x;
        piece.destroy_target_y = move.to_y;
    } else if (target_tile.tile_type == 1) { // water tile
        if (!instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Bridge_Obj)) {
            piece.destroy_pending = true;
            piece.destroy_target_x = move.to_x;
            piece.destroy_target_y = move.to_y;
            piece.destroy_tile_type = 1;
        }
    }
    
    Game_Manager.selected_piece = noone;
}
