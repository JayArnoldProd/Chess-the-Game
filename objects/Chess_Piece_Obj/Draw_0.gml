// Chess_Piece_Obj Draw
tile_size = Board_Manager.tile_size;
image_index = piece_type;
draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 1);

if (Game_Manager.hovered_piece == self) {
    draw_sprite_ext(sprite_index, sprite_get_number(sprite_index)-1, x, y, 1, 1, 0, c_white, 1);
}

if (Game_Manager.selected_piece == self) {
    draw_sprite_ext(sprite_index, sprite_get_number(sprite_index)-1, x, y, 1, 1, 0, c_green, 1);
    
    // Reset all tiles' valid_move status
    with (Tile_Obj) {
        valid_move = false;
    }
    
    // Draw valid moves
    for (var i = 0; i < array_length(valid_moves); i++) {
        check_x = x + valid_moves[i][0] * tile_size;
        check_y = y + valid_moves[i][1] * tile_size;
        
        if (instance_place(check_x, check_y, Tile_Obj)) {
            var piece = instance_place(check_x, check_y, Chess_Piece_Obj);
            
            if (!piece) {
                // Empty square - valid move
                draw_sprite_ext(sprite_index, image_index, check_x, check_y, 1, 1, 0, c_green, .5);
                with (Tile_Obj) {
                    if (x == other.check_x && y == other.check_y) {
                        valid_move = true;
                    }
                }
            } else {
                // Blocked square - show as red
                draw_sprite_ext(sprite_index, image_index, check_x, check_y, 1, 1, 0, c_red, .5);
                // Don't set valid_move for blocked squares
            }
        }
    }
}