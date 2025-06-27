/// @function ai_evaluate_water_control()
/// @returns {real} score_ for water tile control

function ai_evaluate_water_control() {
    var score_ = 0;
    
    // Count pieces near water that could be vulnerable
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            var water_threat = 0;
            var water_tiles_near = 0;
            
            // Check tiles around piece
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    
                    var check_x = x + dx * Board_Manager.tile_size;
                    var check_y = y + dy * Board_Manager.tile_size;
                    var tile = instance_place(check_x, check_y, Tile_Obj);
                    
                    if (tile && tile.tile_type == 1) { // Water tile
                        water_tiles_near++;
                        
                        // Check if there's a bridge
                        if (!instance_position(check_x + Board_Manager.tile_size/4, 
                                             check_y + Board_Manager.tile_size/4, Bridge_Obj)) {
                            water_threat += 50; // Dangerous water nearby
                        }
                    }
                }
            }
            
            if (piece_type == 1) { // Black
                score_ -= water_threat * 0.5; // Penalty for being near dangerous water
            } else { // White
                score_ += water_threat * 0.5; // Bonus when opponent near water
            }
        }
    }
    
    return score_;
}
