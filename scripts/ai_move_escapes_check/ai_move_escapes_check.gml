/// @function ai_move_escapes_check(move)
/// @param {struct} move The move to test
/// @returns {bool} Whether this move gets out of check
function ai_move_escapes_check(move) {
    // Simple simulation: temporarily move piece and check if king is still in check
    var piece = move.piece;
    var old_x = piece.x;
    var old_y = piece.y;
    var captured_piece = move.captured_piece;
    
    // Temporarily move piece
    piece.x = move.to_x;
    piece.y = move.to_y;
    
    // Temporarily remove captured piece
    if (captured_piece != noone && instance_exists(captured_piece)) {
        captured_piece.visible = false;
    }
    
    // Force update moves and check if king is still in check
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            event_perform(ev_step, ev_step_normal);
        }
    }
    
    var still_in_check = ai_is_king_in_check_simple(move.piece_type);
    
    // Restore original position
    piece.x = old_x;
    piece.y = old_y;
    if (captured_piece != noone && instance_exists(captured_piece)) {
        captured_piece.visible = true;
    }
    
    // Force update moves again
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            event_perform(ev_step, ev_step_normal);
        }
    }
    
    return !still_in_check;
}