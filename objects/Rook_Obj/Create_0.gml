// Rook_Obj Create
event_inherited();
piece_id = "rook";
health_ = 1;
// Movement
can_move_through_pieces = false;
max_distance = 7;

// Rook moves horizontally and vertically
direction_moves = [[0,-1], [1,0], [0,1], [-1,0]];  // up, right, down, left
 