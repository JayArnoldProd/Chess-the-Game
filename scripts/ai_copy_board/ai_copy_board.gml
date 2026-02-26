/// @function ai_copy_board(board)
/// @param {array} board The virtual board to copy
/// @returns {array} Deep copy of the board
/// @description Creates a deep copy of a virtual board state
function ai_copy_board(board) {
    var new_board = array_create(8);
    
    for (var row = 0; row < 8; row++) {
        new_board[row] = array_create(8, noone);
        for (var col = 0; col < 8; col++) {
            var piece = board[row][col];
            if (piece != noone) {
                // Deep copy the piece struct
                new_board[row][col] = {
                    piece_id: piece.piece_id,
                    piece_type: piece.piece_type,
                    has_moved: piece.has_moved,
                    instance: piece.instance
                };
            }
        }
    }
    
    return new_board;
}
