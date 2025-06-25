/// @function ai_evaluate_king_safety(color)
/// @param {real} color The color to evaluate (0 = white, 1 = black)
/// @returns {real} King safety score

function ai_evaluate_king_safety_safe(color) {
    var safety_score = 0;
    var king = noone;
    
    // Find the king safely
    with (King_Obj) {
        if (instance_exists(id) && piece_type == color) {
            king = id;
            break;
        }
    }
    
    if (king == noone || !instance_exists(king)) return -10000; // King captured or doesn't exist
    
    // Count attacking pieces near king
    var attackers = 0;
    var king_x = king.x;
    var king_y = king.y;
    
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type != color) {
            var distance = point_distance(x, y, king_x, king_y);
            if (distance <= Board_Manager.tile_size * 3) {
                attackers++;
            }
        }
    }
    
    safety_score -= attackers * 20;
    
    // Bonus for castling (king hasn't moved)
    if (instance_exists(king) && !king.has_moved) {
        safety_score += 30;
    }
    
    return safety_score;
}
