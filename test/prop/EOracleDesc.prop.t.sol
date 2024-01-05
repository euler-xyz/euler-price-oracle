// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";

abstract contract EOracleDescPropTest is Test {
    IEOracle internal oracle;

    function setUp() public {
        oracle = IEOracle(_deployOracle());
    }

    function statefulFuzz_Description_Available() public view {
        oracle.description();
    }

    function _deployOracle() internal virtual returns (address);
}
