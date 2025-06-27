/// @function ai_store_transposition_table(depth, score, flag, best_move)
/// @param {real} depth Search depth
/// @param {real} score Position score
/// @param {real} flag 0=exact, 1=lower, 2=upper
/// @param {struct} best_move Best move found

function ai_store_transposition_table(depth, score, flag, best_move) {
    var board_hash = ai_get_board_hash();
    var index = board_hash mod tt_size;
    var entry = tt_table[index];
    
    // Always replace or replace if deeper/newer
    if (entry.key == 0 || entry.depth <= depth || entry.age < tt_age - 4) {
        entry.key = board_hash;
        entry.depth = depth;
        entry.score = score;
        entry.flag = flag;
        entry.best_move = best_move;
        entry.age = tt_age;
    }
}