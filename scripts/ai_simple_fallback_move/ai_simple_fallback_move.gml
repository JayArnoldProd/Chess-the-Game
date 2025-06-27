/// @function ai_simple_fallback_move()
/// @description Ultra-simple move selection for emergencies
function ai_simple_fallback_move() {
    try {
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) == 0) return undefined;
        
        // Look for captures first
        for (var i = 0; i < array_length(moves); i++) {
            if (moves[i].is_capture) {
                return moves[i];
            }
        }
        
        // Otherwise return first move
        return moves[0];
        
    } catch (error) {
        show_debug_message("Emergency fallback failed: " + string(error));
        return undefined;
    }
}
