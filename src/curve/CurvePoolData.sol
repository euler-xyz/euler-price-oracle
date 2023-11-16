// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {console2} from "forge-std/console2.sol";

type CurvePoolData is uint256;

using CurvePoolDataLib for CurvePoolData global;

library CurvePoolDataLib {
    uint256 internal constant MODULUS = 11;
    uint256 internal constant ORDER_MASK = 0xF000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant ORDER_OFFSET = 252;

    error NoToken();
    error OOB(uint256);
    error ZeroAddend();

    /// @dev We find (a_1, a_2, ... , a_n) such that
    /// {t_1 + a_1, ... , t_n + a_n} is a reduced residue system modulo 11 in ℤ⁺ₘ
    /// Moreover, we constrain each t_i + a_i ≡ i (mod 11)
    /// The remainder i corresponds to the position of the token in the pool
    /// The modulus of 11 accomodates for 10 elements because φ(11) = 10
    /// Here φ is Euler's Totient Function, see https://www.doc.ic.ac.uk/~mrh/330tutor/ch05s02.html
    /// Read more: https://faculty.buffalostate.edu/cunnindw/351Sec3-4.pdf

    /// We need t_i + a_i = k * m + i
    /// (t_i + a_i) (mod m) = (k * m + i) (mod m)
    /// t_i (mod m) + a_i (mod m) = i // because i < m
    /// a_i (mod m) = i - t_i (mod m)
    /// A solution is a_i = m - t_i (mod m) + i
    /// We have one last constraint, we reserve a_i = 0 to represent the end of the token list
    /// So we use a_i = n in place of 0 in the above solution
    /// We need only 16 bits (one hex char) for each addend

    /// If c ≡ d (mod φ(n)), where φ is Euler's totient function, then ac ≡ ad (mod n)—provided that a is coprime with n.
    /// If c ≡ d (mod 11) then ac ≡ ad (mod 10) provided that a is coprime with 10.
    /// If t_i ≡ i (mod 11) then a_i*t_i ≡ a_i*i  (mod 10) provided that a_i is coprime with 10.
    /// We need t_i = 11k + i, and we check

    /// Find f such that f(t, i) -> i

    /// @dev tokens in modulus
    function from(address[] memory tokens) internal pure returns (CurvePoolData) {
        uint256 order = tokens.length;
        if (order > MODULUS) revert OOB(order);

        CurvePoolData data;
        data = setOrder(data, order);

        for (uint256 i = 0; i < order;) {
            address token = tokens[i];
            uint256 remainder = uint256(uint160(token)) % MODULUS;
            uint256 addend = (MODULUS - remainder + i) % MODULUS;
            if (addend == 0) addend = MODULUS;

            console2.log("addend of %s is %s", token, addend);
            data = data.setAddend(i, addend);
            unchecked {
                ++i;
            }
        }

        return data;
    }

    function getOrder(CurvePoolData data) internal pure returns (uint256) {
        return (CurvePoolData.unwrap(data) & ORDER_MASK) >> ORDER_OFFSET;
    }

    function setOrder(CurvePoolData data, uint256 order) internal pure returns (CurvePoolData) {
        return CurvePoolData.wrap((CurvePoolData.unwrap(data) & ~ORDER_MASK) | (order << ORDER_OFFSET));
    }

    function getAddend(CurvePoolData data, uint256 i) internal pure returns (uint256) {
        if (i >= MODULUS) revert OOB(i);

        uint256 pos = (i + 1) * 4;
        uint256 mask = 0xF000000000000000000000000000000000000000000000000000000000000000 >> pos;
        uint256 offset = ORDER_OFFSET - pos;
        return (CurvePoolData.unwrap(data) & mask) >> (offset);
    }

    function setAddend(CurvePoolData data, uint256 i, uint256 addend) internal pure returns (CurvePoolData) {
        if (i >= MODULUS) revert OOB(i);
        if (addend > MODULUS) revert OOB(addend);
        if (addend == 0) revert ZeroAddend();

        uint256 pos = (i + 1) * 4;
        uint256 mask = 0xF000000000000000000000000000000000000000000000000000000000000000 >> pos;
        uint256 offset = ORDER_OFFSET - pos;
        return CurvePoolData.wrap((CurvePoolData.unwrap(data) & ~mask) | (addend << offset));
    }

    function getTokenIndex(CurvePoolData data, address token) internal pure returns (uint256) {
        for (uint256 i = 0; i < MODULUS;) {
            uint256 addend = getAddend(data, i);
            if (checkAddend(token, addend, i)) {
                console2.log("getTokenIndex index of %s is %s", token, i);
                return i;
            }
            unchecked {
                ++i;
            }
        }
        revert NoToken();
    }

    function checkAddend(address token, uint256 addend, uint256 i) internal pure returns (bool c) {
        unchecked {
            uint256 remainder = (uint256(uint160(token)) + addend) % MODULUS;

            console2.log("checkAddend token=%s", token);
            console2.log("checkAddend addend=%s, remainder=%s", addend, remainder);

            return remainder == i;
        }
    }

    function empty() internal pure returns (CurvePoolData) {
        return CurvePoolData.wrap(0);
    }
}

/// Suppose we have T = 0, 1, 2, 3, ...
/// We
