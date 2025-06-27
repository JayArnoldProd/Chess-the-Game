/// @function ai_analyze_position_complexity()
/// @returns {real} Position complexity score (0-100) - FIXED
function ai_analyze_position_complexity() {
    var complexity = 0;
    
    // Safely get legal moves
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        
        // More legal moves = more complex
        complexity += array_length(legal_moves) * 2;
        
        // Captures and checks increase complexity
        var captures = 0;
        var checks = 0;
        for (var i = 0; i < array_length(legal_moves); i++) {
            if (legal_moves[i].is_capture) captures++;
            if (ai_move_gives_check_fast(legal_moves[i])) checks++;
        }
        complexity += captures * 5 + checks * 8;
        
    } catch (error) {
        show_debug_message("Error in position analysis: " + string(error));
        complexity = 30; // Default complexity
    }
    
    // King safety affects complexity
    if (ai_is_king_in_check(1)) complexity += 20;
    if (ai_is_king_in_check(0)) complexity += 15;
    
    // Endgame is more complex
    var piece_count = instance_number(Chess_Piece_Obj);
    if (piece_count <= 12) complexity += 15;
    
    return clamp(complexity, 0, 100);
}