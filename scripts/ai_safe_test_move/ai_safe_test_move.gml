/// @function ai_safe_test_move()
/// @description Tests if AI can make a safe move
function ai_safe_test_move() {
    show_debug_message("=== TESTING AI MOVE SAFETY ===");
    
    if (Game_Manager.turn != 1) {
        show_debug_message("Not AI's turn - switching to AI turn for test");
        Game_Manager.turn = 1;
    }
    
    // Check for moving pieces
    var moving_pieces = 0;
    with (Chess_Piece_Obj) {
        if (is_moving) moving_pieces++;
    }
    
    if (moving_pieces > 0) {
        show_debug_message("WARNING: " + string(moving_pieces) + " pieces still moving");
        ai_fix_stuck_pieces();
    }
    
    // Test move generation
    try {
        var legal_moves = ai_get_legal_moves_fast_fixed(1);
        show_debug_message("Found " + string(array_length(legal_moves)) + " legal moves for black");
        
        if (array_length(legal_moves) > 0) {
            var test_move = legal_moves[0];
            show_debug_message("Test move: " + test_move.piece_id + 
                             " from (" + string(test_move.from_x) + "," + string(test_move.from_y) + ")" +
                             " to (" + string(test_move.to_x) + "," + string(test_move.to_y) + ")");
            
            // Validate the move
            if (instance_exists(test_move.piece)) {
                show_debug_message("✓ Test move piece exists");
                return true;
            } else {
                show_debug_message("✗ Test move piece doesn't exist");
                return false;
            }
        } else {
            show_debug_message("No legal moves available");
            return false;
        }
        
    } catch (error) {
        show_debug_message("Error in move generation: " + string(error));
        return false;
    }
}
