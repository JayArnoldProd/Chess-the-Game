/// @function ai_count_moves_played()
/// @returns {real} Number of moves played in the game

function ai_count_moves_played() {
    // This is a simple approximation
    // You could track this more accurately by storing move history
    var piece_count = 0;
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) piece_count++;
    }
    
    // Estimate moves based on missing pieces (very rough)
    var starting_pieces = 32;
    var captured_pieces = starting_pieces - piece_count;
    return captured_pieces + irandom(10); // Add some randomness
}