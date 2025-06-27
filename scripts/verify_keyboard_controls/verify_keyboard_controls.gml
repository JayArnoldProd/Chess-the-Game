/// @function verify_keyboard_controls()
/// @description Verifies keyboard controls are set up
function verify_keyboard_controls() {
    show_debug_message("=== KEYBOARD CONTROL TEST ===");
    show_debug_message("Try these controls:");
    show_debug_message("- Press ESC (should stop AI)");
    show_debug_message("- Press F1 (should toggle debug)");
    show_debug_message("- Press F2 (should fix stuck pieces)");
    show_debug_message("- Press F3 (should restart AI)");
    show_debug_message("- Press Ctrl+1 (should set difficulty 1)");
    show_debug_message("- Press Ctrl+3 (should set difficulty 3)");
    show_debug_message("Each key press should show a message in the debug log");
}
