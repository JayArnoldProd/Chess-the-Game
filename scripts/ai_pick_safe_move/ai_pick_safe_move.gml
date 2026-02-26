/// @function ai_pick_safe_move(moves)
/// @param {array} moves Array of legal moves (already filtered by ai_get_legal_moves_safe)
/// @returns {struct} Best safe move
function ai_pick_safe_move(moves) {
    if (array_length(moves) == 0) {
        show_debug_message("ai_pick_safe_move: No moves available - likely checkmate!");
        return undefined;
    }
    
    var king_in_check = ai_is_king_in_check_simple(1);
    var safe_moves = [];
    
    if (king_in_check) {
        show_debug_message("ai_pick_safe_move: AI king is in check! Must escape.");
    }
    
    // Evaluate each move
    // Note: Moves are already filtered for legality by ai_get_legal_moves_safe,
    // so all moves here should be legal (don't leave king in check)
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        if (!instance_exists(move.piece)) continue;
        
        var score_ = 0;
        
        // When in check, prioritize escape moves (bonus for escaping)
        if (king_in_check) {
            score_ += 1000; // All legal moves when in check are escape moves
        }
        
        // Extra validation: verify the move doesn't leave king in check
        // (defense in depth - ai_get_legal_moves_safe should have already filtered these)
        var _vboard = ai_build_virtual_board();
        var from_col = round((move.from_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var from_row = round((move.from_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        var to_col = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var to_row = round((move.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        
        var vmove = {
            from_col: from_col,
            from_row: from_row,
            to_col: to_col,
            to_row: to_row,
            is_capture: move.is_capture,
            piece_id: move.piece_id,
            piece_type: move.piece_type
        };
        
        var test_board = ai_copy_board(_vboard);
        ai_make_move_virtual(test_board, vmove);
        
        if (ai_is_king_in_check_virtual(test_board, move.piece_type)) {
            show_debug_message("ai_pick_safe_move: REJECTED illegal move by " + move.piece_id + " - would leave king in check!");
            continue; // Skip this move - it's illegal
        }
        
        // Prefer captures
        if (move.is_capture && instance_exists(move.captured_piece)) {
            var captured_value = ai_get_piece_value(move.captured_piece.piece_id);
            score_ += captured_value;
            
            // HUGE bonus for capturing attacking piece when in check
            if (king_in_check) {
                score_ += 500;
            }
        }
        
        // Prefer center moves
        var target_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        if (target_file >= 2 && target_file <= 5) {
            score_ += 20;
        }
        
        // Prefer piece development
        if (!move.piece.has_moved && (move.piece_id == "knight" || move.piece_id == "bishop")) {
            score_ += 30;
        }
        
        // King moves get slight priority when in check (king safety)
        if (king_in_check && move.piece_id == "king") {
            score_ += 200;
        }
        
        // Stepping stone bonus
        var on_stepping_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
        if (on_stepping_stone) {
            score_ += 100;
        }
        
        // Add randomness for variety
        score_ += irandom(20);
        
        move.ai_score = score_;
        array_push(safe_moves, move);
    }
    
    if (array_length(safe_moves) == 0) {
        show_debug_message("ai_pick_safe_move: No legal moves after filtering - CHECKMATE!");
        return undefined;
    }
    
    // Sort by score_ (highest first)
    for (var i = 0; i < array_length(safe_moves) - 1; i++) {
        for (var j = i + 1; j < array_length(safe_moves); j++) {
            if (safe_moves[j].ai_score > safe_moves[i].ai_score) {
                var temp = safe_moves[i];
                safe_moves[i] = safe_moves[j];
                safe_moves[j] = temp;
            }
        }
    }
    
    // Pick from top 3 moves for some variety
    var top_moves = min(3, array_length(safe_moves));
    var chosen = safe_moves[irandom(top_moves - 1)];
    
    show_debug_message("ai_pick_safe_move: Chose " + chosen.piece_id + " with score " + string(chosen.ai_score));
    
    return chosen;
}