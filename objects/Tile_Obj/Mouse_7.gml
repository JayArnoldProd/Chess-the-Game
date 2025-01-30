//Tile_Obj Left Released

selected_piece = Game_Manager.selected_piece;

if (valid_move and (selected_piece!=noone)) {
	selected_piece.x = x;
	selected_piece.y = y;
	selected_piece.has_moved = true;
	if tile_type = 1 {
		//ignore if theres a bridge
		with (selected_piece) {
			if (!instance_position(x+tile_size/4, y+tile_size/4, Bridge_Obj)) { 
				instance_destroy();
			}
		}
	}
	Game_Manager.selected_piece = noone;
	valid_move = false;
}