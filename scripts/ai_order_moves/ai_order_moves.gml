/// @function ai_order_moves(moves)
/// @param {array} moves Array of moves to order
/// @returns {array} Ordered moves (best first)

function ai_order_moves(moves) {
    // Simple move ordering: captures first, then other moves
    var ordered_moves = [];
    var capture_moves = [];
    var other_moves = [];
    
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        if (move.is_capture) {
            // Calculate capture value
            var capture_value = 0;
            if (move.captured_data != noone) {
                capture_value = AI_Manager.piece_values[$ move.captured_data.piece_id];
                capture_value -= AI_Manager.piece_values[$ move.piece_data.piece_id]; // MVV-LVA
            }
            move.order_value = capture_value;
            array_push(capture_moves, move);
        } else {
            move.order_value = 0;
            array_push(other_moves, move);
        }
    }
    
    // Sort captures by value (highest first)
    for (var i = 0; i < array_length(capture_moves) - 1; i++) {
        for (var j = i + 1; j < array_length(capture_moves); j++) {
            if (capture_moves[j].order_value > capture_moves[i].order_value) {
                var temp = capture_moves[i];
                capture_moves[i] = capture_moves[j];
                capture_moves[j] = temp;
            }
        }
    }
    
    // Combine arrays (captures first)
    for (var i = 0; i < array_length(capture_moves); i++) {
        array_push(ordered_moves, capture_moves[i]);
    }
    for (var i = 0; i < array_length(other_moves); i++) {
        array_push(ordered_moves, other_moves[i]);
    }
    
    return ordered_moves;
}
