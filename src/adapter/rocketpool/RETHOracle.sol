// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IReth} from "src/adapter/rocketpool/IReth.sol";

contract RETHOracle {
    address public immutable weth;
    address public immutable reth;

    error NotSupported(address base, address quote);

    constructor(address _weth, address _reth) {
        weth = _weth;
        reth = _reth;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (base == reth && quote == weth) {
            return IReth(reth).getEthValue(inAmount);
        }

        if (base == weth && quote == reth) {
            return IReth(reth).getRethValue(inAmount);
        }

        revert NotSupported(base, quote);
    }
}
