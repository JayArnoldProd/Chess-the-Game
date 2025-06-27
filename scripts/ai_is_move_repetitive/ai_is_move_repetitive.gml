/// @function ai_is_move_repetitive(move)
/// @param {struct} move The move to check
/// @returns {bool} Whether this move was recently played

function ai_is_move_repetitive(move) {
    if (!variable_global_exists("ai_last_moves")) return false;
    
    var piece = move.piece;
    var grid_from_x = round(piece.x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_from_y = round(piece.y / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_to_x = round(move.to_x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_to_y = round(move.to_y / Board_Manager.tile_size) * Board_Manager.tile_size;
    
    var move_string = piece.piece_id + ":" + string(grid_from_x) + "," + string(grid_from_y) + "->" + string(grid_to_x) + "," + string(grid_to_y);
    
    // Check if this exact move was made in the last 3 moves
    var recent_moves = min(3, array_length(global.ai_last_moves));
    for (var i = array_length(global.ai_last_moves) - recent_moves; i < array_length(global.ai_last_moves); i++) {
        if (global.ai_last_moves[i] == move_string) {
            return true;
        }
    }
    
    return false;
}