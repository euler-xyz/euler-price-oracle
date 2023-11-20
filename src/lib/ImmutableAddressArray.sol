// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract ImmutableAddressArray {
    uint256 private constant MAX_CARDINALITY = 8;

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

    function _get(uint256 i) internal view returns (address) {
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

    function _getOrReturnZero(address[] memory arr, uint256 i) private pure returns (address) {
        if (i < arr.length) return arr[i];
        return address(0);
    }
}
