// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @author totomanov
/// @notice An array of up to 8 addresses stored immutably in code.
/// @dev This contract is necessary because Solidity does not support immutable arrays.
abstract contract ImmutableAddressArray {
    /// @dev Can hold up to 8 addresses. Storing more immutables
    /// increases deployment cost and marginally increases usage cost.
    uint256 private constant MAX_CARDINALITY = 8;

    /// @notice The size of the array.
    uint256 internal immutable cardinality;
    address private immutable e0;
    address private immutable e1;
    address private immutable e2;
    address private immutable e3;
    address private immutable e4;
    address private immutable e5;
    address private immutable e6;
    address private immutable e7;

    error ArrayEmpty();
    error ArrayTooLarge(uint256 length, uint256 maxLength);
    error IndexOOB(uint256 index, uint256 maxIndex);

    /// @notice Deploy a new ImmutableAddressArray.
    /// @param arr The immutable array of addresses.
    /// @dev Reverts if `arr` is empty or if it has more than 8 elements.
    constructor(address[] memory arr) {
        uint256 _cardinality = arr.length;
        if (_cardinality == 0) revert ArrayEmpty();
        if (_cardinality > MAX_CARDINALITY) revert ArrayTooLarge(_cardinality, MAX_CARDINALITY);

        cardinality = _cardinality;
        e0 = _getOrReturnZero(arr, 0);
        e1 = _getOrReturnZero(arr, 1);
        e2 = _getOrReturnZero(arr, 2);
        e3 = _getOrReturnZero(arr, 3);
        e4 = _getOrReturnZero(arr, 4);
        e5 = _getOrReturnZero(arr, 5);
        e6 = _getOrReturnZero(arr, 6);
        e7 = _getOrReturnZero(arr, 7);
    }

    /// @notice Get the element at index i.
    /// @dev Prefixed with `_array` to avoid collisions and ambiguity in the inheriting contract.
    /// Reverts if the index is out of bounds given the cardinality.
    function _arrayGet(uint256 i) internal view returns (address) {
        if (i > cardinality - 1) revert IndexOOB(i, cardinality - 1);
        if (i == 0) return e0;
        if (i == 1) return e1;
        if (i == 2) return e2;
        if (i == 3) return e3;
        if (i == 4) return e4;
        if (i == 5) return e5;
        if (i == 6) return e6;
        if (i == 7) return e7;
        revert(); // unreachable, suppress compiler warning
    }

    /// @notice Find the index of the element `a`.
    /// @dev Prefixed with `_array` to avoid collisions and ambiguity in the inheriting contract.
    /// INTEGRATOR NOTE: Does not revert if `a` is not found in the array.
    /// Instead, this function returns the special value `2**256-1` to indicate `a` was not found.
    function _arrayFind(address a) internal view returns (uint256) {
        if (a == e0) return 0;
        if (a == e1) return 1;
        if (a == e2) return 2;
        if (a == e3) return 3;
        if (a == e4) return 4;
        if (a == e5) return 5;
        if (a == e6) return 6;
        if (a == e7) return 7;
        return type(uint256).max;
    }

    /// @dev Return `arr[i]` or `address(0)` if the index is out of bounds.
    /// Used solely in the constructor.
    function _getOrReturnZero(address[] memory arr, uint256 i) private pure returns (address) {
        return i < arr.length ? arr[i] : address(0);
    }
}
