// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ICTokenV2} from "src/adapter/compound-v2/ICTokenV2.sol";

contract CTokenV2Oracle {
    address public immutable cToken;
    address public immutable underlying;

    error NotSupported(address base, address quote);

    constructor(address _cToken) {
        cToken = _cToken;
        underlying = ICTokenV2(_cToken).underlying();
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (base != cToken || quote != underlying) revert NotSupported(base, quote);

        uint256 rate = ICTokenV2(cToken).exchangeRateStored();
        return inAmount * rate / 1e18;
    }
}
