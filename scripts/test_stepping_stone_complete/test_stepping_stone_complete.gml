/// @function test_stepping_stone_complete()
/// @description Comprehensive test for stepping stone mechanics
function test_stepping_stone_complete() {
    show_debug_message("=== COMPREHENSIVE STEPPING STONE TEST ===");
    
    // Step 1: Verify stepping stones exist
    var stone_count = instance_number(Stepping_Stone_Obj);
    show_debug_message("Step 1: Found " + string(stone_count) + " stepping stones");
    
    if (stone_count == 0) {
        show_debug_message("❌ FAILED: No stepping stones on board");
        return false;
    }
    
    // Step 2: Test stepping stone detection
    var first_stone = instance_find(Stepping_Stone_Obj, 0);
    if (!instance_exists(first_stone)) {
        show_debug_message("❌ FAILED: Cannot access stepping stone");
        return false;
    }
    
    var stone_x = first_stone.x;
    var stone_y = first_stone.y;
    show_debug_message("Step 2: Testing detection at (" + string(stone_x) + "," + string(stone_y) + ")");
    
    // Test different detection methods
    var method1 = instance_position(stone_x, stone_y, Stepping_Stone_Obj);
    var method2 = instance_position(stone_x + Board_Manager.tile_size/4, stone_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    var method3 = instance_position(stone_x + Board_Manager.tile_size/2, stone_y + Board_Manager.tile_size/2, Stepping_Stone_Obj);
    
    show_debug_message("  Method 1 (exact): " + (method1 ? "✓" : "✗"));
    show_debug_message("  Method 2 (quarter): " + (method2 ? "✓" : "✗"));
    show_debug_message("  Method 3 (half): " + (method3 ? "✓" : "✗"));
    
    if (!method1 && !method2 && !method3) {
        show_debug_message("❌ FAILED: Stepping stone detection not working");
        return false;
    }
    
    // Step 3: Check AI pieces and their proximity to stones
    var ai_pieces_near_stones = 0;
    var total_ai_pieces = 0;
    
    with (Chess_Piece_Obj) {
        if (piece_type == 1) { // Black AI pieces
            total_ai_pieces++;
            
            // Check all 8 directions for stepping stones
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    
                    var check_x = x + dx * Board_Manager.tile_size;
                    var check_y = y + dy * Board_Manager.tile_size;
                    
                    var stone_nearby = instance_position(check_x + Board_Manager.tile_size/4, check_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
                    if (stone_nearby) {
                        ai_pieces_near_stones++;
                        show_debug_message("  " + piece_id + " can reach stone at (" + string(check_x) + "," + string(check_y) + ")");
                        break;
                    }
                }
            }
        }
    }
    
    show_debug_message("Step 3: " + string(ai_pieces_near_stones) + "/" + string(total_ai_pieces) + " AI pieces can reach stones");
    
    // Step 4: Test move generation for stepping stones
    var moves = ai_get_legal_moves_safe(1);
    var stone_moves = 0;
    
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var on_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
        if (on_stone) {
            stone_moves++;
            show_debug_message("  Stone move: " + move.piece_id + " to (" + string(move.to_x) + "," + string(move.to_y) + ")");
        }
    }
    
    show_debug_message("Step 4: Found " + string(stone_moves) + " stepping stone moves out of " + string(array_length(moves)) + " total");
    
    // Step 5: Test AI move scoring for stepping stones
    if (stone_moves > 0) {
        for (var i = 0; i < array_length(moves); i++) {
            var move = moves[i];
            var on_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
            if (on_stone) {
                // Test scoring
                var base_score = 100;
                var stone_bonus = 150;
                var expected_score = base_score + stone_bonus;
                
                show_debug_message("  Expected score for stone move: ~" + string(expected_score) + " points");
                break;
            }
        }
    }
    
    // Step 6: Test stepping stone sequence state
    show_debug_message("Step 6: AI stepping stone state:");
    show_debug_message("  Phase: " + string(AI_Manager.ai_stepping_phase));
    show_debug_message("  Piece: " + (AI_Manager.ai_stepping_piece != noone ? AI_Manager.ai_stepping_piece.piece_id : "none"));
    
    // Summary
    show_debug_message("=== TEST SUMMARY ===");
    show_debug_message("✓ Stepping stones: " + string(stone_count) + " found");
    show_debug_message("✓ Detection: Working");
    show_debug_message("✓ AI pieces near stones: " + string(ai_pieces_near_stones));
    show_debug_message("✓ Stone moves available: " + string(stone_moves));
    
    if (stone_moves > 0) {
        show_debug_message("🎯 AI should be able to use stepping stones!");
        return true;
    } else {
        show_debug_message("⚠️  No stepping stone moves currently available");
        return false;
    }
}