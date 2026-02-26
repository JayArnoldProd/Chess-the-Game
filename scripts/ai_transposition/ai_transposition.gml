/// @function ai_tt_init(size_bits)
/// @description Initializes transposition table
/// @param {real} size_bits Log2 of table size (e.g., 16 = 65536 entries)
function ai_tt_init(size_bits = 16) {
    var size = 1 << size_bits;
    global.tt_size = size;
    global.tt_mask = size - 1;
    global.tt_entries = array_create(size, undefined);
    global.tt_hits = 0;
    global.tt_stores = 0;
    global.tt_collisions = 0;
}

// TT entry flags
#macro TT_EXACT 0
#macro TT_ALPHA 1  // Upper bound (failed low)
#macro TT_BETA 2   // Lower bound (failed high)

/// @function ai_tt_probe(hash, depth, alpha, beta)
/// @description Probes transposition table for a position
/// @returns {struct|undefined} Entry if found and valid, undefined otherwise
function ai_tt_probe(hash, depth, alpha, beta) {
    if (!variable_global_exists("tt_entries")) return undefined;
    
    var idx = hash[0] & global.tt_mask;
    var entry = global.tt_entries[idx];
    
    if (entry == undefined) return undefined;
    
    // Verify hash match (both parts)
    if (entry.hash_lo != hash[0] || entry.hash_hi != hash[1]) {
        return undefined;
    }
    
    // Only use if depth is sufficient
    if (entry.depth < depth) return undefined;
    
    global.tt_hits++;
    
    // Return based on bound type
    if (entry.flag == TT_EXACT) {
        return entry;
    } else if (entry.flag == TT_ALPHA && entry.score <= alpha) {
        return entry;
    } else if (entry.flag == TT_BETA && entry.score >= beta) {
        return entry;
    }
    
    // Return move hint even if score isn't usable
    return { move: entry.move, score: undefined, flag: -1 };
}

/// @function ai_tt_store(hash, depth, score, flag, move)
/// @description Stores position in transposition table
function ai_tt_store(hash, depth, score, flag, move) {
    if (!variable_global_exists("tt_entries")) {
        ai_tt_init();
    }
    
    var idx = hash[0] & global.tt_mask;
    var existing = global.tt_entries[idx];
    
    // Replacement scheme: always replace if new depth >= existing depth
    if (existing != undefined && existing.depth > depth) {
        // Keep existing deeper entry unless this is an exact score
        if (flag != TT_EXACT) {
            global.tt_collisions++;
            return;
        }
    }
    
    global.tt_entries[idx] = {
        hash_lo: hash[0],
        hash_hi: hash[1],
        depth: depth,
        score: score,
        flag: flag,
        move: move
    };
    
    global.tt_stores++;
}

/// @function ai_tt_clear()
/// @description Clears transposition table
function ai_tt_clear() {
    if (variable_global_exists("tt_entries")) {
        var size = global.tt_size;
        for (var i = 0; i < size; i++) {
            global.tt_entries[i] = undefined;
        }
        global.tt_hits = 0;
        global.tt_stores = 0;
        global.tt_collisions = 0;
    }
}

/// @function ai_tt_stats()
/// @description Returns TT statistics
function ai_tt_stats() {
    return {
        size: variable_global_exists("tt_size") ? global.tt_size : 0,
        stores: variable_global_exists("tt_stores") ? global.tt_stores : 0,
        hits: variable_global_exists("tt_hits") ? global.tt_hits : 0,
        collisions: variable_global_exists("tt_collisions") ? global.tt_collisions : 0
    };
}
