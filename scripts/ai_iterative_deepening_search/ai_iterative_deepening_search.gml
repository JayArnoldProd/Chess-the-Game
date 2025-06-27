/// @function ai_iterative_deepening_search() - SIMPLIFIED AND FIXED
/// @returns {bool} Whether search is complete
function ai_iterative_deepening_search() {
    // For now, just use the fast search to avoid complexity
    // This can be enhanced later once basic system is stable
    try {
        ai_selected_move = ai_fast_tactical_search();
        return true; // Always complete immediately
        
    } catch (error) {
        show_debug_message("Error in iterative deepening: " + string(error));
        // Emergency fallback
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            ai_selected_move = moves[0];
        }
        return true;
    }
}