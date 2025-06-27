/// @function ai_get_performance_stats()
/// @returns {string} Performance statistics

function ai_get_performance_stats() {
    var stats = "AI Performance:\n";
    stats += "Nodes searched: " + string(search_stats.nodes) + "\n";
    stats += "TT hits: " + string(search_stats.tt_hits) + "\n";
    stats += "TT misses: " + string(search_stats.tt_misses) + "\n";
    stats += "Cutoffs: " + string(search_stats.cutoffs) + "\n";
    stats += "Time used: " + string(search_stats.time_used) + "ms\n";
    
    if (search_stats.time_used > 0) {
        var nps = (search_stats.nodes * 1000) / search_stats.time_used;
        stats += "Nodes/second: " + string(round(nps));
    }
    
    return stats;
}
