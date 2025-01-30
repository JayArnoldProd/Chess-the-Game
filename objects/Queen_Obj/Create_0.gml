// Queen_Obj Create
image_index = 0;
image_speed = 0;
// Movement
can_move_through_pieces = false;
max_distance = 7;
has_moved = false;

// Queen moves in all 8 directions (combine rook and bishop directions)
direction_moves = [
    [0,-1], [1,0], [0,1], [-1,0],  // horizontal/vertical (rook moves)
    [1,-1], [-1,-1], [1,1], [-1,1]  // diagonal (bishop moves)
];
