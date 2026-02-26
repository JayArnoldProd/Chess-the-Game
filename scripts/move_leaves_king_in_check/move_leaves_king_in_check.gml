/// @function move_leaves_king_in_check(piece, target_x, target_y)
/// @desc Simulates a move and checks if the player's king would be in check after
/// @param {id} piece The piece to move
/// @param {real} target_x Target X position
/// @param {real} target_y Target Y position
/// @returns {bool} True if move leaves king in check (illegal move)
function move_leaves_king_in_check(piece, target_x, target_y) {
    if (!instance_exists(piece)) return true;
    
    // Special case: Allow KING to step onto a stepping stone (phase 1) even if
    // the intermediate landing square would be "in check". We'll validate on phase 2.
    if (piece.piece_id == "king" && piece.stepping_chain == 0) {
        var _stone = instance_position(target_x + Board_Manager.tile_size/4, target_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
        if (!_stone) _stone = instance_position(target_x, target_y, Stepping_Stone_Obj);
        if (_stone) {
            return false; // allow stepping onto stone; final check happens on phase 2
        }
    }
    
    var my_color = piece.piece_type;
    var original_x = piece.x;
    var original_y = piece.y;
    
    // Check if there's an enemy piece at target (would be captured)
    var captured_piece = noone;
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && id != piece) {
            if (point_distance(x, y, target_x, target_y) < Board_Manager.tile_size * 0.5) {
                if (piece_type != my_color) {
                    captured_piece = id;
                }
                break;
            }
        }
    }
    
    // Simulate the move
    piece.x = target_x;
    piece.y = target_y;
    
    // Temporarily remove the captured piece from consideration
    var captured_original_x = 0;
    var captured_original_y = 0;
    if (captured_piece != noone && instance_exists(captured_piece)) {
        captured_original_x = captured_piece.x;
        captured_original_y = captured_piece.y;
        captured_piece.x = -9999;
        captured_piece.y = -9999;
    }
    
    // Find our king
    var king = noone;
    with (King_Obj) {
        if (instance_exists(id) && piece_type == my_color) {
            king = id;
            break;
        }
    }
    
    var king_x = (king != noone) ? king.x : -9999;
    var king_y = (king != noone) ? king.y : -9999;
    
    // If the moving piece IS the king, update position
    if (piece.piece_id == "king") {
        king_x = target_x;
        king_y = target_y;
    }
    
    // Check if any enemy piece can attack the king position
    var in_check = false;
    var enemy_color = (my_color == 0) ? 1 : 0;
    
    with (Chess_Piece_Obj) {
        if (!instance_exists(id)) continue;
        if (piece_type != enemy_color) continue;
        if (x < -9000) continue; // Skip "removed" pieces
        
        // Recalculate valid moves for sliding pieces based on new position
        // For simplicity, use current valid_moves (may miss some edge cases)
        for (var i = 0; i < array_length(valid_moves); i++) {
            var move = valid_moves[i];
            var attack_x = x + move[0] * Board_Manager.tile_size;
            var attack_y = y + move[1] * Board_Manager.tile_size;
            
            if (point_distance(attack_x, attack_y, king_x, king_y) < Board_Manager.tile_size * 0.5) {
                in_check = true;
                break;
            }
        }
        if (in_check) break;
    }
    
    // Restore positions
    piece.x = original_x;
    piece.y = original_y;
    
    if (captured_piece != noone && instance_exists(captured_piece)) {
        captured_piece.x = captured_original_x;
        captured_piece.y = captured_original_y;
    }
    
    return in_check;
}
