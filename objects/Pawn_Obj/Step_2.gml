//Pawn_Obj End Step

//Pawn can only move 2 spaces first move
if (has_moved = true) {
	valid_moves = [[0,-1]];
}

//change to queen at top
if (y = Top_Row.y) {
	instance_change(Queen_Obj,1);
}