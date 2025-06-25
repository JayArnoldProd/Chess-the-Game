/// @function ai_is_legal_move(move)
/// @param {struct} move The move to validate
/// @returns {bool} Whether the move is legal

function ai_is_legal_move(move) {
    // Make the move temporarily
    var game_state = ai_save_game_state();
    ai_make_move_simulation(move);
    
    // Check if the king is in check after the move
    var king_in_check = ai_is_king_in_check(move.piece_data.piece_type);
    
    // Restore the game state
    ai_restore_game_state(game_state);
    
    return !king_in_check;
}