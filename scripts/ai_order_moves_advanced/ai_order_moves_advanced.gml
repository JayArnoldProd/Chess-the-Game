/// @function ai_order_moves_advanced(moves, ply)
/// @param {array} moves Array of moves to order
/// @param {real} ply Current ply (optional, defaults to 0)
/// @returns {array} Ordered moves (best first)

function ai_order_moves_advanced(moves, ply = 0) {
    // score_ each move for ordering
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var score_ = 0;
        
        // 1. Hash move (from transposition table) gets highest priority
        var tt_entry = ai_probe_transposition_table_move();
        if (tt_entry != undefined && ai_moves_equal(move, tt_entry.best_move)) {
            score_ += 10000;
        }
        
        // 2. Captures (MVV-LVA: Most Valuable Victim, Least Valuable Attacker)
        else if (move.is_capture) {
            var victim_value = move.captured_data ? AI_Manager.piece_values[$ move.captured_data.piece_id] : 100;
            var attacker_value = AI_Manager.piece_values[$ move.piece_data.piece_id];
            score_ += 8000 + victim_value - (attacker_value / 10);
        }
        
        // 3. Killer moves
        else if (ply < array_length(killer_moves)) {
            if (ai_moves_equal(move, killer_moves[ply][0])) {
                score_ += 6000;
            } else if (ai_moves_equal(move, killer_moves[ply][1])) {
                score_ += 5000;
            }
        }
        
        // 4. History heuristic
        else {
            var from_square = ai_get_square_index(move.from_x, move.from_y);
            var to_square = ai_get_square_index(move.to_x, move.to_y);
            if (from_square >= 0 && from_square < 64 && to_square >= 0 && to_square < 64) {
                score_ += history_table[from_square][to_square];
            }
        }
        
        // 5. Castling bonus
        if (move.is_castling) {
            score_ += 4000;
        }
        
        // 6. Pawn promotions
        if (move.piece_data.piece_id == "pawn") {
            var target_rank = ai_get_rank(move.to_y);
            if ((move.piece_data.piece_type == 0 && target_rank == 7) || 
                (move.piece_data.piece_type == 1 && target_rank == 0)) {
                score_ += 7000; // Promotion
            }
        }
        
        // 7. Center control bonus
        var to_square = ai_get_square_index(move.to_x, move.to_y);
        if (to_square == 27 || to_square == 28 || to_square == 35 || to_square == 36) { // e4, d4, e5, d5
            score_ += 100;
        }
        
        move.order_score = score_;
    }
    
    // Sort moves by score_ (highest first)
    for (var i = 0; i < array_length(moves) - 1; i++) {
        for (var j = i + 1; j < array_length(moves); j++) {
            if (moves[j].order_score > moves[i].order_score) {
                var temp = moves[i];
                moves[i] = moves[j];
                moves[j] = temp;
            }
        }
    }
    
    return moves;
}
