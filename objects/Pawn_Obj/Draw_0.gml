// -------------------------
// Pawn_Obj Draw Event
// -------------------------
// Inherit standard drawing.
event_inherited();

// --- En Passant Overlay for Pawn ---
// Only if this pawn is selected.
if (Game_Manager.selected_piece == self) {
    for (var i = 0; i < array_length(valid_moves); i++) {
        var move = valid_moves[i];
        if (array_length(move) >= 3 && move[2] == "en_passant") {
            var target_x = x + move[0] * Board_Manager.tile_size;
            var target_y = y + move[1] * Board_Manager.tile_size;
            // Draw a blue overlay (semi-transparent) at the en passant target.
            draw_sprite_ext(sprite_index, 0, target_x, target_y, 1, 1, 0, c_blue, 0.5);
            
            // Optionally, mark the tile as valid.
            var tileInst = instance_place(target_x, target_y, Tile_Obj);
            if (tileInst != noone) {
                tileInst.valid_move = true;
            }
        }
    }
}