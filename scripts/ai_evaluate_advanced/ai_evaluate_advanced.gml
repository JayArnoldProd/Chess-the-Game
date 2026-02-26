/// @function ai_evaluate_advanced(board)
/// @description Advanced position evaluation with full chess knowledge
/// @returns {real} Score in centipawns (positive = black/AI advantage)
function ai_evaluate_advanced(board) {
    // Cache piece-square tables in local vars for speed
    static pst_init = false;
    static pst_pawn = undefined;
    static pst_knight = undefined;
    static pst_bishop = undefined;
    static pst_rook = undefined;
    static pst_queen = undefined;
    static pst_king_mg = undefined;
    static pst_king_eg = undefined;
    
    if (!pst_init) {
        ai_init_piece_square_tables();
        pst_pawn = global.pst_pawn;
        pst_knight = global.pst_knight;
        pst_bishop = global.pst_bishop;
        pst_rook = global.pst_rook;
        pst_queen = global.pst_queen;
        pst_king_mg = global.pst_king_mg;
        pst_king_eg = global.pst_king_eg;
        pst_init = true;
    }
    
    var score_mg = 0; // Middlegame score
    var score_eg = 0; // Endgame score
    var phase = 0;    // Game phase (0=endgame, 24=opening)
    
    // Material values (middlegame / endgame)
    var val_pawn_mg = 82, val_pawn_eg = 94;
    var val_knight_mg = 337, val_knight_eg = 281;
    var val_bishop_mg = 365, val_bishop_eg = 297;
    var val_rook_mg = 477, val_rook_eg = 512;
    var val_queen_mg = 1025, val_queen_eg = 936;
    
    // Phase weights
    var phase_knight = 1;
    var phase_bishop = 1;
    var phase_rook = 2;
    var phase_queen = 4;
    
    // Piece lists for faster evaluation
    var white_pawns = [];
    var black_pawns = [];
    var white_king_sq = -1;
    var black_king_sq = -1;
    var white_bishops = 0;
    var black_bishops = 0;
    
    // First pass: material and PST, collect piece info
    for (var row = 0; row < 8; row++) {
        var board_row = board[row];
        for (var col = 0; col < 8; col++) {
            var piece = board_row[col];
            if (piece == noone) continue;
            
            var sq = row * 8 + col;
            var is_white = (piece.piece_type == 0);
            var pst_row = is_white ? row : (7 - row);
            var pst_sq = pst_row * 8 + col;
            var _sign = is_white ? -1 : 1; // Positive for black (AI)
            
            switch (piece.piece_id) {
                case "pawn":
                    score_mg += _sign * (val_pawn_mg + pst_pawn[pst_sq]);
                    score_eg += _sign * (val_pawn_eg + pst_pawn[pst_sq]);
                    if (is_white) array_push(white_pawns, sq);
                    else array_push(black_pawns, sq);
                    break;
                    
                case "knight":
                    score_mg += _sign * (val_knight_mg + pst_knight[pst_sq]);
                    score_eg += _sign * (val_knight_eg + pst_knight[pst_sq]);
                    phase += phase_knight;
                    break;
                    
                case "bishop":
                    score_mg += _sign * (val_bishop_mg + pst_bishop[pst_sq]);
                    score_eg += _sign * (val_bishop_eg + pst_bishop[pst_sq]);
                    phase += phase_bishop;
                    if (is_white) white_bishops++;
                    else black_bishops++;
                    break;
                    
                case "rook":
                    score_mg += _sign * (val_rook_mg + pst_rook[pst_sq]);
                    score_eg += _sign * (val_rook_eg + pst_rook[pst_sq]);
                    phase += phase_rook;
                    break;
                    
                case "queen":
                    score_mg += _sign * (val_queen_mg + pst_queen[pst_sq]);
                    score_eg += _sign * (val_queen_eg + pst_queen[pst_sq]);
                    phase += phase_queen;
                    break;
                    
                case "king":
                    score_mg += _sign * pst_king_mg[pst_sq];
                    score_eg += _sign * pst_king_eg[pst_sq];
                    if (is_white) white_king_sq = sq;
                    else black_king_sq = sq;
                    break;
            }
        }
    }
    
    // Bishop pair bonus
    if (white_bishops >= 2) {
        score_mg -= 30;
        score_eg -= 50;
    }
    if (black_bishops >= 2) {
        score_mg += 30;
        score_eg += 50;
    }
    
    // Pawn structure evaluation
    var pawn_eval = ai_evaluate_pawns(white_pawns, black_pawns);
    score_mg += pawn_eval[0];
    score_eg += pawn_eval[1];
    
    // King safety (only in middlegame)
    if (phase > 8) {
        var white_king_safety = ai_evaluate_king_safety_fast(board, white_king_sq, 0, black_pawns);
        var black_king_safety = ai_evaluate_king_safety_fast(board, black_king_sq, 1, white_pawns);
        score_mg += black_king_safety - white_king_safety;
    }
    
    // Mobility (simplified for speed)
    var mobility = ai_evaluate_mobility_fast(board);
    score_mg += mobility;
    score_eg += mobility * 0.5;
    
    // Interpolate between middlegame and endgame scores
    phase = min(phase, 24);
    var mg_weight = phase;
    var eg_weight = 24 - phase;
    
    return floor((score_mg * mg_weight + score_eg * eg_weight) / 24);
}

