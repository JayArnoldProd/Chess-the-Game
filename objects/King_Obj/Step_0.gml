// Inherit the parent event
event_inherited();

// --- King_Obj Step Event ---
// Only check for castling if the king has not moved.
if (!has_moved) {

    // Initialize (or clear) the castle_moves array.
    castle_moves = [];

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