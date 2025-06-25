/// @function ai_generate_moves(color)
/// @param {real} color The color to generate moves for (0 = white, 1 = black)
/// @returns {array} Array of move structures

function ai_generate_moves(color) {
    var moves = [];
    
    with (Chess_Piece_Obj) {
        if (piece_type == color) {
            var piece_moves = ai_generate_piece_moves(id);
            for (var i = 0; i < array_length(piece_moves); i++) {
                array_push(moves, piece_moves[i]);
            }
        }
    }
    
    return moves;
}