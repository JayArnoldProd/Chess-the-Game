/// @function ai_clear_transposition_table()
/// @description Clears the transposition table

function ai_clear_transposition_table() {
    for (var i = 0; i < tt_size; i++) {
        tt_table[i] = {
            key: 0,
            depth: 0,
            score: 0,
            flag: 0,
            best_move: undefined,
            age: 0
        };
    }
    tt_age = 0;
    show_debug_message("Transposition table cleared");
}
