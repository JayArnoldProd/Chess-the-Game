/// @function ai_step_event_robust()
/// @description Robust AI step event that prevents loops

function ai_step_event_robust() {
    // Initialize safety variables
    if (!variable_instance_exists(id, "ai_move_count")) ai_move_count = 0;
    if (!variable_instance_exists(id, "ai_last_turn_check")) ai_last_turn_check = -1;
    if (!variable_instance_exists(id, "ai_cooldown")) ai_cooldown = 0;
    if (!variable_instance_exists(id, "ai_selected_move")) ai_selected_move = undefined;
    if (!variable_instance_exists(id, "think_start_time")) think_start_time = 0;
    if (!variable_instance_exists(id, "ai_timeout_count")) ai_timeout_count = 0;

    // Cooldown timer
    if (ai_cooldown > 0) {
        ai_cooldown--;
        exit;
    }

    // CRITICAL: Only think on AI's turn when enabled
    if (!ai_enabled || Game_Manager.turn != 1) {
        if (ai_thinking) {
            ai_thinking = false;
        }
        exit;
    }

    // CRITICAL: Don't think while ANY piece is moving
    var any_piece_moving = false;
    with (Chess_Piece_Obj) {
        if (is_moving) {
            any_piece_moving = true;
            break;
        }
    }

    if (any_piece_moving) {
        exit;
    }

    // ENHANCED LOOP DETECTION
    if (ai_last_turn_check == Game_Manager.turn) {
        ai_move_count++;
        if (ai_move_count > 3) { // Reduced threshold
            show_debug_message("AI: LOOP DETECTED! Count: " + string(ai_move_count));
            ai_emergency_stop();
            exit;
        }
    } else {
        ai_move_count = 0;
        ai_last_turn_check = Game_Manager.turn;
    }

    // Reset thinking if it's a new turn
    if (!ai_thinking && ai_move_delay <= 0) {
        ai_thinking = true;
        think_start_time = current_time;
        ai_selected_move = undefined;
    }

    // AI thinking with multiple safeguards
    if (ai_thinking) {
        var elapsed_time = current_time - think_start_time;
        
        // TIMEOUT PROTECTION
        if (elapsed_time > 2000) { // 2 second max
            ai_timeout_count++;
            show_debug_message("AI: TIMEOUT! Count: " + string(ai_timeout_count));
            
            if (ai_timeout_count > 2) {
                ai_emergency_stop();
                exit;
            } else {
                Game_Manager.turn = 0;
                ai_thinking = false;
                ai_cooldown = 30;
                exit;
            }
        }
        
        // Generate NON-REPETITIVE moves
        try {
            var legal_moves = ai_get_non_repetitive_moves(1);
            
            if (array_length(legal_moves) == 0) {
                show_debug_message("AI: No moves available");
                Game_Manager.turn = 0;
                ai_thinking = false;
                exit;
            }
            
            // Simple move selection
            var best_move = legal_moves[0];
            var best_score = -999;
            
            var moves_to_check = min(array_length(legal_moves), 5); // Reduced for speed
            
            for (var i = 0; i < moves_to_check; i++) {
                var move = legal_moves[i];
                
                if (!instance_exists(move.piece) || move.piece.is_moving) continue;
                
                var score_ = 0;
                
                // Prefer captures
                if (move.is_capture) score_ += 300;
                
                // Prefer center moves
                var target_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
                var target_rank = round((move.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
                if (target_file >= 2 && target_file <= 5 && target_rank >= 2 && target_rank <= 5) {
                    score_ += 100;
                }
                
                // Add randomness
                score_ += irandom(50);
                
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
            ai_cooldown = 60;
            exit;
        }
        
        // Finish thinking
        if (elapsed_time > 100) { // Minimum think time
            ai_thinking = false;
            ai_timeout_count = 0; // Reset timeout counter on successful think
        }
    }

    // Execute move with robust function
    if (!ai_thinking && ai_selected_move != undefined && ai_move_delay <= 0) {
        
        if (!instance_exists(ai_selected_move.piece) || ai_selected_move.piece.is_moving) {
            ai_selected_move = undefined;
            Game_Manager.turn = 0;
            exit;
        }
        
        var success = ai_execute_move_fast_robust(ai_selected_move);
        ai_selected_move = undefined;
        
        if (success) {
            ai_cooldown = 30; // Brief cooldown after successful move
        } else {
            ai_cooldown = 60; // Longer cooldown after failed move
        }
    }

    // Decrease delay
    if (ai_move_delay > 0) {
        ai_move_delay--;
    }
}