// AI_Manager Step Event - Improved with Error Handling

// Only act when it's black's turn and AI is enabled
if (!ai_enabled || Game_Manager.turn != 1) exit;

// Don't act if any piece is currently moving
var pieces_moving = false;
with (Chess_Piece_Obj) {
    if (instance_exists(id) && is_moving) {
        pieces_moving = true;
        break;
    }
}
if (pieces_moving) exit;

// Start thinking if not already thinking
if (!ai_thinking) {
    ai_thinking = true;
    ai_move_timer = ai_move_delay;
    
    show_debug_message("AI is thinking...");
    
    try {
        // Update all piece valid moves before thinking
        ai_update_piece_valid_moves();
        
        // Check if we have any legal moves
        var legal_moves = ai_get_legal_moves(1);
        show_debug_message("AI has " + string(array_length(legal_moves)) + " legal moves");
        
        if (array_length(legal_moves) == 0) {
            show_debug_message("AI has no legal moves!");
            ai_thinking = false;
            best_move = undefined;
            exit;
        }
        
        // Find the best move using minimax
        best_move = ai_find_best_move(ai_depth);
        
        if (best_move != undefined) {
            show_debug_message("AI found move from " + string(best_move.from_x) + "," + string(best_move.from_y) + " to " + string(best_move.to_x) + "," + string(best_move.to_y));
        } else {
            show_debug_message("AI could not find a move!");
        }
    } catch (error) {
        show_debug_message("AI Error during thinking: " + string(error));
        ai_thinking = false;
        best_move = undefined;
        exit;
    }
}

// Execute move after delay
if (ai_thinking && ai_move_timer > 0) {
    ai_move_timer--;
    if (ai_move_timer <= 0) {
        try {
            if (best_move != undefined) {
                show_debug_message("AI executing move...");
                ai_execute_move(best_move);
                show_debug_message("AI move completed");
            } else {
                show_debug_message("AI has no move to execute");
            }
        } catch (error) {
            show_debug_message("AI Error during move execution: " + string(error));
        }
        ai_thinking = false;
        best_move = undefined;
    }
}