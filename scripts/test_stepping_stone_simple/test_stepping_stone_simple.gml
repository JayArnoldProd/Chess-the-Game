/// @function test_stepping_stone_simple()
/// @description Simple test to verify stepping stones work
function test_stepping_stone_simple() {
    show_debug_message("=== STEPPING STONE SIMPLE TEST ===");
    
    // Check if stepping stones exist
    var stone_count = instance_number(Stepping_Stone_Obj);
    show_debug_message("Stepping stones on board: " + string(stone_count));
    
    if (stone_count == 0) {
        show_debug_message("No stepping stones found - test cannot run");
        return false;
    }
    
    // Find first stepping stone
    var test_stone = instance_find(Stepping_Stone_Obj, 0);
    if (!instance_exists(test_stone)) {
        show_debug_message("Could not find stepping stone instance");
        return false;
    }
    
    show_debug_message("Test stone at: (" + string(test_stone.x) + "," + string(test_stone.y) + ")");
    
    // Check detection function
    var detected = instance_position(test_stone.x + Board_Manager.tile_size/4, test_stone.y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    if (detected) {
        show_debug_message("✓ Stepping stone detection working");
    } else {
        show_debug_message("✗ Stepping stone detection FAILED");
        return false;
    }
    
    // Find AI pieces that can reach stepping stones
    var can_reach_stone = false;
    with (Chess_Piece_Obj) {
        if (piece_type == 1) { // Black AI pieces
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    
                    var check_x = x + dx * Board_Manager.tile_size;
                    var check_y = y + dy * Board_Manager.tile_size;
                    
                    var stone_here = instance_position(check_x + Board_Manager.tile_size/4, check_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
                    if (stone_here) {
                        show_debug_message("AI " + piece_id + " can reach stepping stone at (" + string(check_x) + "," + string(check_y) + ")");
                        can_reach_stone = true;
                    }
                }
            }
        }
    }
    
    if (can_reach_stone) {
        show_debug_message("✓ AI can reach stepping stones");
    } else {
        show_debug_message("? No AI pieces can currently reach stepping stones");
    }
    
    show_debug_message("=== TEST COMPLETE ===");
    return true;
}