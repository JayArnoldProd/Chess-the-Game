/// @function ai_evaluate_pawn_structure(color)
/// @param {real} color The color to evaluate (0 = white, 1 = black)
/// @returns {real} Pawn structure score

function ai_evaluate_pawn_structure_safe(color) {
    var structure_score = 0;
    var pawn_files = [0, 0, 0, 0, 0, 0, 0, 0]; // Count pawns per file
    
    // Count pawns in each file safely
    with (Pawn_Obj) {
        if (instance_exists(id) && piece_type == color && instance_exists(Object_Manager) && instance_exists(Board_Manager)) {
            var file = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            file = clamp(file, 0, 7);
            pawn_files[file]++;
        }
    }
    
    // Evaluate pawn structure
    for (var i = 0; i < 8; i++) {
        if (pawn_files[i] > 1) {
            structure_score -= 20; // Doubled pawns penalty
        }
        if (pawn_files[i] == 0 && i > 0 && i < 7) {
            // Check for isolated pawns
            if (pawn_files[i-1] == 0 && pawn_files[i+1] == 0) {
                structure_score -= 15; // Isolated pawn penalty
            }
        }
    }
    
    return structure_score;
}