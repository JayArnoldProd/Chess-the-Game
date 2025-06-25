/// @function ai_make_move(move)
/// @param {struct} move The move to make
/// @description Executes a move on the board (for simulation)

function ai_make_move(move) {
    var piece = move.piece;
    
    if (!instance_exists(piece)) return;
    
    // Handle captures
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        instance_destroy(move.captured_piece);
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
    if (move.is_castling) {
        var rook = noone;
        with (Rook_Obj) {
            if (id == move.rook_id) {
                rook = id;
                break;
            }
        }
        
        if (rook != noone) {
            var king_moved_right = (move.to_x > move.from_x);
            if (king_moved_right) {
                rook.x = move.to_x - Board_Manager.tile_size;
            } else {
                rook.x = move.to_x + Board_Manager.tile_size;
            }
            rook.has_moved = true;
        }
    }
    
    // Handle pawn promotion (simplified - always promote to queen)
    if (piece.piece_id == "pawn") {
        var promote = false;
        if (piece.piece_type == 0 && piece.y <= Object_Manager.topleft_y) { // White reaches top
            promote = true;
        } else if (piece.piece_type == 1 && piece.y >= Object_Manager.topleft_y + 7 * Board_Manager.tile_size) { // Black reaches bottom
            promote = true;
        }
        
        if (promote) {
            var new_queen = instance_create_depth(piece.x, piece.y, -1, Queen_Obj);
            new_queen.piece_type = piece.piece_type;
            new_queen.has_moved = true;
            instance_destroy(piece);
        }
    }
    
    // Update en passant state
    Game_Manager.en_passant_target_x = -1;
    Game_Manager.en_passant_target_y = -1;
    Game_Manager.en_passant_pawn = noone;
    
    // Check for new en passant vulnerability
    if (piece.piece_id == "pawn" && abs(move.to_y - move.from_y) == Board_Manager.tile_size * 2) {
        Game_Manager.en_passant_target_x = piece.x;
        Game_Manager.en_passant_target_y = (move.from_y + move.to_y) / 2;
        if (variable_instance_exists(piece, "en_passant_vulnerable")) {
            piece.en_passant_vulnerable = true;
            Game_Manager.en_passant_pawn = piece;
        }
    }
    
    // Switch turns
    Game_Manager.turn = (Game_Manager.turn == 0) ? 1 : 0;
}