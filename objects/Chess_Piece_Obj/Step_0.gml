// Chess_Piece_Obj Step:

audio_emitter_position(audio_emitter, x, y, 0);

last_x = x;
last_y = y;

// Only check if not already in an extra–move chain:
if (stepping_chain == 0) {
    var stone = instance_position(x, y, Stepping_Stone_Obj);
    if (stone != noone) {
        // Instead of using the current (stepping stone) position, use the previous frame’s position:
        pre_stepping_x = last_x;
        pre_stepping_y = last_y;
        
        extra_move_pending = true;
        stepping_chain = 2;  // Phase 1 extra move pending
        stepping_stone_instance = stone;
        stone_original_x = stone.x;
        stone_original_y = stone.y;
        show_debug_message("Stepping stone activated! Extra move phase 1 available.");
    }
}

// Only override moves if in Phase 1 of the extra move (stepping_chain == 2)
if (stepping_chain == 2) {
    valid_moves = [];
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx != 0 || dy != 0) {
                array_push(valid_moves, [dx, dy]);
            }
        }
    }
}

if (stepping_chain > 0) {
    // Force the piece to remain the selected piece.
    Game_Manager.selected_piece = self;
}

