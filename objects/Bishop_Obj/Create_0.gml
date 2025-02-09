// Bishop_Obj Create

event_inherited();
piece_id = "bishop";
health_ = 1;
can_move_through_pieces = false;

// Instead of a fixed valid_moves array, we'll calculate valid moves dynamically
// These represent the directions a bishop can move: up-right, up-left, down-right, down-left
direction_moves = [[1,-1], [-1,-1], [1,1], [-1,1]];
max_distance = 7; // Maximum squares a bishop can move (standard chess board is 8x8)