/// @function ai_init_piece_square_tables()
/// @description Initializes piece-square tables (called once)
function ai_init_piece_square_tables() {
    // Pawn PST (from white's perspective, row 0 = rank 8)
    global.pst_pawn = [
        0,   0,   0,   0,   0,   0,   0,   0,
        98, 134,  61,  95,  68, 126,  34, -11,
        -6,   7,  26,  31,  65,  56,  25, -20,
       -14,  13,   6,  21,  23,  12,  17, -23,
       -27,  -2,  -5,  12,  17,   6,  10, -25,
       -26,  -4,  -4, -10,   3,   3,  33, -12,
       -35,  -1, -20, -23, -15,  24,  38, -22,
         0,   0,   0,   0,   0,   0,   0,   0
    ];
    
    global.pst_knight = [
       -167, -89, -34, -49,  61, -97, -15, -107,
        -73, -41,  72,  36,  23,  62,   7,  -17,
        -47,  60,  37,  65,  84, 129,  73,   44,
         -9,  17,  19,  53,  37,  69,  18,   22,
        -13,   4,  16,  13,  28,  19,  21,   -8,
        -23,  -9,  12,  10,  19,  17,  25,  -16,
        -29, -53, -12,  -3,  -1,  18, -14,  -19,
       -105, -21, -58, -33, -17, -28, -19,  -23
    ];
    
    global.pst_bishop = [
        -29,   4, -82, -37, -25, -42,   7,  -8,
        -26,  16, -18, -13,  30,  59,  18, -47,
        -16,  37,  43,  40,  35,  50,  37,  -2,
         -4,   5,  19,  50,  37,  37,   7,  -2,
         -6,  13,  13,  26,  34,  12,  10,   4,
          0,  15,  15,  15,  14,  27,  18,  10,
          4,  15,  16,   0,   7,  21,  33,   1,
        -33,  -3, -14, -21, -13, -12, -39, -21
    ];
    
    global.pst_rook = [
         32,  42,  32,  51,  63,   9,  31,  43,
         27,  32,  58,  62,  80,  67,  26,  44,
         -5,  19,  26,  36,  17,  45,  61,  16,
        -24, -11,   7,  26,  24,  35,  -8, -20,
        -36, -26, -12,  -1,   9,  -7,   6, -23,
        -45, -25, -16, -17,   3,   0,  -5, -33,
        -44, -16, -20,  -9,  -1,  11,  -6, -71,
        -19, -13,   1,  17,  16,   7, -37, -26
    ];
    
    global.pst_queen = [
        -28,   0,  29,  12,  59,  44,  43,  45,
        -24, -39,  -5,   1, -16,  57,  28,  54,
        -13, -17,   7,   8,  29,  56,  47,  57,
        -27, -27, -16, -16,  -1,  17,  -2,   1,
         -9, -26,  -9, -10,  -2,  -4,   3,  -3,
        -14,   2, -11,  -2,  -5,   2,  14,   5,
        -35,  -8,  11,   2,   8,  15,  -3,   1,
         -1, -18,  -9,  10, -15, -25, -31, -50
    ];
    
    global.pst_king_mg = [
        -65,  23,  16, -15, -56, -34,   2,  13,
         29,  -1, -20,  -7,  -8,  -4, -38, -29,
         -9,  24,   2, -16, -20,   6,  22, -22,
        -17, -20, -12, -27, -30, -25, -14, -36,
        -49,  -1, -27, -39, -46, -44, -33, -51,
        -14, -14, -22, -46, -44, -30, -15, -27,
          1,   7,  -8, -64, -43, -16,   9,   8,
        -15,  36,  12, -54,   8, -28,  24,  14
    ];
    
    global.pst_king_eg = [
        -74, -35, -18, -18, -11,  15,   4, -17,
        -12,  17,  14,  17,  17,  38,  23,  11,
         10,  17,  23,  15,  20,  45,  44,  13,
         -8,  22,  24,  27,  26,  33,  26,   3,
        -18,  -4,  21,  24,  27,  23,   9, -11,
        -19,  -3,  11,  21,  23,  16,   7,  -9,
        -27, -11,   4,  13,  14,   4,  -5, -17,
        -53, -34, -21, -11, -28, -14, -24, -43
    ];
}

