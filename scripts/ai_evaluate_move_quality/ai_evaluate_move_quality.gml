/// @function ai_evaluate_move_quality(move)
/// @returns {string} Quality assessment
function ai_evaluate_move_quality(move) {
    var score_ = ai_score_move_tactical(move);
    
    if (score_ > 300) return "Excellent";
    if (score_ > 150) return "Good";
    if (score_ > 50) return "Decent";
    if (score_ > -50) return "Okay";
    return "Poor";
}