/// @function ai_get_board_hash()
/// @returns {real} Hash of current board position

function ai_get_board_hash() {
    var hash = 0;
    var multiplier = 1;
    
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            var piece_hash = 0;
            piece_hash += x * 7;
            piece_hash += y * 11;
            piece_hash += piece_type * 13;
            
            switch (piece_id) {
                case "pawn": piece_hash += 17; break;
                case "knight": piece_hash += 19; break;
                case "bishop": piece_hash += 23; break;
                case "rook": piece_hash += 29; break;
                case "queen": piece_hash += 31; break;
                case "king": piece_hash += 37; break;
            }
            
            hash += piece_hash * multiplier;
            multiplier = (multiplier * 41) mod 2147483647; // Keep it reasonable
        }
    }
    
    hash += Game_Manager.turn * 43;
    hash += Game_Manager.en_passant_target_x * 47;
    hash += Game_Manager.en_passant_target_y * 53;
    
    return abs(hash) mod 2147483647;
}