/// @function ai_evaluate_pawns(white_pawns, black_pawns)
/// @description Evaluates pawn structure
/// @returns {array} [mg_score, eg_score]
function ai_evaluate_pawns(white_pawns, black_pawns) {
    var score_mg = 0;
    var score_eg = 0;
    
    // Build pawn file arrays
    var white_files = array_create(8, 0);
    var black_files = array_create(8, 0);
    
    var wp_count = array_length(white_pawns);
    var bp_count = array_length(black_pawns);
    
    for (var i = 0; i < wp_count; i++) {
        white_files[white_pawns[i] % 8]++;
    }
    for (var i = 0; i < bp_count; i++) {
        black_files[black_pawns[i] % 8]++;
    }
    
    // Doubled pawns penalty
    for (var f = 0; f < 8; f++) {
        if (white_files[f] > 1) {
            score_mg += 10 * (white_files[f] - 1); // Penalty for white = bonus for black
            score_eg += 20 * (white_files[f] - 1);
        }
        if (black_files[f] > 1) {
            score_mg -= 10 * (black_files[f] - 1);
            score_eg -= 20 * (black_files[f] - 1);
        }
    }
    
    // Isolated pawns penalty
    for (var f = 0; f < 8; f++) {
        var left = (f > 0) ? white_files[f-1] : 0;
        var right = (f < 7) ? white_files[f+1] : 0;
        if (white_files[f] > 0 && left == 0 && right == 0) {
            score_mg += 20;
            score_eg += 10;
        }
        
        left = (f > 0) ? black_files[f-1] : 0;
        right = (f < 7) ? black_files[f+1] : 0;
        if (black_files[f] > 0 && left == 0 && right == 0) {
            score_mg -= 20;
            score_eg -= 10;
        }
    }
    
    // Passed pawns bonus (simplified)
    for (var i = 0; i < wp_count; i++) {
        var sq = white_pawns[i];
        var file = sq % 8;
        var rank = floor(sq / 8);
        var passed = true;
        
        // Check if any black pawn can block or capture
        for (var r = rank - 1; r >= 0; r--) {
            for (var df = -1; df <= 1; df++) {
                var check_file = file + df;
                if (check_file >= 0 && check_file < 8) {
                    var check_sq = r * 8 + check_file;
                    for (var j = 0; j < bp_count; j++) {
                        if (black_pawns[j] == check_sq) {
                            passed = false;
                            break;
                        }
                    }
                }
                if (!passed) break;
            }
            if (!passed) break;
        }
        
        if (passed) {
            var bonus = (7 - rank) * 10; // More advanced = bigger bonus
            score_mg -= bonus;
            score_eg -= bonus * 2;
        }
    }
    
    // Same for black passed pawns
    for (var i = 0; i < bp_count; i++) {
        var sq = black_pawns[i];
        var file = sq % 8;
        var rank = floor(sq / 8);
        var passed = true;
        
        for (var r = rank + 1; r < 8; r++) {
            for (var df = -1; df <= 1; df++) {
                var check_file = file + df;
                if (check_file >= 0 && check_file < 8) {
                    var check_sq = r * 8 + check_file;
                    for (var j = 0; j < wp_count; j++) {
                        if (white_pawns[j] == check_sq) {
                            passed = false;
                            break;
                        }
                    }
                }
                if (!passed) break;
            }
            if (!passed) break;
        }
        
        if (passed) {
            var bonus = rank * 10;
            score_mg += bonus;
            score_eg += bonus * 2;
        }
    }
    
    return [score_mg, score_eg];
}

