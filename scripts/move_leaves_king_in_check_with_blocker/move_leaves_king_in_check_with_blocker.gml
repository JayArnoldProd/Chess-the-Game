/// @function move_leaves_king_in_check_with_blocker(piece, target_x, target_y, blocker_x, blocker_y)
/// @desc Like move_leaves_king_in_check but considers an extra blocker position (knocked-back enemy)
/// @param {Id.Instance} piece The piece to move
/// @param {real} target_x Target X position  
/// @param {real} target_y Target Y position
/// @param {real} blocker_x Extra blocker X (enemy knockback destination)
/// @param {real} blocker_y Extra blocker Y (enemy knockback destination)
/// @returns {bool} True if move leaves king in check even WITH the extra blocker
function move_leaves_king_in_check_with_blocker(piece, target_x, target_y, blocker_x, blocker_y) {
    if (!instance_exists(piece)) return true;
    
    var my_color = piece.piece_type;
    var original_x = piece.x;
    var original_y = piece.y;
    var ts = Board_Manager.tile_size;
    
    // Check if there's an enemy chess piece at target (would be captured)
    var captured_piece = noone;
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && id != piece) {
            if (point_distance(x, y, target_x, target_y) < ts * 0.5) {
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
    
    // Temporarily remove the captured piece
    var cap_ox = 0, cap_oy = 0;
    if (captured_piece != noone && instance_exists(captured_piece)) {
        cap_ox = captured_piece.x;
        cap_oy = captured_piece.y;
        captured_piece.x = -9999;
        captured_piece.y = -9999;
    }
    
    // Find our king position
    var king_x = -9999, king_y = -9999;
    with (King_Obj) {
        if (instance_exists(id) && piece_type == my_color) {
            king_x = x;
            king_y = y;
            break;
        }
    }
    
    // Check if any enemy piece attacks the king — WITH extra blocker in ray-casts
    var in_check = false;
    var enemy_color = (my_color == 0) ? 1 : 0;
    
    with (Chess_Piece_Obj) {
        if (!instance_exists(id)) continue;
        if (piece_type != enemy_color) continue;
        if (x < -9000) continue;
        
        var dx = round((king_x - x) / ts);
        var dy = round((king_y - y) / ts);
        var abs_dx = abs(dx);
        var abs_dy = abs(dy);
        
        if (piece_id == "pawn") {
            var pawn_dir = (piece_type == 0) ? -1 : 1;
            if (abs_dx == 1 && dy == pawn_dir) {
                in_check = true;
            }
        }
        else if (piece_id == "knight") {
            if ((abs_dx == 1 && abs_dy == 2) || (abs_dx == 2 && abs_dy == 1)) {
                in_check = true;
            }
        }
        else if (piece_id == "king") {
            if (abs_dx <= 1 && abs_dy <= 1 && (abs_dx + abs_dy > 0)) {
                in_check = true;
            }
        }
        else if (piece_id == "bishop") {
            if (abs_dx == abs_dy && abs_dx > 0) {
                var step_x = sign(dx);
                var step_y = sign(dy);
                var blocked = false;
                for (var dist = 1; dist < abs_dx; dist++) {
                    var cx = x + step_x * dist * ts;
                    var cy = y + step_y * dist * ts;
                    // Check chess pieces
                    var blocker = noone;
                    with (Chess_Piece_Obj) {
                        if (instance_exists(id) && x > -9000 && point_distance(x, y, cx, cy) < ts * 0.4) {
                            blocker = id;
                            break;
                        }
                    }
                    if (blocker != noone) { blocked = true; break; }
                    // Check extra blocker (knocked-back enemy)
                    if (point_distance(blocker_x, blocker_y, cx, cy) < ts * 0.4) {
                        blocked = true; break;
                    }
                }
                if (!blocked) in_check = true;
            }
        }
        else if (piece_id == "rook") {
            if ((dx == 0 || dy == 0) && (abs_dx + abs_dy > 0)) {
                var max_dist = max(abs_dx, abs_dy);
                var step_x = (dx != 0) ? sign(dx) : 0;
                var step_y = (dy != 0) ? sign(dy) : 0;
                var blocked = false;
                for (var dist = 1; dist < max_dist; dist++) {
                    var cx = x + step_x * dist * ts;
                    var cy = y + step_y * dist * ts;
                    var blocker = noone;
                    with (Chess_Piece_Obj) {
                        if (instance_exists(id) && x > -9000 && point_distance(x, y, cx, cy) < ts * 0.4) {
                            blocker = id;
                            break;
                        }
                    }
                    if (blocker != noone) { blocked = true; break; }
                    if (point_distance(blocker_x, blocker_y, cx, cy) < ts * 0.4) {
                        blocked = true; break;
                    }
                }
                if (!blocked) in_check = true;
            }
        }
        else if (piece_id == "queen") {
            var is_diagonal = (abs_dx == abs_dy && abs_dx > 0);
            var is_straight = ((dx == 0 || dy == 0) && (abs_dx + abs_dy > 0));
            if (is_diagonal || is_straight) {
                var max_dist = max(abs_dx, abs_dy);
                var step_x = (dx != 0) ? sign(dx) : 0;
                var step_y = (dy != 0) ? sign(dy) : 0;
                var blocked = false;
                for (var dist = 1; dist < max_dist; dist++) {
                    var cx = x + step_x * dist * ts;
                    var cy = y + step_y * dist * ts;
                    var blocker = noone;
                    with (Chess_Piece_Obj) {
                        if (instance_exists(id) && x > -9000 && point_distance(x, y, cx, cy) < ts * 0.4) {
                            blocker = id;
                            break;
                        }
                    }
                    if (blocker != noone) { blocked = true; break; }
                    if (point_distance(blocker_x, blocker_y, cx, cy) < ts * 0.4) {
                        blocked = true; break;
                    }
                }
                if (!blocked) in_check = true;
            }
        }
        
        if (in_check) break;
    }
    
    // Restore positions
    piece.x = original_x;
    piece.y = original_y;
    if (captured_piece != noone && instance_exists(captured_piece)) {
        captured_piece.x = cap_ox;
        captured_piece.y = cap_oy;
    }
    
    return in_check;
}
