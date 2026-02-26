// Inherit the parent event
event_inherited();

// --- King_Obj Step Event ---
// Only check for castling if the king has not moved.
if (!has_moved) {

    // Initialize (or clear) the castle_moves array.
    castle_moves = [];
    
    // FIXED: First check if king is currently in check - can't castle out of check
    var king_in_check = false;
    var my_x = x;
    var my_y = y;
    var my_type = piece_type;
    
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type != my_type) {
            for (var m = 0; m < array_length(valid_moves); m++) {
                var vv = valid_moves[m];
                var attack_x = x + vv[0] * Board_Manager.tile_size;
                var attack_y = y + vv[1] * Board_Manager.tile_size;
                if (point_distance(attack_x, attack_y, my_x, my_y) < Board_Manager.tile_size * 0.5) {
                    king_in_check = true;
                    break;
                }
            }
        }
        if (king_in_check) break;
    }
    
    // If in check, can't castle at all
    if (king_in_check) {
        // castle_moves stays empty
    } else {
        // Find eligible rooks on the same row.
        var numRooks = instance_number(Rook_Obj);
        for (var i = 0; i < numRooks; i++) {
            var rook = instance_find(Rook_Obj, i);
            // Only consider rooks of the same color that haven't moved.
            if (rook.piece_type == piece_type && !rook.has_moved) {

                // Check that the king and rook are on the same row.
                if (abs(y - rook.y) < ((Board_Manager.tile_size) / 2)) {
                    // Determine the horizontal direction from king to rook.
                    var dir = (rook.x > x) ? 1 : -1;

                    // Check that all tiles between the king and rook are empty.
                    var pathClear = true;
                    var start_ = min(x, rook.x) + Board_Manager.tile_size;
                    var end_   = max(x, rook.x) - Board_Manager.tile_size;
                    for (var xx = start_; xx <= end_; xx += Board_Manager.tile_size) {
                        if (instance_position(xx, y, Chess_Piece_Obj) != noone) {
                            pathClear = false;
                            break;
                        }
                    }

                    if (pathClear) {
                        // FIXED: Check that king doesn't pass through or land on attacked squares
                        // King moves 2 squares: check both the intermediate and destination squares
                        var path_attacked = false;
                        
                        for (var step = 1; step <= 2; step++) {
                            var check_x = x + step * dir * Board_Manager.tile_size;
                            
                            with (Chess_Piece_Obj) {
                                if (instance_exists(id) && piece_type != my_type) {
                                    for (var m = 0; m < array_length(valid_moves); m++) {
                                        var vv = valid_moves[m];
                                        var attack_x = x + vv[0] * Board_Manager.tile_size;
                                        var attack_y = y + vv[1] * Board_Manager.tile_size;
                                        if (point_distance(attack_x, attack_y, check_x, my_y) < Board_Manager.tile_size * 0.5) {
                                            path_attacked = true;
                                            break;
                                        }
                                    }
                                }
                                if (path_attacked) break;
                            }
                            if (path_attacked) break;
                        }
                        
                        if (!path_attacked) {
                            // Castle is allowed.
                            // For standard chess, the king moves two spaces toward the rook.
                            var castle_dx = 2 * dir;
                            var target_x = x + castle_dx * Board_Manager.tile_size;
                            var target_y = y;

                            // Save the move as an array entry, tagging it as a castle move.
                            // Format: [move_dx, move_dy, "castle", rook_id]
                            array_push(castle_moves, [castle_dx, 0, "castle", rook.id]);
                        }
                    }
                }
            }
        }
    }
}