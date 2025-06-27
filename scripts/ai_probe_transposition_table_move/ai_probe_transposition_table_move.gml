/// @function ai_probe_transposition_table_move()
/// @returns {struct} TT entry with move or undefined

function ai_probe_transposition_table_move() {
    var board_hash = ai_get_board_hash();
    var index = board_hash mod tt_size;
    var entry = tt_table[index];
    
    if (entry.key == board_hash && entry.best_move != undefined) {
        return entry;
    }
    
    return undefined;
}