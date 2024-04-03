// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

contract SDaiOracleDiffHarness {
    function rpowSolady(uint256 x, uint256 y, uint256 b) external pure returns (uint256) {
        return FixedPointMathLib.rpow(x, y, b);
    }

    /// @dev From https://etherscan.io/address/0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7#code#L134
    function rpowMaker(uint256 x, uint256 n, uint256 base) external pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

contract SDaiOracleDiffTest is Test {
    SDaiOracleDiffHarness harness;

    constructor() {
        harness = new SDaiOracleDiffHarness();
    }

    /// forge-config: default.fuzz.runs = 100000
    function test_SoladyRpow_EquivalentTo_MakerRpow(uint256 x, uint256 n, uint256 base) public {
        (bool successSolady, bytes memory dataSolady) =
            address(harness).call(abi.encodeCall(SDaiOracleDiffHarness.rpowSolady, (x, n, base)));
        (bool successMaker, bytes memory dataMaker) =
            address(harness).call(abi.encodeCall(SDaiOracleDiffHarness.rpowMaker, (x, n, base)));

        assertEq(successSolady, successMaker);
        if (successSolady) assertEq(dataSolady, dataMaker);
    }
}
