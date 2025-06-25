/// @function ai_execute_move(move)
/// @param {struct} move The move to execute in the actual game
/// @description Executes the AI's chosen move in the real game

function ai_execute_move(move) {
    if (move == undefined) {
        show_debug_message("AI Error: No move to execute");
        return;
    }
    
    // Find the piece using position and data
    var piece = ai_find_piece_at_position(move.from_x, move.from_y, move.piece_data.piece_type, move.piece_data.piece_id);
    if (piece == noone) {
        show_debug_message("AI Error: Could not find piece to move");
        return;
    }
    
    // Find the target tile
    var target_tile = instance_place(move.to_x, move.to_y, Tile_Obj);
    if (target_tile == noone) {
        show_debug_message("AI Error: Invalid target tile");
        return;
    }
    
    // Set the piece as selected to enable the move system
    Game_Manager.selected_piece = piece;
    
    // Record original position for the piece's turn tracking
    piece.original_turn_x = piece.x;
    piece.original_turn_y = piece.y;
    piece.original_has_moved = piece.has_moved;
    
    // Handle special moves
    if (move.is_castling) {
        ai_execute_castling_move(move, target_tile);
    } else if (move.is_en_passant) {
        ai_execute_en_passant_move(move, target_tile);
    } else {
        ai_execute_normal_move(move, target_tile);
    }
}