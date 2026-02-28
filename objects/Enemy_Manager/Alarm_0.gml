/// Enemy_Manager Alarm 0
/// TEST: Spawn placeholder enemies per room for gimmick testing
/// Remove this after PRP-009 implements proper spawning

/// Helper: destroy black pawn at (col, row) and spawn enemy there
var _spawn = function(_col, _row) {
    var _tx = Object_Manager.topleft_x + _col * Board_Manager.tile_size;
    var _ty = Object_Manager.topleft_y + _row * Board_Manager.tile_size;
    
    var _pawn = instance_position(_tx, _ty, Chess_Piece_Obj);
    if (_pawn != noone && _pawn.piece_type == 1) {
        var _pid = _pawn.piece_id;
        instance_destroy(_pawn);
        show_debug_message("TEST: Destroyed black " + _pid + " at (" + string(_col) + ", " + string(_row) + ")");
    }
    
    var _enemy = enemy_create("placeholder", _col, _row);
    if (_enemy != noone) {
        show_debug_message("TEST: Spawned placeholder enemy at (" + string(_col) + ", " + string(_row) + ")");
    }
};

if (room == Ruined_Overworld) {
    // Original test: 1 enemy at (4, 1)
    _spawn(4, 1);
    
} else if (room == Pirate_Seas) {
    // Water/bridge level: 2 enemies on front pawn row, separated by one piece
    // Pawn row is row 1, space them out: col 2 and col 5 (one pawn gap between)
    _spawn(2, 1);
    _spawn(5, 1);
    
} else if (room == Fear_Factory) {
    // Conveyor belt level: 3 enemies on pawn row, one pawn gap between each
    // Cols 1, 3, 5 (pawns at 0, 2, 4, 6, 7 remain)
    _spawn(1, 1);
    _spawn(3, 1);
    _spawn(5, 1);
    
} else {
    // Default: 1 enemy at (4, 1) for any other room
    _spawn(4, 1);
}
