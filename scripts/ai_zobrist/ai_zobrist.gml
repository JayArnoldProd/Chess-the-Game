/// @function ai_zobrist_init()
/// @description Initializes Zobrist hash tables for transposition table
function ai_zobrist_init() {
    // Create random 64-bit keys for each piece on each square
    // Using two 32-bit values since GML doesn't have native 64-bit
    global.zobrist_pieces = array_create(64 * 12 * 2); // 64 squares, 12 piece types (6 pieces * 2 colors), 2 parts
    global.zobrist_side = [irandom(2147483647), irandom(2147483647)]; // Side to move
    global.zobrist_castling = array_create(16 * 2); // 16 castling states
    global.zobrist_enpassant = array_create(8 * 2); // 8 files for en passant
    
    // Initialize piece keys
    randomize();
    var seed = 12345; // Consistent seed for reproducibility
    random_set_seed(seed);
    
    for (var i = 0; i < 64 * 12 * 2; i++) {
        global.zobrist_pieces[i] = irandom(2147483647);
    }
    
    for (var i = 0; i < 16 * 2; i++) {
        global.zobrist_castling[i] = irandom(2147483647);
    }
    
    for (var i = 0; i < 8 * 2; i++) {
        global.zobrist_enpassant[i] = irandom(2147483647);
    }
    
    // Reset random seed
    randomize();
    
    global.zobrist_initialized = true;
}

/// @function ai_get_piece_index(piece_id, piece_type)
/// @description Returns index 0-11 for piece type
function ai_get_piece_index(piece_id, piece_type) {
    var base = 0;
    switch (piece_id) {
        case "pawn": base = 0; break;
        case "knight": base = 1; break;
        case "bishop": base = 2; break;
        case "rook": base = 3; break;
        case "queen": base = 4; break;
        case "king": base = 5; break;
        default: return 0;
    }
    return base + (piece_type * 6);
}

/// @function ai_compute_hash(board)
/// @description Computes Zobrist hash for a board position
/// @returns {array} [hash_lo, hash_hi] two 32-bit values
function ai_compute_hash(board) {
    if (!variable_global_exists("zobrist_initialized") || !global.zobrist_initialized) {
        ai_zobrist_init();
    }
    
    var hash_lo = 0;
    var hash_hi = 0;
    
    for (var row = 0; row < 8; row++) {
        var board_row = board[row];
        for (var col = 0; col < 8; col++) {
            var piece = board_row[col];
            if (piece != noone) {
                var sq = row * 8 + col;
                var piece_idx = ai_get_piece_index(piece.piece_id, piece.piece_type);
                var key_idx = (sq * 12 + piece_idx) * 2;
                hash_lo ^= global.zobrist_pieces[key_idx];
                hash_hi ^= global.zobrist_pieces[key_idx + 1];
            }
        }
    }
    
    return [hash_lo, hash_hi];
}

/// @function ai_update_hash(hash, from_sq, to_sq, piece, captured)
/// @description Incrementally updates hash after a move
function ai_update_hash(hash, from_sq, to_sq, piece, captured) {
    var hash_lo = hash[0];
    var hash_hi = hash[1];
    var piece_idx = ai_get_piece_index(piece.piece_id, piece.piece_type);
    
    // Remove piece from source
    var key_idx = (from_sq * 12 + piece_idx) * 2;
    hash_lo ^= global.zobrist_pieces[key_idx];
    hash_hi ^= global.zobrist_pieces[key_idx + 1];
    
    // Add piece to destination
    key_idx = (to_sq * 12 + piece_idx) * 2;
    hash_lo ^= global.zobrist_pieces[key_idx];
    hash_hi ^= global.zobrist_pieces[key_idx + 1];
    
    // Remove captured piece if any
    if (captured != noone) {
        var cap_idx = ai_get_piece_index(captured.piece_id, captured.piece_type);
        key_idx = (to_sq * 12 + cap_idx) * 2;
        hash_lo ^= global.zobrist_pieces[key_idx];
        hash_hi ^= global.zobrist_pieces[key_idx + 1];
    }
    
    // Toggle side to move
    hash_lo ^= global.zobrist_side[0];
    hash_hi ^= global.zobrist_side[1];
    
    return [hash_lo, hash_hi];
}
