/// @function ai_make_move_virtual(board, move)
/// @param {array} board Virtual board state (modified in place)
/// @param {struct} move The move to make
/// @description Applies a move to the virtual board state
function ai_make_move_virtual(board, move) {
    var from_col = move.from_col;
    var from_row = move.from_row;
    var to_col = move.to_col;
    var to_row = move.to_row;
    
    // Get the piece
    var piece = board[from_row][from_col];
    if (piece == noone) return;
    
    // Handle special moves
    var special = variable_struct_exists(move, "special") ? move.special : "";
    
    if (special == "castle_k") {
        // Kingside castle - move king and rook
        board[to_row][to_col] = piece;
        piece.has_moved = true;
        board[from_row][from_col] = noone;
        
        // Move rook
        var rook = board[from_row][7];
        board[from_row][5] = rook;
        if (rook != noone) rook.has_moved = true;
        board[from_row][7] = noone;
        
    } else if (special == "castle_q") {
        // Queenside castle - move king and rook
        board[to_row][to_col] = piece;
        piece.has_moved = true;
        board[from_row][from_col] = noone;
        
        // Move rook
        var rook = board[from_row][0];
        board[from_row][3] = rook;
        if (rook != noone) rook.has_moved = true;
        board[from_row][0] = noone;
        
    } else {
        // Normal move
        board[to_row][to_col] = piece;
        piece.has_moved = true;
        board[from_row][from_col] = noone;
        
        // Handle pawn promotion
        if (piece.piece_id == "pawn") {
            if ((piece.piece_type == 0 && to_row == 0) || (piece.piece_type == 1 && to_row == 7)) {
                // Promote to queen (simplification)
                piece.piece_id = "queen";
            }
        }
    }
}
