// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubPriceOracle} from "test/adapter/StubPriceOracle.sol";
import {AnchoredOracle} from "src/components/AnchoredOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract AnchoredOracleTest is Test {
    /// @notice The lower bound for `maxDivergence`, 0.1%.
    uint256 internal constant MAX_DIVERGENCE_LOWER_BOUND = 0.001e18;
    /// @notice The upper bound for `maxDivergence`, 50%.
    uint256 internal constant MAX_DIVERGENCE_UPPER_BOUND = 0.5e18;

    uint256 MAX_DIVERGENCE = 0.1e18;
    StubPriceOracle primary;
    StubPriceOracle anchor;
    AnchoredOracle oracle;

    function setUp() public {
        primary = new StubPriceOracle();
        anchor = new StubPriceOracle();
        oracle = new AnchoredOracle(address(primary), address(anchor), MAX_DIVERGENCE);
    }

    function test_Constructor_Integrity() public view {
        assertEq(oracle.primaryOracle(), address(primary));
        assertEq(oracle.anchorOracle(), address(anchor));
        assertEq(oracle.maxDivergence(), MAX_DIVERGENCE);
    }

    function test_Constructor_RevertsWhen_MaxDivergenceTooLow(address base, address quote, uint256 maxDivergence) public {
        maxDivergence = bound(maxDivergence, 0, MAX_DIVERGENCE_LOWER_BOUND - 1);
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new AnchoredOracle(base, quote, maxDivergence);
    }

    function test_Constructor_RevertsWhen_MaxDivergenceTooHigh(address base, address quote, uint256 maxDivergence) public {
        maxDivergence = bound(maxDivergence, MAX_DIVERGENCE_UPPER_BOUND + 1, type(uint256).max);
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new AnchoredOracle(base, quote, maxDivergence);
    }

    function test_Quote_Integrity(uint256 inAmount, address base, address quote, uint256 prim, uint256 priceB) public {

    }
}
