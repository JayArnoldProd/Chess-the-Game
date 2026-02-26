/// @function ai_get_piece_value(piece_id)
/// @param {string} piece_id The piece type
/// @returns {real} The piece value
function ai_get_piece_value(piece_id) {
    switch (piece_id) {
        case "pawn": return 100;
        case "knight": return 320;
        case "bishop": return 330;
        case "rook": return 500;
        case "queen": return 900;
        case "king": return 20000;
        default: return 100;
    }
}