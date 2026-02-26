/// @function ai_is_king_in_check_virtual(board, color)
/// @param {array} board Virtual board state
/// @param {real} color The color of the king to check (0=white, 1=black)
/// @returns {bool} Whether the king of the specified color is in check
/// @description Checks if a king is in check on the virtual board
function ai_is_king_in_check_virtual(board, color) {
    // Find the king position
    var king_col = -1;
    var king_row = -1;
    
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var piece = board[row][col];
            if (piece != noone && piece.piece_id == "king" && piece.piece_type == color) {
                king_col = col;
                king_row = row;
                break;
            }
        }
        if (king_col != -1) break;
    }
    
    // If no king found, assume in check (shouldn't happen)
    if (king_col == -1) return true;
    
    var enemy_color = (color == 0) ? 1 : 0;
    
    // Check for attacks from each enemy piece
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var piece = board[row][col];
            if (piece == noone || piece.piece_type != enemy_color) continue;
            
            // Check if this piece can attack the king
            if (ai_can_piece_attack_square(board, col, row, piece, king_col, king_row)) {
                return true;
            }
        }
    }
    
    return false;
}

/// @function ai_can_piece_attack_square(board, piece_col, piece_row, piece, target_col, target_row)
/// @description Checks if a specific piece can attack a target square
function ai_can_piece_attack_square(board, piece_col, piece_row, piece, target_col, target_row) {
    var dc = target_col - piece_col;
    var dr = target_row - piece_row;
    var abs_dc = abs(dc);
    var abs_dr = abs(dr);
    
    switch (piece.piece_id) {
        case "pawn":
            // Pawns attack diagonally
            var attack_dir = (piece.piece_type == 0) ? -1 : 1;
            return (abs_dc == 1 && dr == attack_dir);
            
        case "knight":
            // Knight attacks in L-shape
            return ((abs_dc == 2 && abs_dr == 1) || (abs_dc == 1 && abs_dr == 2));
            
        case "bishop":
            // Bishop attacks diagonally
            if (abs_dc != abs_dr || abs_dc == 0) return false;
            return ai_is_path_clear(board, piece_col, piece_row, target_col, target_row);
            
        case "rook":
            // Rook attacks orthogonally
            if (dc != 0 && dr != 0) return false;
            return ai_is_path_clear(board, piece_col, piece_row, target_col, target_row);
            
        case "queen":
            // Queen attacks diagonally or orthogonally
            if (!((abs_dc == abs_dr) || (dc == 0 || dr == 0))) return false;
            if (abs_dc == 0 && abs_dr == 0) return false;
            return ai_is_path_clear(board, piece_col, piece_row, target_col, target_row);
            
        case "king":
            // King attacks adjacent squares
            return (abs_dc <= 1 && abs_dr <= 1 && (abs_dc + abs_dr > 0));
    }
    
    return false;
}

/// @function ai_is_path_clear(board, from_col, from_row, to_col, to_row)
/// @description Checks if the path between two squares is clear
function ai_is_path_clear(board, from_col, from_row, to_col, to_row) {
    var dc = sign(to_col - from_col);
    var dr = sign(to_row - from_row);
    
    var col = from_col + dc;
    var row = from_row + dr;
    
    while (col != to_col || row != to_row) {
        if (board[row][col] != noone) return false;
        col += dc;
        row += dr;
    }
    
    return true;
}
