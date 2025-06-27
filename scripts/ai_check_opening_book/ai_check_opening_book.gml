/// @function ai_check_opening_book()
/// @returns {struct} Opening book move or undefined

function ai_check_opening_book() {
    // Only use opening book in first 10 moves
    var move_count = ai_count_moves_played();
    if (move_count > 20) return undefined; // 10 moves per side
    
    var current_hash = ai_get_current_game_hash();
    var hash_str = string(current_hash);
    
    if (ds_map_exists(opening_book, hash_str)) {
        var book_moves = opening_book[? hash_str];
        
        if (is_array(book_moves) && array_length(book_moves) > 0) {
            // Pick a random move from the book
            var random_move_str = book_moves[irandom(array_length(book_moves) - 1)];
            
            // Convert string move to move structure
            var move = ai_convert_string_to_move(random_move_str);
            if (move != undefined) {
                show_debug_message("Using opening book move: " + random_move_str);
                return move;
            }
        }
    }
    
    return undefined;
}
