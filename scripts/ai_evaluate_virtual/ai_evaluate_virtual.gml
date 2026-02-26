/// @function ai_evaluate_virtual(board)
/// @param {array} board Virtual board state
/// @returns {real} Evaluation score (positive = black/AI advantage)
/// @description Evaluates a virtual board position using advanced evaluation
function ai_evaluate_virtual(board) {
    // Use the full advanced evaluation with:
    // - Material counting with middlegame/endgame interpolation
    // - Piece-square tables
    // - Pawn structure (doubled, isolated, passed pawns)
    // - King safety
    // - Mobility
    // - Bishop pair bonus
    return ai_evaluate_advanced(board);
}
