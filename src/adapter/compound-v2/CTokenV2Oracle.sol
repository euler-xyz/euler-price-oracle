// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {ICTokenV2} from "src/adapter/compound-v2/ICTokenV2.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract CTokenV2Oracle is BaseOracle {
    mapping(address cToken => address underlying) public cTokens;

    constructor(address[] memory _cTokens) {
        uint256 length = _cTokens.length;
        for (uint256 i = 0; i < length;) {
            address cToken = _cTokens[i];
            cTokens[cToken] = ICTokenV2(cToken).underlying();
            unchecked {
                ++i;
            }
        }
    }

    function govSetConfig(address cToken) external onlyGovernor {
        cTokens[cToken] = ICTokenV2(cToken).underlying();
    }

    function govUnsetConfig(address cToken) external onlyGovernor {
        delete cTokens[cToken];
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.CTokenV2Oracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        address underlying = cTokens[base];
        if (underlying == address(0)) {
            underlying = cTokens[quote];
            if (underlying == address(0)) revert Errors.EOracle_NotSupported(base, quote);

            return inAmount * 1e18 / ICTokenV2(quote).exchangeRateStored();
        }
        return inAmount * ICTokenV2(base).exchangeRateStored() / 1e18;
    }
}
