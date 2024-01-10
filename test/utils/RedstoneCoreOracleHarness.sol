// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleHarness is RedstoneCoreOracle {
    uint256 price;

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getOracleNumericValueFromTxMsg(bytes32) internal view override returns (uint256) {
        return price;
    }
}
