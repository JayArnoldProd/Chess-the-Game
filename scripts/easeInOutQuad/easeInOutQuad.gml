/// @function easeInOutQuad(t)
/// @param t A number from 0 to 1.
/// @returns The eased value.
function easeInOutQuad(t) {
    if (t < 0.5)
        return 2 * t * t;
    else
        return -1 + (4 - 2 * t) * t;
}