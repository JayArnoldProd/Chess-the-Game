// Rook_Obj Create
image_index = 0;
image_speed = 0;
// Movement
can_move_through_pieces = false;
max_distance = 7;
has_moved = false;

// Rook moves horizontally and vertically
direction_moves = [[0,-1], [1,0], [0,1], [-1,0]];  // up, right, down, left

// 0 = white, 1 = black, 2 = corrupted
piece_type = 0;