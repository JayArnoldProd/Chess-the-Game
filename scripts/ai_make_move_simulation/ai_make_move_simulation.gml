/// @function ai_make_move_simulation(move)
/// @param {struct} move The move to make in simulation
/// @description Executes a move on the board (for simulation only)

function ai_make_move_simulation(move) {
    // Find the piece at the from position
    var piece = instance_position(move.from_x, move.from_y, Chess_Piece_Obj);
    if (piece == noone) return;
    
    // Verify this is the right piece
    if (piece.piece_type != move.piece_data.piece_type || 
        piece.piece_id != move.piece_data.piece_id) {
        return;
    }
    
    // Store piece info before potential destruction
    var piece_type = piece.piece_type;
    var piece_id = piece.piece_id;
    var original_x = piece.x;
    var original_y = piece.y;
    
    // Handle captures
    if (move.is_capture && !move.is_en_passant) {
        var captured_piece = instance_position(move.to_x, move.to_y, Chess_Piece_Obj);
        if (captured_piece != noone && captured_piece != piece) {
            instance_destroy(captured_piece);
        }
    }
    
    // Handle en passant
    if (move.is_en_passant) {
        if (instance_exists(Game_Manager.en_passant_pawn)) {
            instance_destroy(Game_Manager.en_passant_pawn);
        }
    }
    
    // Move the piece
    piece.x = move.to_x;
    piece.y = move.to_y;
    piece.has_moved = true;
    
    // Handle castling
    if (move.is_castling && move.rook_data != noone) {
        var rook = instance_position(move.rook_data.x, move.rook_data.y, Rook_Obj);
        if (rook != noone && rook.piece_type == piece.piece_type) {
            var king_moved_right = (move.castle_direction > 0);
            if (king_moved_right) {
                rook.x = move.to_x - Board_Manager.tile_size;
            } else {
                rook.x = move.to_x + Board_Manager.tile_size;
            }
            rook.has_moved = true;
        }
    }
    
    // Handle pawn promotion (simplified - always promote to queen)
    var promoted_piece = piece; // Keep reference to the piece (might change due to promotion)
    if (piece_id == "pawn" && instance_exists(piece)) {
        var promote = false;
        if (piece_type == 0 && piece.y <= Object_Manager.topleft_y) { // White reaches top
            promote = true;
        } else if (piece_type == 1 && piece.y >= Object_Manager.topleft_y + 7 * Board_Manager.tile_size) { // Black reaches bottom
            promote = true;
        }
        
        if (promote) {
            var new_queen = instance_create_depth(piece.x, piece.y, -1, Queen_Obj);
            new_queen.piece_type = piece_type;
            new_queen.has_moved = true;
            promoted_piece = new_queen; // Update reference to the new piece
            instance_destroy(piece);
        }
    }
    
    // Update en passant state
    Game_Manager.en_passant_target_x = -1;
    Game_Manager.en_passant_target_y = -1;
    Game_Manager.en_passant_pawn = noone;
    
    // Check for new en passant vulnerability (use stored values to avoid accessing destroyed piece)
    if (piece_id == "pawn" && instance_exists(promoted_piece) && abs(move.to_y - move.from_y) == Board_Manager.tile_size * 2) {
        Game_Manager.en_passant_target_x = promoted_piece.x;
        Game_Manager.en_passant_target_y = (move.from_y + move.to_y) / 2;
        if (variable_instance_exists(promoted_piece, "en_passant_vulnerable")) {
            promoted_piece.en_passant_vulnerable = true;
            Game_Manager.en_passant_pawn = promoted_piece;
        }
    }
    
    // Switch turns
    Game_Manager.turn = (Game_Manager.turn == 0) ? 1 : 0;
}