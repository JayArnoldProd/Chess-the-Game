/// AI_Manager Step Event - SIMPLIFIED (No stepping stone handling)
if (!ai_enabled || Game_Manager.turn != 1) {
    exit; // Only run on AI's turn
}

// Don't move while pieces are animating
var any_moving = false;
with (Chess_Piece_Obj) {
    if (is_moving) {
        any_moving = true;
        break;
    }
}
if (any_moving) exit;

// Initialize delay
if (!variable_instance_exists(id, "ai_move_delay")) ai_move_delay = 30;

// Wait for delay
if (ai_move_delay > 0) {
    ai_move_delay--;
    exit;
}

// Get legal moves and pick one
try {
    var legal_moves = ai_get_legal_moves_fast(1);
    
    if (array_length(legal_moves) == 0) {
        Game_Manager.turn = 0;
        show_debug_message("AI: No legal moves available (checkmate or stalemate)");
        exit;
    }
    
    // Sort moves by score
    var scored_moves = [];
    for (var i = 0; i < array_length(legal_moves); i++) {
        var move = legal_moves[i];
        if (!instance_exists(move.piece)) continue;
        
        move.score = ai_score_move_fast(move);
        array_push(scored_moves, move);
    }
    
    // Sort by score (highest first)
    for (var i = 0; i < array_length(scored_moves) - 1; i++) {
        for (var j = i + 1; j < array_length(scored_moves); j++) {
            if (scored_moves[j].score > scored_moves[i].score) {
                var temp = scored_moves[i];
                scored_moves[i] = scored_moves[j];
                scored_moves[j] = temp;
            }
        }
    }
    
    // Pick from top moves
    var moves_to_consider = min(array_length(scored_moves), max_moves_to_consider);
    var best_move = scored_moves[irandom(max(0, moves_to_consider - 1))]; // Some randomness
    
    // Execute the move
    if (instance_exists(best_move.piece)) {
        ai_execute_move_simple(best_move);
        show_debug_message("AI: Moved " + best_move.piece_id + " (score: " + string(best_move.score) + ")");
    } else {
        Game_Manager.turn = 0;
    }
    
    ai_move_delay = 30;
    
} catch (error) {
    show_debug_message("AI Error: " + string(error));
    Game_Manager.turn = 0;
    ai_move_delay = 60;
}