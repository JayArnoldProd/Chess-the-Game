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

// Extra–move (stepping stone) state initialization
extra_move_pending = false;   // (alternative name: not used beyond activation)
stepping_chain = 0;           // 0 = no chain; 2 = extra move phase 1 pending; 1 = extra move phase 2 pending
stepping_stone_instance = noone;  // Will store the activated stepping stone’s instance id
stone_original_x = 0;         // Save original position so we can revert later
stone_original_y = 0;

pre_stepping_x = x;
pre_stepping_y = y;

last_x = x;
last_y = y;

original_turn_x = x;
original_turn_y = y;
original_has_moved = has_moved; 