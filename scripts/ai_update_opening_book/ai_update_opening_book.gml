/// @function ai_update_opening_book(move)
/// @param {struct} move The move that was played
/// @description Updates opening book with moves from strong play

function ai_update_opening_book(move) {
    var move_count = ai_count_moves_played();
    if (move_count > 16) return; // Only learn openings
    
    // Convert move to string notation for storage
    var move_str = ai_convert_move_to_string(move);
    if (move_str == "") return;
    
    // Get position before the move
    var game_state = ai_save_game_state();
    
    // Undo the move to get the position hash
    Game_Manager.turn = (Game_Manager.turn == 0) ? 1 : 0;
    var position_hash = ai_get_current_game_hash();
    
    ai_restore_game_state(game_state);
    
    var hash_str = string(position_hash);
    
    // Add move to book if position exists, or create new entry
    if (ds_map_exists(opening_book, hash_str)) {
        var existing_moves = opening_book[? hash_str];
        
        // Check if move already exists
        var move_exists = false;
        for (var i = 0; i < array_length(existing_moves); i++) {
            if (existing_moves[i] == move_str) {
                move_exists = true;
                break;
            }
        }
        
        // Add move if it doesn't exist
        if (!move_exists && array_length(existing_moves) < 4) {
            array_push(existing_moves, move_str);
            ds_map_replace(opening_book, hash_str, existing_moves);
        }
    } else {
        ds_map_add(opening_book, hash_str, [move_str]);
    }
}