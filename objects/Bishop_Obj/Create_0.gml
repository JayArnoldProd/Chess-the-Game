// Bishop_Obj Create
image_index = 0;
image_speed = 0;
// Movement
can_move_through_pieces = false;

// Instead of a fixed valid_moves array, we'll calculate valid moves dynamically
// These represent the directions a bishop can move: up-right, up-left, down-right, down-left
direction_moves = [[1,-1], [-1,-1], [1,1], [-1,1]];
max_distance = 7; // Maximum squares a bishop can move (standard chess board is 8x8)
has_moved = false;

// 0 = white, 1 = black, 2 = corrupted
piece_type = 0;