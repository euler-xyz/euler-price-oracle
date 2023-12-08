// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOraclePropTest} from "test/EOracle.prop.t.sol";
import {ConstantOracle} from "src/adapter/constant/ConstantOracle.sol";

contract ConstantOracle_PropTest is EOraclePropTest {
    function _deployOracle() internal override returns (address) {
        return address(new ConstantOracle());
    }
}
