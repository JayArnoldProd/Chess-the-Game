/// @function ai_emergency_move()
/// @returns {struct} Emergency random legal move

function ai_emergency_move() {
    show_debug_message("AI using emergency move selection");
    var legal_moves = ai_get_legal_moves(1);
    
    if (array_length(legal_moves) > 0) {
        return legal_moves[irandom(array_length(legal_moves) - 1)];
    }
    
    return undefined;
}
