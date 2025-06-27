/// @function ai_convert_string_to_move(move_str)
/// @param {string} move_str Move in algebraic notation (e.g., "e2e4")
/// @returns {struct} Move structure or undefined

function ai_convert_string_to_move(move_str) {
    if (string_length(move_str) != 4) return undefined;
    
    var from_file = ord(string_char_at(move_str, 1)) - ord("a");
    var from_rank = real(string_char_at(move_str, 2)) - 1;
    var to_file = ord(string_char_at(move_str, 3)) - ord("a");
    var to_rank = real(string_char_at(move_str, 4)) - 1;
    
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) return undefined;
    
    var from_x = Object_Manager.topleft_x + from_file * Board_Manager.tile_size;
    var from_y = Object_Manager.topleft_y + from_rank * Board_Manager.tile_size;
    var to_x = Object_Manager.topleft_x + to_file * Board_Manager.tile_size;
    var to_y = Object_Manager.topleft_y + to_rank * Board_Manager.tile_size;
    
    // Find the piece at the from position
    var piece = instance_position(from_x, from_y, Chess_Piece_Obj);
    if (piece == noone || piece.piece_type != 1) return undefined; // Must be black piece
    
    // Check if this is a legal move
    var legal_moves = ai_get_legal_moves(1);
    for (var i = 0; i < array_length(legal_moves); i++) {
        var move = legal_moves[i];
        if (point_distance(move.from_x, move.from_y, from_x, from_y) < Board_Manager.tile_size / 2 &&
            point_distance(move.to_x, move.to_y, to_x, to_y) < Board_Manager.tile_size / 2) {
            return move;
        }
    }
    
    return undefined;
}
