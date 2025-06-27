/// @function ai_test_move_generation()
/// @description Tests if move generation works
function ai_test_move_generation() {
    show_debug_message("=== TESTING MOVE GENERATION ===");
    
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        show_debug_message("Generated " + string(array_length(legal_moves)) + " moves for black");
        
        if (array_length(legal_moves) > 0) {
            var test_move = legal_moves[0];
            show_debug_message("Sample move: " + test_move.piece_id + 
                              " from (" + string(test_move.from_x) + "," + string(test_move.from_y) + ")" +
                              " to (" + string(test_move.to_x) + "," + string(test_move.to_y) + ")");
        }
        
        // Test move scoring
        if (array_length(legal_moves) > 0) {
            var score_ = ai_score_move_fast(legal_moves[0]);
            show_debug_message("Move score: " + string(score_));
        }
        
    } catch (error) {
        show_debug_message("ERROR in move generation: " + string(error));
    }
    
    show_debug_message("=== END TEST ===");
}
