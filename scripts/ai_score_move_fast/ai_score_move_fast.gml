/// @function ai_score_move_fast(move)
function ai_score_move_fast(move) {
    var score_ = 0;
    
    // Big bonus for captures
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        var captured_value = AI_Manager.piece_values[? move.captured_piece.piece_id];
        score_ += captured_value;
    }
    
    // KING SAFETY - Critical for endgame
    if (move.piece_id == "king") {
        // Penalty for king moves (unless necessary)
        score_ -= 50;
        
        // But bonus for king activity in endgame
        var total_pieces = instance_number(Chess_Piece_Obj);
        if (total_pieces <= 10) { // Endgame
            score_ += 30; // King should be active in endgame
        }
    }
    
    // RESPONSE TO CHECK - Highest priority
    var king_in_check = ai_is_king_in_check(move.piece_type);
    if (king_in_check) {
        // If king is in check, prioritize moves that get out of check
        score_ += 500; // Very high bonus for any legal move when in check
        
        if (move.piece_id == "king") {
            score_ += 200; // Extra bonus for king moves when in check
        }
    }
    
    // PIECE ACTIVITY - Encourage using all pieces
    switch (move.piece_id) {
        case "queen":
            score_ += 40; // Queens should be active
            break;
        case "rook":
            score_ += 35; // Rooks should be active
            break;
        case "bishop":
            score_ += 30; // Bishops should be active
            break;
        case "knight":
            score_ += 25; // Knights should be active
            break;
        case "pawn":
            score_ += 10; // Slight preference for pawn moves
            break;
    }
    
    // Center control bonus
    var target_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    if (target_file >= 2 && target_file <= 5) {
        score_ += 20;
    }
    
    // Development bonus
    if (!move.piece.has_moved && (move.piece.piece_id == "knight" || move.piece.piece_id == "bishop")) {
        score_ += 30;
    }
    
    // Stepping stone bonus
    var on_stepping_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    if (on_stepping_stone) {
        score_ += 150; // Big bonus for stepping stone usage
    }
    
    // Random element for variety
    score_ += irandom(15);
    
    return score_;
}