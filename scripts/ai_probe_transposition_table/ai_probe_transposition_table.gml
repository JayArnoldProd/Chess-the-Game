/// @function ai_probe_transposition_table(depth)
/// @param {real} depth Current depth
/// @returns {struct} TT entry or undefined

function ai_probe_transposition_table(depth) {
    var board_hash = ai_get_board_hash();
    var index = board_hash mod tt_size;
    var entry = tt_table[index];
    
    if (entry.key == board_hash && entry.depth >= depth) {
        return entry;
    }
    
    return undefined;
}