/// @function ai_evaluate_king_safety_fast(board, king_sq, color, enemy_pawns)
/// @description Fast king safety evaluation
function ai_evaluate_king_safety_fast(board, king_sq, color, enemy_pawns) {
    if (king_sq < 0) return 0;
    
    var safety = 0;
    var king_file = king_sq % 8;
    var king_rank = floor(king_sq / 8);
    
    // Penalize open files near king
    for (var df = -1; df <= 1; df++) {
        var f = king_file + df;
        if (f < 0 || f >= 8) continue;
        
        var has_friendly_pawn = false;
        var shield_rank = (color == 0) ? king_rank - 1 : king_rank + 1;
        
        if (shield_rank >= 0 && shield_rank < 8) {
            var shield_sq = shield_rank * 8 + f;
            var piece = board[shield_rank][f];
            if (piece != noone && piece.piece_id == "pawn" && piece.piece_type == color) {
                has_friendly_pawn = true;
            }
        }
        
        if (!has_friendly_pawn) {
            safety -= 15; // Open file near king
        }
    }
    
    // Bonus for castled king position
    if (color == 0) { // White
        if (king_file >= 5 && king_rank == 7) safety += 20; // Kingside castle position
        else if (king_file <= 2 && king_rank == 7) safety += 20; // Queenside
    } else { // Black
        if (king_file >= 5 && king_rank == 0) safety += 20;
        else if (king_file <= 2 && king_rank == 0) safety += 20;
    }
    
    return safety;
}

/// @function ai_evaluate_mobility_fast(board)
/// @description Fast mobility evaluation (simplified)
function ai_evaluate_mobility_fast(board) {
    var white_mobility = 0;
    var black_mobility = 0;
    
    // Only count knight and bishop mobility for speed
    for (var row = 0; row < 8; row++) {
        var board_row = board[row];
        for (var col = 0; col < 8; col++) {
            var piece = board_row[col];
            if (piece == noone) continue;
            
            var is_white = (piece.piece_type == 0);
            var mob = 0;
            
            if (piece.piece_id == "knight") {
                // Count knight moves
                static knight_moves = [[1,-2],[2,-1],[2,1],[1,2],[-1,2],[-2,1],[-2,-1],[-1,-2]];
                for (var i = 0; i < 8; i++) {
                    var nr = row + knight_moves[i][1];
                    var nc = col + knight_moves[i][0];
                    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
                        var target = board[nr][nc];
                        if (target == noone || target.piece_type != piece.piece_type) {
                            mob++;
                        }
                    }
                }
            } else if (piece.piece_id == "bishop") {
                // Count bishop moves (simplified - just immediate diagonals)
                static bishop_dirs = [[1,-1],[1,1],[-1,1],[-1,-1]];
                for (var d = 0; d < 4; d++) {
                    var dr = bishop_dirs[d][1];
                    var dc = bishop_dirs[d][0];
                    for (var dist = 1; dist <= 7; dist++) {
                        var nr = row + dr * dist;
                        var nc = col + dc * dist;
                        if (nr < 0 || nr >= 8 || nc < 0 || nc >= 8) break;
                        var target = board[nr][nc];
                        if (target == noone) {
                            mob++;
                        } else {
                            if (target.piece_type != piece.piece_type) mob++;
                            break;
                        }
                    }
                }
            }
            
            if (is_white) white_mobility += mob;
            else black_mobility += mob;
        }
    }
    
    return (black_mobility - white_mobility) * 4; // 4 centipawns per square
}
