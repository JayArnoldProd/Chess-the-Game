/// @function ai_update_history(move, depth)
/// @param {struct} move The move to update
/// @param {real} depth Search depth

function ai_update_history(move, depth) {
    var from_square = ai_get_square_index(move.from_x, move.from_y);
    var to_square = ai_get_square_index(move.to_x, move.to_y);
    
    if (from_square >= 0 && from_square < 64 && to_square >= 0 && to_square < 64) {
        history_table[from_square][to_square] += depth * depth;
        
        // Prevent overflow
        if (history_table[from_square][to_square] > 10000) {
            // Age all history scores
            for (var i = 0; i < 64; i++) {
                for (var j = 0; j < 64; j++) {
                    history_table[i][j] = history_table[i][j] div 2;
                }
            }
        }
    }
}