// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Adapter for Redstone Core (pull-based)
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase, BaseOracle {
    mapping(address base => mapping(address quote => Config)) public configs;

    event ConfigSet(address indexed base, address indexed quote, bytes32 indexed feedId);
    event ConfigUnset(address indexed base, address indexed quote);

    struct Config {
        bytes32 feedId;
        uint32 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    struct ConfigParams {
        address base;
        address quote;
        bytes32 feedId;
        uint32 maxStaleness;
        bool inverse;
    }

    function govSetConfig(ConfigParams memory params) external onlyGovernor {
        uint8 baseDecimals = ERC20(params.base).decimals();
        uint8 quoteDecimals = ERC20(params.quote).decimals();

        configs[params.base][params.quote] = Config({
            feedId: params.feedId,
            maxStaleness: params.maxStaleness,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            inverse: params.inverse
        });

        configs[params.quote][params.base] = Config({
            feedId: params.feedId,
            maxStaleness: params.maxStaleness,
            baseDecimals: quoteDecimals,
            quoteDecimals: baseDecimals,
            inverse: !params.inverse
        });
        emit ConfigSet(params.base, params.quote, params.feedId);
        emit ConfigSet(params.quote, params.base, params.feedId);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.RedstoneCoreOracle(governor);
    }

    function _getQuote(uint256 inAmount, address base, address quote) internal view returns (uint256) {
        Config memory config = _getConfigOrRevert(base, quote);
        uint256 unitPrice = getOracleNumericValueFromTxMsg(config.feedId);
        if (config.inverse) return (inAmount * 10 ** config.quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** config.baseDecimals;
    }

    function _getConfigOrRevert(address base, address quote) internal view returns (Config memory) {
        Config memory config = configs[base][quote];
        if (config.feedId == 0) revert Errors.EOracle_NotSupported(base, quote);
        return config;
    }
}
