// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";

abstract contract PythOracle is BaseOracle {
    struct Config {
        bytes32 feedId;
        uint8 decimals;
    }

    struct ConfigParams {
        bytes32 feedId;
        address token;
    }

    IPyth public immutable pyth;
    uint256 public maxStaleness;
    mapping(address token => Config) public configs;

    constructor(address _pyth, uint256 _maxStaleness, ConfigParams[] memory _initialConfigs) {
        pyth = IPyth(_pyth);
        maxStaleness = _maxStaleness;

        uint256 length = _initialConfigs.length;
        for (uint256 i = 0; i < length;) {
            _setConfig(_initialConfigs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        virtual
        returns (uint256, uint256);

    function _setConfig(ConfigParams memory params) internal {
        uint8 decimals = ERC20(params.token).decimals();
        configs[params.token] = Config(params.feedId, decimals);
    }

    function _fetchPriceStruct(address token) internal view returns (PythStructs.Price memory) {
        bytes32 feedId = configs[token].feedId;
        if (feedId == 0) revert Errors.EOracle_NotSupported(token, address(0));
        return pyth.getPriceNoOlderThan(feedId, maxStaleness);
    }

    function _fetchEMAPriceStruct(address token) internal view returns (PythStructs.Price memory) {
        bytes32 feedId = configs[token].feedId;
        if (feedId == 0) revert Errors.EOracle_NotSupported(token, address(0));
        return pyth.getEmaPriceNoOlderThan(feedId, maxStaleness);
    }

    function _combinePrices(
        uint256 inAmount,
        PythStructs.Price memory baseStruct,
        PythStructs.Price memory quoteStruct,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256 result) {
        _sanityCheckPriceStruct(baseStruct);
        _sanityCheckPriceStruct(quoteStruct);

        int256 netDecimals = _calculateNetDecimals(baseStruct.expo, quoteStruct.expo, baseDecimals, quoteDecimals);

        return _calculatePrice(inAmount, baseStruct.price, quoteStruct.price, netDecimals);
    }

    function _combinePricesWithSpread(
        uint256 inAmount,
        PythStructs.Price memory baseStruct,
        PythStructs.Price memory quoteStruct,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256, uint256) {
        _sanityCheckPriceStruct(baseStruct);
        _sanityCheckPriceStruct(quoteStruct);

        int256 netDecimals = _calculateNetDecimals(baseStruct.expo, quoteStruct.expo, baseDecimals, quoteDecimals);
        (int64 baseBidPrice, int64 baseAskPrice) = _getBidAsk(baseStruct);
        (int64 quoteBidPrice, int64 quoteAskPrice) = _getBidAsk(quoteStruct);

        uint256 bid = _calculatePrice(inAmount, baseBidPrice, quoteBidPrice, netDecimals);
        uint256 ask = _calculatePrice(inAmount, baseAskPrice, quoteAskPrice, netDecimals);
        return (bid, ask);
    }

    function _calculatePrice(uint256 inAmount, int64 basePrice, int64 quotePrice, int256 netDecimals)
        internal
        pure
        returns (uint256 result)
    {
        // uint256 scalingFactor = netDecimals > 0 ? 10 ** uint256(netDecimals) : 10 ** uint256(-netDecimals);
        uint256 scalingFactor;
        assembly ("memory-safe") {
            let absDecimals := xor(sub(0, shr(255, netDecimals)), add(sub(0, shr(255, netDecimals)), netDecimals))
            // scalingFactor := 10^|netDecimals|
            scalingFactor := exp(10, absDecimals)
        }

        if (netDecimals > 0) {
            // return (inAmount * uint256(uint64(basePrice)) * scalingFactor) / uint256(uint64(quotePrice));
            assembly ("memory-safe") {
                result := mul(inAmount, basePrice)
                result := mul(result, scalingFactor)
                result := div(result, quotePrice)
            }
        } else {
            // return (inAmount * uint256(uint64(basePrice))) / (uint256(uint64(quotePrice)) * scalingFactor);
            assembly ("memory-safe") {
                result := mul(inAmount, basePrice)
                let denom := mul(quotePrice, scalingFactor)
                result := div(result, denom)
            }
        }
    }

    /// @dev MUST call _sanityCheckPriceStruct beforehand, otherwise over/underflows may occur
    function _getBidAsk(PythStructs.Price memory priceStruct) internal pure returns (int64 bidPrice, int64 askPrice) {
        int64 price = priceStruct.price;
        uint64 conf = priceStruct.conf;
        assembly {
            bidPrice := sub(price, conf)
            askPrice := add(price, conf)
        }
    }

    /// @notice Calculates the net scaling decimals needed when diving base by quote
    /// @dev basePriceExponent - quotePriceExponent + quoteDecimals - baseDecimals
    function _calculateNetDecimals(
        int32 basePriceExponent,
        int32 quotePriceExponent,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (int256 netDecimals) {
        assembly ("memory-safe") {
            netDecimals := sub(basePriceExponent, quotePriceExponent)
            netDecimals := add(netDecimals, quoteDecimals)
            netDecimals := sub(netDecimals, baseDecimals)
        }
    }

    function _sanityCheckPriceStruct(PythStructs.Price memory price) internal pure {
        if (price.price <= 0) {
            revert Errors.Pyth_InvalidPrice(price.price);
        }

        if (price.conf > uint64(type(int64).max) || int64(price.conf) > price.price) {
            revert Errors.Pyth_InvalidConfidenceInterval(price.price, price.conf);
        }

        if (price.expo > 255 || price.expo < -255) {
            revert Errors.Pyth_InvalidExponent(price.expo);
        }
    }
}
