//Knight_Obj Create

image_index = 0;
image_speed = 0;

//Movement
can_move_through_pieces = false;
valid_moves = [[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]];

has_moved = false;

// 0 = white, 1 = black, 2 = corrupted
piece_type = 0;