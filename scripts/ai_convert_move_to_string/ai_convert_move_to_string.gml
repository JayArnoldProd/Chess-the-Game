/// @function ai_convert_move_to_string(move)
/// @param {struct} move Move structure
/// @returns {string} Move in algebraic notation

function ai_convert_move_to_string(move) {
    if (move == undefined) return "";
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) return "";
    
    var from_file = round((move.from_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var from_rank = round((move.from_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    var to_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var to_rank = round((move.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    if (from_file < 0 || from_file > 7 || from_rank < 0 || from_rank > 7 ||
        to_file < 0 || to_file > 7 || to_rank < 0 || to_rank > 7) {
        return "";
    }
    
    var from_file_char = chr(ord("a") + from_file);
    var to_file_char = chr(ord("a") + to_file);
    
    return from_file_char + string(from_rank + 1) + to_file_char + string(to_rank + 1);
}