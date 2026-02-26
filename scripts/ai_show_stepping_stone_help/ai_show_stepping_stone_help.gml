/// @function ai_show_stepping_stone_help()
/// @description Shows help for stepping stone debugging
function ai_show_stepping_stone_help() {
    show_debug_message("=== STEPPING STONE DEBUG COMMANDS ===");
    show_debug_message("F7  - Show all stepping stones on board");
    show_debug_message("F8  - Force AI stepping stone test");
    show_debug_message("F9  - Run simple stepping stone test");
    show_debug_message("F10 - Force AI to make stepping stone move");
    show_debug_message("F11 - Manually advance stepping stone phase");
    show_debug_message("F12 - Show detailed stepping stone state");
    show_debug_message("INS - Force stepping stone phase 2");
    show_debug_message("ESC - Emergency reset AI");
    show_debug_message("===================================");
    show_debug_message("To test: Move a piece to a stepping stone, then use F11 to advance phases");
}