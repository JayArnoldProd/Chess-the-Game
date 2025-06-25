/// @function ai_execute_castling_move(move, target_tile)
/// @param {struct} move The castling move to execute
/// @param {id} target_tile The target tile instance

function ai_execute_castling_move(move, target_tile) {
    var king = ai_find_piece_at_position(move.from_x, move.from_y, move.piece_data.piece_type, move.piece_data.piece_id);
    if (king == noone) return;
    
    // Set up king animation
    king.move_start_x = king.x;
    king.move_start_y = king.y;
    king.move_target_x = move.to_x;
    king.move_target_y = move.to_y;
    king.move_progress = 0;
    king.move_duration = 30;
    king.is_moving = true;
    king.move_animation_type = "linear";
    king.has_moved = true;
    king.landing_sound = Piece_Landing_SFX;
    king.landing_sound_pending = true;
    
    // Find and move the rook
    var rook = noone;
    if (move.rook_data != noone) {
        rook = ai_find_piece_at_position(move.rook_data.x, move.rook_data.y, move.rook_data.piece_type, move.rook_data.piece_id);
    }
    
    if (rook != noone) {
        rook.move_start_x = rook.x;
        rook.move_start_y = rook.y;
        
        var king_moved_right = (move.castle_direction > 0);
        if (king_moved_right) {
            rook.move_target_x = move.to_x - Board_Manager.tile_size;
        } else {
            rook.move_target_x = move.to_x + Board_Manager.tile_size;
        }
        
        rook.move_target_y = move.to_y;
        rook.move_progress = 0;
        rook.move_duration = 30;
        rook.is_moving = true;
        rook.has_moved = true;
    }
    
    // Clear castling moves
    if (variable_instance_exists(king, "castle_moves")) {
        king.castle_moves = [];
    }
    king.pending_turn_switch = 0; // Switch to white's turn
    
    Game_Manager.selected_piece = noone;
}

