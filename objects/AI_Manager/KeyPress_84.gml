// T Key - Toggle AI On/Off
// KeyPress_84 event (Key "T"):
if (keyboard_check(vk_control)) {
    if (instance_exists(AI_Manager)) {
        AI_Manager.ai_enabled = !AI_Manager.ai_enabled;
        show_debug_message("AI " + (AI_Manager.ai_enabled ? "ENABLED" : "DISABLED"));
    }
}
