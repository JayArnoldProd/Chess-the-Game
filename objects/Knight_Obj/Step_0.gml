// Inherit the parent event
event_inherited();

// After inherited code in Knight_Obj Step event:
if (stepping_chain == 1) {
    // Restore the knight's normal L-shaped moves.
    valid_moves = [[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]];
}

