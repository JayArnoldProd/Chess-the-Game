//Bishop_Obj Step
//set size
if instance_exists(Board_Manager) {
	tile_size = Board_Manager.tile_size;
}

valid_moves = [];
if (Game_Manager.selected_piece == self) {
    // Check each direction
    for (var dir = 0; dir < array_length(direction_moves); dir++) {
        var dx = direction_moves[dir][0];
        var dy = direction_moves[dir][1];
        
        // Check each distance in this direction
        for (var dist = 1; dist <= max_distance; dist++) {
            var check_x = x + (dx * dist * Board_Manager.tile_size);
            var check_y = y + (dy * dist * Board_Manager.tile_size);
            
            // Check if position is on the board
            var tile = instance_place(check_x, check_y, Tile_Obj);
            if (!tile) break; // Stop if we're off the board
            
            // Check if position is occupied
            var piece = instance_place(check_x, check_y, Chess_Piece_Obj);
            
            // Add this position to valid_moves array
            array_push(valid_moves, [dx * dist, dy * dist]);
            
            // If we hit a piece, stop checking this direction
            if (piece) break;
			
			// If path crosses water, stop.
			if tile.tile_type = 1 {
				if (!instance_position(check_x+tile_size/4, check_y+tile_size/4, Bridge_Obj)) {
					break;
				}
			}
        }
    }
}