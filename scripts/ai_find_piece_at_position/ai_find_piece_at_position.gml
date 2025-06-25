/// @function ai_find_piece_at_position(x_pos, y_pos, piece_type, piece_id)
/// @param {real} x_pos X position to check
/// @param {real} y_pos Y position to check  
/// @param {real} piece_type Type of piece to find
/// @param {string} piece_id ID of piece to find
/// @returns {id} The piece instance or noone

function ai_find_piece_at_position(x_pos, y_pos, piece_type, piece_id) {
    with (Chess_Piece_Obj) {
        if (point_distance(x, y, x_pos, y_pos) < Board_Manager.tile_size / 2 &&
            piece_type == piece_type && piece_id == piece_id) {
            return id;
        }
    }
    return noone;
}

