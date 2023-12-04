// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {IYearnV2Vault} from "src/adapter/yearn-v2/IYearnV2Vault.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract YearnV2VaultOracle is BaseOracle {
    struct Config {
        address underlying;
        uint8 yvTokenDecimals;
        uint8 underlyingDecimals;
    }

    mapping(address yvToken => Config) public configs;

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.YearnV2VaultOracle();
    }

    function _initializeOracle(bytes memory _data) internal override {
        address[] memory yvTokens = abi.decode(_data, (address[]));

        uint256 length = yvTokens.length;
        for (uint256 i = 0; i < length;) {
            address yvToken = yvTokens[i];
            address underlying = IYearnV2Vault(yvToken).token();
            uint8 yvTokenDecimals = ERC20(yvToken).decimals();
            uint8 underlyingDecimals = ERC20(underlying).decimals();

            configs[yvToken] = Config({
                underlying: underlying,
                yvTokenDecimals: yvTokenDecimals,
                underlyingDecimals: underlyingDecimals
            });

            unchecked {
                ++i;
            }
        }
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        Config memory config = configs[base];
        if (config.underlying == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        if (config.underlying == quote) {
            uint256 price = IYearnV2Vault(base).pricePerShare();
            return inAmount * 10 ** config.yvTokenDecimals / price;
        }

        config = configs[quote];
        if (config.underlying == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        if (config.underlying == base) {
            uint256 price = IYearnV2Vault(quote).pricePerShare();
            return inAmount * price / 10 ** config.yvTokenDecimals;
        }

        revert Errors.EOracle_NotSupported(base, quote);
    }
}
