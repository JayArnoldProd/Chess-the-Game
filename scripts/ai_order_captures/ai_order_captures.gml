/// @function ai_order_captures(moves)
/// @param {array} moves Array of capture moves
/// @returns {array} Ordered capture moves

function ai_order_captures(moves) {
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var victim_value = move.captured_data ? AI_Manager.piece_values[$ move.captured_data.piece_id] : 100;
        var attacker_value = AI_Manager.piece_values[$ move.piece_data.piece_id];
        move.order_score = victim_value * 10 - attacker_value;
    }
    
    // Sort by score
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
