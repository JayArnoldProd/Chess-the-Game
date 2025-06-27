/// @function array_sum_custom(arr)
/// @param {array} arr Array to sum
/// @returns {real} Sum of all elements
function array_sum_custom(arr) {
    var sum = 0;
    for (var i = 0; i < array_length(arr); i++) {
        sum += arr[i];
    }
    return sum;
}
