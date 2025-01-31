if instance_exists(Board_Manager) {
	tile_size = Board_Manager.tile_size;

	visible = false;
	top_row = [Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj];
	bottom_row = [Rook_Obj,Knight_Obj,Bishop_Obj,Queen_Obj,King_Obj,Bishop_Obj,Knight_Obj,Rook_Obj];
	army_count = 16;
	army_width = 8;
	army_height = 2;
	
	if (room = Void_Dimension) {
		army_width = 6;
		if (round(random(1)) = 1) {
			top_row = [Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj];
			bottom_row = [Knight_Obj,Bishop_Obj,Queen_Obj,King_Obj,Bishop_Obj,Rook_Obj];
		} else {
			top_row = [Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj,Pawn_Obj];
			bottom_row = [Rook_Obj,Bishop_Obj,Queen_Obj,King_Obj,Bishop_Obj,Knight_Obj];
		}
	}
	for (i = 0; i < army_width; i++) {
		instance_create_depth(x + i * tile_size, y - tile_size, -1, top_row[i]);
		instance_create_depth(x + i * tile_size, y, -1, bottom_row[i]);
	}
}