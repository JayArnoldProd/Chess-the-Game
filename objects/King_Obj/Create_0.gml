// King_Obj Create
event_inherited();
piece_id = "king";
health_ = 1;
//Movement
can_move_through_pieces = false;
has_moved = false;


// All possible one-square moves around the king
valid_moves = [
    [0,-1],  // up
    [1,-1],  // up-right
    [1,0],   // right
    [1,1],   // down-right
    [0,1],   // down
    [-1,1],  // down-left
    [-1,0],  // left
    [-1,-1]  // up-left
];

