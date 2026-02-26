/// AI_Manager Create Event - MULTI-FRAME AI WITH STATE MACHINE
show_debug_message("AI_Manager: Initializing multi-frame AI system...");

// Core AI control variables
ai_enabled = true;
ai_selected_move = undefined;
ai_move_delay = 15;

// ========== MULTI-FRAME STATE MACHINE ==========
ai_state = "idle";              // Current state: idle, preparing, searching, executing
ai_search_board = undefined;    // Virtual board for search
ai_search_world_state = undefined; // World state (includes board, tiles, objects)
ai_search_moves = [];           // Root moves to evaluate
ai_search_index = 0;            // Current root move being searched
ai_search_best_move = undefined;
ai_search_best_score = -999999;
ai_search_current_depth = 1;    // Current iterative deepening depth
ai_search_max_depth = 20;       // Maximum depth
ai_search_start_time = 0;       // When search began (get_timer())
ai_search_frame_budget = 10;    // ms per frame (10ms leaves 6.6ms for game loop at 60fps)
ai_search_nodes_total = 0;      // Total nodes searched
ai_search_depth_scores = [];    // Best score at each depth for reordering

// For "Thinking..." animation
ai_thinking_dots = 0;
ai_thinking_timer = 0;

// Search statistics (for debug display)
ai_last_search_time = 0;
ai_last_search_depth = 0;
ai_last_search_nodes = 0;
ai_last_search_score = 0;

// Search parameters (controlled by difficulty)
ai_time_limit = 2000; // Time limit in milliseconds for search

// Stepping stone support
ai_stepping_phase = 0; // 0 = normal, 1 = phase1 pending, 2 = phase2 pending
ai_stepping_piece = noone;

// Initialize AI systems
ai_zobrist_init(); // Initialize Zobrist hashing
ai_tt_init(16);    // Initialize transposition table (65536 entries)

// Simple piece values for evaluation
piece_values = ds_map_create();
ds_map_add(piece_values, "pawn", 100);
ds_map_add(piece_values, "knight", 320);
ds_map_add(piece_values, "bishop", 330);
ds_map_add(piece_values, "rook", 500);
ds_map_add(piece_values, "queen", 900);
ds_map_add(piece_values, "king", 20000);

// Difficulty settings
max_moves_to_consider = 8; // How many moves to evaluate (difficulty)

// Debug display
global.ai_debug_visible = true;

// Simple piece-square tables for positional evaluation
pawn_table = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5,  5, 10, 25, 25, 10,  5,  5],
    [0,  0,  0, 20, 20,  0,  0,  0],
    [5, -5,-10,  0,  0,-10, -5,  5],
    [5, 10, 10,-20,-20, 10, 10,  5],
    [0,  0,  0,  0,  0,  0,  0,  0]
];

knight_table = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50]
];

bishop_table = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20]
];

rook_table = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [0,  0,  0,  5,  5,  0,  0,  0]
];

queen_table = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [-5,  0,  5,  5,  5,  5,  0, -5],
    [0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20]
];

king_middle_table = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [20, 20,  0,  0,  0,  0, 20, 20],
    [20, 30, 10,  0,  0, 10, 30, 20]
];

king_end_table = [
    [-50,-40,-30,-20,-20,-30,-40,-50],
    [-30,-20,-10,  0,  0,-10,-20,-30],
    [-30,-10, 20, 30, 30, 20,-10,-30],
    [-30,-10, 30, 40, 40, 30,-10,-30],
    [-30,-10, 30, 40, 40, 30,-10,-30],
    [-30,-10, 20, 30, 30, 20,-10,-30],
    [-30,-30,  0,  0,  0,  0,-30,-30],
    [-50,-30,-30,-30,-30,-30,-30,-50]
];

show_debug_message("AI_Manager: Multi-frame AI ready with state machine");

// Set initial difficulty
ai_set_difficulty_simple(3);
