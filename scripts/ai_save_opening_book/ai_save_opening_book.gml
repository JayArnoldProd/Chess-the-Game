/// @function ai_save_opening_book()
/// @description Saves opening book to file (if you want persistence)

function ai_save_opening_book() {
    // This would save the opening book to a file for persistence
    // Implementation depends on your file I/O needs
    show_debug_message("Opening book has " + string(ds_map_size(opening_book)) + " positions");
}
