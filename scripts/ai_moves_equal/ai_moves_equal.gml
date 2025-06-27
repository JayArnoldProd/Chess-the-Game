/// @function ai_moves_equal(move1, move2)
/// @param {struct} move1 First move
/// @param {struct} move2 Second move
/// @returns {bool} Whether moves are equal

function ai_moves_equal(move1, move2) {
    if (move1 == undefined || move2 == undefined) return false;
    
    return (move1.from_x == move2.from_x && 
            move1.from_y == move2.from_y && 
            move1.to_x == move2.to_x && 
            move1.to_y == move2.to_y);
}