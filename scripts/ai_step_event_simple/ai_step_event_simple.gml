/// @function ai_step_event_simple()
/// @description Simple AI step event without complex loop detection
function ai_step_event_simple() {
    // Initialize basic variables if missing
    if (!variable_instance_exists(id, "ai_selected_move")) ai_selected_move = undefined;
    if (!variable_instance_exists(id, "think_start_time")) think_start_time = 0;
    if (!variable_instance_exists(id, "ai_move_attempts")) ai_move_attempts = 0;

    // Only think on AI's turn when enabled
    if (!ai_enabled || Game_Manager.turn != 1) {
        if (ai_thinking) {
            ai_thinking = false;
        }
        exit;
    }

    // Don't think while pieces are moving
    var any_moving = false;
    with (Chess_Piece_Obj) {
        if (is_moving) {
            any_moving = true;
            break;
        }
    }
    if (any_moving) exit;

    // Start thinking
    if (!ai_thinking && ai_move_delay <= 0) {
        ai_thinking = true;
        think_start_time = current_time;
        ai_selected_move = undefined;
        show_debug_message("AI: Starting to think...");
    }

    // AI thinking process
    if (ai_thinking) {
        var elapsed = current_time - think_start_time;
        
        // Timeout protection
        if (elapsed > 3000) {
            show_debug_message("AI: Timeout, skipping turn");
            Game_Manager.turn = 0;
            ai_thinking = false;
            exit;
        }
        
        // Simple move selection
        try {
            var legal_moves = ai_get_legal_moves_fast(1);
            
            if (array_length(legal_moves) == 0) {
                show_debug_message("AI: No legal moves");
                Game_Manager.turn = 0;
                ai_thinking = false;
                exit;
            }
            
            // Pick best move simply
            var best_move = legal_moves[0];
            var best_score = -999;
            
            for (var i = 0; i < min(array_length(legal_moves), 10); i++) {
                var move = legal_moves[i];
                if (!instance_exists(move.piece)) continue;
                
                var score_ = 0;
                if (move.is_capture) score_ += 200;
                score_ += irandom(100); // Add randomness
                
                if (score_ > best_score) {
                    best_score = score_;
                    best_move = move;
                }
            }
            
            ai_selected_move = best_move;
            
        } catch (error) {
            show_debug_message("AI Error: " + string(error));
            Game_Manager.turn = 0;
            ai_thinking = false;
            exit;
        }
        
        // Finish thinking after minimum time
        if (elapsed > 500) {
            ai_thinking = false;
            show_debug_message("AI: Move selected");
        }
    }

    // Execute move
    if (!ai_thinking && ai_selected_move != undefined && ai_move_delay <= 0) {
        if (!instance_exists(ai_selected_move.piece)) {
            ai_selected_move = undefined;
            Game_Manager.turn = 0;
            exit;
        }
        
        try {
            var success = ai_execute_move_simple(ai_selected_move);
            ai_selected_move = undefined;
            
            if (!success) {
                Game_Manager.turn = 0;
            }
            
        } catch (error) {
            show_debug_message("AI Execute Error: " + string(error));
            ai_selected_move = undefined;
            Game_Manager.turn = 0;
        }
    }

    // Decrease delay
    if (ai_move_delay > 0) {
        ai_move_delay--;
    }
}