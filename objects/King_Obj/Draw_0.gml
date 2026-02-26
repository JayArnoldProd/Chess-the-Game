// King_Obj Draw

// Inherit the parent event
event_inherited();

// --- CHECK INDICATOR ---
// Draw a red tint when this king is in check
var am_in_check = ai_is_king_in_check_simple(piece_type);
if (am_in_check) {
    // Draw a pulsing red overlay on the king to indicate check
    var pulse = 0.5 + 0.3 * sin(current_time / 200); // Pulse effect
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_red, pulse);
}

// --- Castle Moves Overlay ---

// Only draw castling overlays if this king is selected and castle moves exist.
if (Game_Manager.selected_piece == self && array_length(castle_moves) > 0 && !is_moving) {
    for (var i = 0; i < array_length(castle_moves); i++) {
        var move = castle_moves[i];  // Format: [castle_dx, 0, "castle", rook_id]
        // Calculate the target position for castling.
        var castle_target_x = x + move[0] * Board_Manager.tile_size;
        var castle_target_y = y;  // same row as king

        // Draw a blue-tinted overlay (semi-transparent) at the castle target.
        // (You can adjust the subimage index if needed.)
        draw_sprite_ext(sprite_index, 0, castle_target_x, castle_target_y, 1, 1, 0, c_blue, 0.5);

        // Optionally, mark the tile as valid.
        var tileInst = instance_place(castle_target_x, castle_target_y, Tile_Obj);
        if (tileInst != noone) {
            tileInst.valid_move = true;
        }
    }
}
