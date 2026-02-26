/// @function ai_alphabeta(board, depth, alpha, beta, maximizing, stones)
/// @param {array} board Virtual board state
/// @param {real} depth Remaining search depth
/// @param {real} alpha Alpha bound (best score maximizer can guarantee)
/// @param {real} beta Beta bound (best score minimizer can guarantee)
/// @param {bool} maximizing True if maximizing player (black/AI)
/// @param {array} stones Array of stepping stone positions (for bonus evaluation)
/// @returns {struct} Object with score and best_move
/// @description Alpha-beta minimax search
function ai_alphabeta(board, depth, alpha, beta, maximizing, stones) {
    var color = maximizing ? 1 : 0;
    
    // Generate legal moves
    var moves = ai_generate_moves_from_board(board, color);
    
    // Terminal conditions
    if (array_length(moves) == 0) {
        // No legal moves - checkmate or stalemate
        var in_check = ai_is_king_in_check_virtual(board, color);
        if (in_check) {
            // Checkmate - worst possible score for the side that's mated
            return { score: maximizing ? -99999 + (10 - depth) : 99999 - (10 - depth), move: undefined };
        } else {
            // Stalemate - draw
            return { score: 0, move: undefined };
        }
    }
    
    // Depth 0 - evaluate position
    if (depth == 0) {
        return { score: ai_evaluate_virtual(board), move: undefined };
    }
    
    // Order moves for better pruning (captures first, then piece value)
    moves = ai_order_moves_virtual(moves);
    
    var best_move = moves[0];
    
    if (maximizing) {
        var max_eval = -999999;
        
        for (var i = 0; i < array_length(moves); i++) {
            var move = moves[i];
            
            // Make move on copy of board
            var new_board = ai_copy_board(board);
            ai_make_move_virtual(new_board, move);
            
            // Check if move lands on stepping stone for bonus
            var stone_bonus = 0;
            if (array_length(stones) > 0) {
                for (var s = 0; s < array_length(stones); s++) {
                    if (stones[s][0] == move.to_col && stones[s][1] == move.to_row) {
                        stone_bonus = 50; // Stepping stone bonus
                        break;
                    }
                }
            }
            
            // Recursive search
            var result = ai_alphabeta(new_board, depth - 1, alpha, beta, false, stones);
            var eval_score = result.score + stone_bonus;
            
            if (eval_score > max_eval) {
                max_eval = eval_score;
                best_move = move;
            }
            
            alpha = max(alpha, eval_score);
            if (beta <= alpha) break; // Prune
        }
        
        return { score: max_eval, move: best_move };
        
    } else {
        var min_eval = 999999;
        
        for (var i = 0; i < array_length(moves); i++) {
            var move = moves[i];
            
            // Make move on copy of board
            var new_board = ai_copy_board(board);
            ai_make_move_virtual(new_board, move);
            
            // Recursive search
            var result = ai_alphabeta(new_board, depth - 1, alpha, beta, true, stones);
            var eval_score = result.score;
            
            if (eval_score < min_eval) {
                min_eval = eval_score;
                best_move = move;
            }
            
            beta = min(beta, eval_score);
            if (beta <= alpha) break; // Prune
        }
        
        return { score: min_eval, move: best_move };
    }
}

/// @function ai_order_moves_virtual(moves)
/// @description Orders moves for better alpha-beta pruning
function ai_order_moves_virtual(moves) {
    // Score each move for ordering
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var order_score = 0;
        
        // Captures first (MVV-LVA: Most Valuable Victim - Least Valuable Attacker)
        if (move.is_capture) {
            order_score += 1000;
            
            // Captured piece value (we don't have it directly, estimate from position)
            // This is a simplification
        }
        
        // Prefer central moves
        var center_dist = abs(move.to_col - 3.5) + abs(move.to_row - 3.5);
        order_score -= center_dist * 5;
        
        // Prefer pawn pushes in opening/midgame
        if (move.piece_id == "pawn") {
            order_score += 50;
        }
        
        // Prefer piece development (knights and bishops)
        if ((move.piece_id == "knight" || move.piece_id == "bishop") && 
            (move.from_row == 0 || move.from_row == 7)) {
            order_score += 80;
        }
        
        move.order_score = order_score;
    }
    
    // Sort by order_score descending (bubble sort for simplicity)
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
