// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

contract ImmutablePythOracle {
    IPyth public immutable pyth;
    uint256 public immutable maxStaleness;

    struct PythConfig {
        bytes32 feedId;
        uint8 decimals;
    }

    /// @dev all Pyth crypto feeds are USD-denominated
    mapping(address token => PythConfig) public configs;

    error ArityMismatch(uint256 arityA, uint256 arityB);
    error ConfigAlreadyExists(address token);
    error ConfigDoesNotExist(address token);
    error InvalidExponent(int32 expo);
    error InvalidPrice(int64 price);

    constructor(address _pyth, uint256 _maxStaleness, address[] memory tokens, bytes32[] memory feedIds) {
        pyth = IPyth(_pyth);
        maxStaleness = _maxStaleness;

        if (tokens.length != feedIds.length) revert ArityMismatch(tokens.length, feedIds.length);
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length;) {
            _initConfig(tokens[i], feedIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function canQuote(uint256, address base, address quote) external view returns (bool) {
        bytes32 baseFeedId = configs[base].feedId;
        if (baseFeedId == 0) return false;
        bytes32 quoteFeedId = configs[quote].feedId;
        if (quoteFeedId == 0) return false;

        PythStructs.Price memory basePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, maxStaleness) returns (PythStructs.Price memory _priceStruct) {
            basePriceStruct = _priceStruct;
        } catch {
            return false;
        }

        PythStructs.Price memory quotePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, maxStaleness) returns (PythStructs.Price memory _priceStruct) {
            quotePriceStruct = _priceStruct;
        } catch {
            return false;
        }

        // todo: more checks
        return true;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        bytes32 baseFeedId = configs[base].feedId;
        if (baseFeedId == 0) revert ConfigDoesNotExist(base);
        bytes32 quoteFeedId = configs[quote].feedId;
        if (quoteFeedId == 0) revert ConfigDoesNotExist(quote);

        PythStructs.Price memory basePriceStruct = pyth.getPriceNoOlderThan(baseFeedId, maxStaleness);
        PythStructs.Price memory quotePriceStruct = pyth.getPriceNoOlderThan(quoteFeedId, maxStaleness);

        uint256 basePrice = _priceStructToWad(basePriceStruct); // base/USD
        uint256 quotePrice = _priceStructToWad(quotePriceStruct); // quote/USD

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;
        // todo: more efficient and precise calc if this scaling is integrated in _priceStructToWad
        return (inAmount * basePrice * 10 ** quoteDecimals) / (quotePrice * 10 ** baseDecimals);
    }

    function _initConfig(address token, bytes32 feedId) internal {
        uint8 decimals = ERC20(token).decimals();
        configs[token] = PythConfig(feedId, decimals);
    }

    function _priceStructToWad(PythStructs.Price memory price) internal pure returns (uint256) {
        if (price.price <= 0) {
            revert InvalidPrice(price.price);
        }

        if (price.expo > 0 || price.expo < -255) {
            revert InvalidExponent(price.expo);
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));
        uint8 targetDecimals = 18;

        if (targetDecimals >= priceDecimals) {
            return uint256(uint64(price.price)) * 10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return uint256(uint64(price.price)) / 10 ** uint32(priceDecimals - targetDecimals);
        }
    }
}
