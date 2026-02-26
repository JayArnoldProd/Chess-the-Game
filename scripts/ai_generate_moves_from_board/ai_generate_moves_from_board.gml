/// @function ai_generate_moves_from_board(board, color)
/// @param {array} board Virtual board state
/// @param {real} color 0=white, 1=black
/// @returns {array} Array of all legal moves for this color
/// @description Generates all legal moves for a color from virtual board state
function ai_generate_moves_from_board(board, color) {
    var all_moves = [];
    
    // First, generate all pseudo-legal moves
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var piece = board[row][col];
            if (piece == noone || piece.piece_type != color) continue;
            
            var piece_moves = ai_get_piece_moves_virtual(board, col, row, piece);
            
            // Add piece info to each move
            for (var i = 0; i < array_length(piece_moves); i++) {
                piece_moves[i].piece_id = piece.piece_id;
                piece_moves[i].piece_type = piece.piece_type;
                array_push(all_moves, piece_moves[i]);
            }
        }
    }
    
    // Filter out moves that leave the king in check
    var legal_moves = [];
    for (var i = 0; i < array_length(all_moves); i++) {
        var move = all_moves[i];
        
        // Make the move on a copy of the board
        var test_board = ai_copy_board(board);
        ai_make_move_virtual(test_board, move);
        
        // Check if our king is in check after this move
        if (!ai_is_king_in_check_virtual(test_board, color)) {
            array_push(legal_moves, move);
        }
    }
    
    return legal_moves;
}
