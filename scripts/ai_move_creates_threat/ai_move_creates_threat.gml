/// @function ai_move_creates_threat(move) - Simplified implementation
/// @param {struct} move The move to check
/// @returns {bool} Whether move creates a threat
function ai_move_creates_threat(move) {
    // Simplified threat detection
    if (move.is_capture) return true;
    if (ai_move_gives_check_fast(move)) return true;
    return false;
}