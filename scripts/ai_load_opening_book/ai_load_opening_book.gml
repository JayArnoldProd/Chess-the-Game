/// @function ai_load_opening_book()
/// @description Loads opening book with common chess openings

function ai_load_opening_book() {
    // Clear existing book
    ds_map_clear(opening_book);
    
    // Define some basic opening moves for black
    // Format: "position_hash" -> [array of good moves]
    
    // Starting position responses
    var start_hash = ai_calculate_position_hash_for_opening([]);
    
    // Responses to 1.e4
    var e4_hash = ai_calculate_position_hash_for_opening(["e2e4"]);
    ds_map_add(opening_book, string(e4_hash), ["e7e5", "c7c5", "e7e6", "c7c6"]);
    
    // Responses to 1.d4
    var d4_hash = ai_calculate_position_hash_for_opening(["d2d4"]);
    ds_map_add(opening_book, string(d4_hash), ["d7d5", "g8f6", "f7f5", "e7e6"]);
    
    // Responses to 1.Nf3
    var nf3_hash = ai_calculate_position_hash_for_opening(["g1f3"]);
    ds_map_add(opening_book, string(nf3_hash), ["d7d5", "g8f6", "c7c5"]);
    
    // Responses to 1.c4 (English Opening)
    var c4_hash = ai_calculate_position_hash_for_opening(["c2c4"]);
    ds_map_add(opening_book, string(c4_hash), ["e7e5", "c7c5", "g8f6"]);
    
    // Sicilian Defense responses to 2.Nf3
    var sicilian_nf3_hash = ai_calculate_position_hash_for_opening(["e2e4", "c7c5", "g1f3"]);
    ds_map_add(opening_book, string(sicilian_nf3_hash), ["d7d6", "b8c6", "g8f6"]);
    
    // Italian Game response
    var italian_hash = ai_calculate_position_hash_for_opening(["e2e4", "e7e5", "g1f3", "b8c6", "f1c4"]);
    ds_map_add(opening_book, string(italian_hash), ["f8c5", "g8f6", "f7f5"]);
    
    // Spanish Opening (Ruy Lopez) response
    var spanish_hash = ai_calculate_position_hash_for_opening(["e2e4", "e7e5", "g1f3", "b8c6", "f1b5"]);
    ds_map_add(opening_book, string(spanish_hash), ["a7a6", "g8f6", "f7f5"]);
    
    // Queen's Gambit
    var queens_gambit_hash = ai_calculate_position_hash_for_opening(["d2d4", "d7d5", "c2c4"]);
    ds_map_add(opening_book, string(queens_gambit_hash), ["e7e6", "c7c6", "d5c4"]);
    
    // French Defense
    var french_hash = ai_calculate_position_hash_for_opening(["e2e4", "e7e6", "d2d4"]);
    ds_map_add(opening_book, string(french_hash), ["d7d5", "c7c5"]);
    
    // Caro-Kann Defense
    var caro_kann_hash = ai_calculate_position_hash_for_opening(["e2e4", "c7c6", "d2d4"]);
    ds_map_add(opening_book, string(caro_kann_hash), ["d7d5", "g8f6"]);
    
    // King's Indian Defense setup
    var kings_indian_hash = ai_calculate_position_hash_for_opening(["d2d4", "g8f6", "c2c4", "g7g6"]);
    ds_map_add(opening_book, string(kings_indian_hash), ["f8g7", "d7d6"]);
    
    show_debug_message("Opening book loaded with " + string(ds_map_size(opening_book)) + " positions");
}