/// @function ai_comprehensive_debug()
/// @description Complete AI system diagnostic
function ai_comprehensive_debug() {
    show_debug_message("=== COMPREHENSIVE AI DEBUG ===");
    
    // System Status
    show_debug_message("AI Enabled: " + string(AI_Manager.ai_enabled));
    show_debug_message("Current Turn: " + string(Game_Manager.turn));
    show_debug_message("AI Thinking: " + string(AI_Manager.ai_thinking));
    
    // Performance Metrics
    if (variable_instance_exists(AI_Manager, "last_move_time")) {
        show_debug_message("Last Move Time: " + string(AI_Manager.last_move_time) + "ms");
    }
    
    if (variable_instance_exists(AI_Manager, "search_efficiency")) {
        show_debug_message("Search Efficiency: " + string(AI_Manager.search_efficiency));
    }
    
    // Position Analysis
    if (variable_instance_exists(AI_Manager, "position_complexity")) {
        show_debug_message("Position Complexity: " + string(AI_Manager.position_complexity));
    }
    
    // Legal Moves Check
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        show_debug_message("Legal Moves for Black: " + string(array_length(legal_moves)));
        
        // Check for illegal moves
        var illegal_count = 0;
        for (var i = 0; i < array_length(legal_moves); i++) {
            var move = legal_moves[i];
            if (!ai_validate_move_legality(move)) {
                illegal_count++;
                show_debug_message("ILLEGAL MOVE DETECTED: " + move.piece_id + 
                                 " from (" + string(move.from_x) + "," + string(move.from_y) + ")" +
                                 " to (" + string(move.to_x) + "," + string(move.to_y) + ")");
            }
        }
        show_debug_message("Illegal Moves Found: " + string(illegal_count));
        
    } catch (error) {
        show_debug_message("ERROR in move generation: " + string(error));
    }
    
    // Piece Count and Board State
    var white_pieces = 0;
    var black_pieces = 0;
    with (Chess_Piece_Obj) {
        if (piece_type == 0) white_pieces++;
        else if (piece_type == 1) black_pieces++;
    }
    show_debug_message("Pieces - White: " + string(white_pieces) + ", Black: " + string(black_pieces));
    
    // Memory and Performance
    show_debug_message("Game Objects: " + string(instance_count));
    
    show_debug_message("=== END COMPREHENSIVE DEBUG ===");
}