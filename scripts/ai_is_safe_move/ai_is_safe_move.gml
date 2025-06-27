/// @function ai_is_move_safe(move)
function ai_is_move_safe(move) {
    // Quick check - if king would be in check after this move, it's not safe
    
    // For king moves, check if target square is attacked
    if (move.piece_id == "king") {
        return !ai_is_square_attacked(move.to_x, move.to_y, move.piece_type);
    }
    
    // For other pieces, this is a simplified check
    // (A full implementation would simulate the move and check if king is in check)
    return true; // Simplified - assume other moves are safe
}