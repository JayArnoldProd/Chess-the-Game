/// @function ai_update_killer_move(move, ply)
/// @param {struct} move The killer move
/// @param {real} ply Current ply

function ai_update_killer_move(move, ply) {
    if (ply >= 0 && ply < array_length(killer_moves)) {
        // Shift killer moves
        if (!ai_moves_equal(move, killer_moves[ply][0])) {
            killer_moves[ply][1] = killer_moves[ply][0];
            killer_moves[ply][0] = move;
        }
    }
}