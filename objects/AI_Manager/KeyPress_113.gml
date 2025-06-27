// F2 Key (vk_f2) - Fix Stuck Pieces
// KeyPress_vk_f2 event:
var fixed = ai_fix_stuck_pieces();
show_debug_message("Fixed " + string(fixed) + " stuck pieces");