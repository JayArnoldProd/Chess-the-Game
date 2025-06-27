/// @function ai_reset_performance_stats()
/// @description Resets performance counters

function ai_reset_performance_stats() {
    search_stats.nodes = 0;
    search_stats.tt_hits = 0;
    search_stats.tt_misses = 0;
    search_stats.cutoffs = 0;
    search_stats.time_used = 0;
}
