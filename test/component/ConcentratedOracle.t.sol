// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StubPriceOracle} from "test/adapter/StubPriceOracle.sol";
import {ConcentratedOracle} from "src/component/ConcentratedOracle.sol";

contract ConcentratedOracleNumericTest is Test {
    address base = makeAddr("BASE");
    address quote = makeAddr("QUOTE");
    StubPriceOracle fundamentalOracle;
    StubPriceOracle marketOracle;
    ConcentratedOracle oracle;

    function setUp() public {
        fundamentalOracle = new StubPriceOracle();
        marketOracle = new StubPriceOracle();
    }

    /// forge-config: default.fuzz.runs = 10000
    function test_Quote_Lambda40(uint256 scale) public {
        scale = bound(scale, 1e18, 1e27);
        oracle = new ConcentratedOracle(base, quote, address(fundamentalOracle), address(marketOracle), 40);
        fundamentalOracle.setPrice(base, quote, 1e18);

        _testCase(1000e18, 1000e18, scale);
        _testCase(1.5e18, 1.5e18, scale);
        _testCase(1.1e18, 1.098168e18, scale);
        _testCase(1.025e18, 1.015803e18, scale);
        _testCase(1.01e18, 1.003297e18, scale);
        _testCase(1e18, 1e18, scale);
        _testCase(0.99e18, 0.996703e18, scale);
        _testCase(0.975e18, 0.984197e18, scale);
        _testCase(0.9e18, 0.901832e18, scale);
        _testCase(0.5e18, 0.5e18, scale);
        _testCase(0.01e18, 0.01e18, scale);
    }

    /// forge-config: default.fuzz.runs = 10000
    function test_Quote_Lambda100(uint256 scale) public {
        scale = bound(scale, 1e9, 1e27);
        oracle = new ConcentratedOracle(base, quote, address(fundamentalOracle), address(marketOracle), 100);
        fundamentalOracle.setPrice(base, quote, 1e18);

        _testCase(1000e18, 1000e18, scale);
        _testCase(1.5e18, 1.5e18, scale);
        _testCase(1.1e18, 1.099995e18, scale);
        _testCase(1.01e18, 1.006321e18, scale);
        _testCase(1e18, 1e18, scale);
        _testCase(0.99e18, 0.993679e18, scale);
        _testCase(0.975e18, 0.977052e18, scale);
        _testCase(0.9e18, 0.900005e18, scale);
        _testCase(0.5e18, 0.5e18, scale);
        _testCase(0.01e18, 0.01e18, scale);
    }

    function _testCase(uint256 m, uint256 r, uint256 scale) internal {
        marketOracle.setPrice(base, quote, m * scale / 1e18);
        fundamentalOracle.setPrice(base, quote, scale);

        assertApproxEqRel(oracle.getQuote(1e18, base, quote), r * scale / 1e18, 0.000001e18);
    }
}
