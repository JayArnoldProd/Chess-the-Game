// -------------------------
// Chess_Piece_Obj Draw Event
// -------------------------

// Set the piece's depth based on its selection status.
if (Game_Manager.selected_piece == self) {
    depth = original_depth - 1;  // Lower the depth so that overlays appear on top.
} else {
    depth = original_depth;      // Restore the original depth.
}

// Set tile size and image index.
tile_size = Board_Manager.tile_size;
image_index = piece_type;

// Draw the base sprite.
draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 1);

// Draw the hovered overlay if this piece is hovered.
if (Game_Manager.hovered_piece == self) {
    draw_sprite_ext(sprite_index, sprite_get_number(sprite_index) - 1, x, y, 1, 1, 0, c_white, 1);
}

// Only if this piece is selected AND not animating, draw the valid–move overlays.
if (Game_Manager.selected_piece == self && !is_moving) {
    // Draw a green overlay on the piece.
    draw_sprite_ext(sprite_index, sprite_get_number(sprite_index) - 1, x, y, 1, 1, 0, c_green, 1);
    
    // Reset valid_move flag for all tiles.
    with (Tile_Obj) {
        valid_move = false;
    }
    
    // Loop through the valid_moves array to draw overlays on the corresponding tiles.
    for (var i = 0; i < array_length(valid_moves); i++) {
        var check_x = x + valid_moves[i][0] * tile_size;
        var check_y = y + valid_moves[i][1] * tile_size;
        
        // Only process if there is a tile at this location.
        if (instance_place(check_x, check_y, Tile_Obj)) {
            // When in stepping stone Phase 1, only allow moves on empty tiles.
            if (stepping_chain == 2) {
                if (instance_place(check_x, check_y, Chess_Piece_Obj) == noone) {
                    draw_sprite_ext(sprite_index, 0, check_x, check_y, 1, 1, 0, c_green, 0.5);
                    // Set the valid_move flag on that tile.
                    var tileInst = instance_place(check_x, check_y, Tile_Obj);
                    if (tileInst != noone) {
                        tileInst.valid_move = true;
                    }
                }
                else {
                    // Occupied: draw a red overlay.
                    draw_sprite_ext(sprite_index, 0, check_x, check_y, 1, 1, 0, c_red, 0.5);
                }
            }
            else { // Normal move drawing.
                var occ = instance_place(check_x, check_y, Chess_Piece_Obj);
                
                // CHECK ENFORCEMENT: For player pieces, check if this move would leave king in check
                // EXCEPTION: Stepping stone tiles allow the king to land on threatened squares
                // because the stepping stone grants extra moves to escape to safety.
                // The final move (phase 2) still enforces check in Tile_Obj/Mouse_7.gml.
                var move_is_legal = true;
                if (piece_type == 0) { // Player piece
                    var target_has_stepping_stone = instance_position(check_x, check_y, Stepping_Stone_Obj) != noone;
                    if (target_has_stepping_stone) {
                        move_is_legal = true; // Stepping stones grant extra moves to escape
                    } else {
                        move_is_legal = !move_leaves_king_in_check(self, check_x, check_y);
                    }
                }
                
                if (occ == noone) {
                    // Empty square
                    if (move_is_legal) {
                        // Legal move: draw green overlay
                        draw_sprite_ext(sprite_index, 0, check_x, check_y, 1, 1, 0, c_green, 0.5);
                        var tileInst = instance_place(check_x, check_y, Tile_Obj);
                        if (tileInst != noone) {
                            tileInst.valid_move = true;
                        }
                    }
                    // If illegal (would leave king in check), don't draw anything - square not available
                }
                else {
                    // There is a piece present.
                    if ((piece_type == 0 && occ.piece_type == 0) ||
                        (piece_type == 1 && occ.piece_type == 1)) {
                        // Same color: blocked square.
                        draw_sprite_ext(sprite_index, 0, check_x, check_y, 1, 1, 0, c_red, 0.5);
                    }
                    else {
                        // Opponent piece: capture allowed if legal
                        if (move_is_legal) {
                            draw_sprite_ext(sprite_index, 0, check_x, check_y, 1, 1, 0, c_green, 0.5);
                            var tileInst = instance_place(check_x, check_y, Tile_Obj);
                            if (tileInst != noone) {
                                tileInst.valid_move = true;
                            }
                        }
                        // If illegal capture, don't mark as valid
                    }
                }
            }
        }
    }
}
