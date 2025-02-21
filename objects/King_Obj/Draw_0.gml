// Inherit the parent event
event_inherited();

// --- Castle Moves Overlay ---
// Only draw castling overlays if this king is selected and castle moves exist.
if (Game_Manager.selected_piece == self && array_length(castle_moves) > 0) {
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
