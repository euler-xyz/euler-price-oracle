// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";

contract ImmutablePythOracle {
    uint256 public constant DEFAULT_MAX_STALENESS = 384; // ~ one epoch

    IPyth public immutable pyth;

    struct PythConfig {
        bytes32 feedId;
        uint8 decimals;
    }

    /// @dev all Pyth crypto feeds are USD-denominated
    mapping(address token => PythConfig) public configs;

    error ConfigDoesNotExist(address token);
    error ConfigAlreadyExists(address token);
    error InvalidPrice(int64 price);
    error InvalidExponent(int32 expo);

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function canQuote(uint256, address base, address quote) external view returns (bool) {
        bytes32 baseFeedId = configs[base].feedId;
        if (baseFeedId == 0) return false;
        bytes32 quoteFeedId = configs[quote].feedId;
        if (quoteFeedId == 0) return false;

        PythStructs.Price memory basePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, DEFAULT_MAX_STALENESS) returns (PythStructs.Price memory _priceStruct)
        {
            basePriceStruct = _priceStruct;
        } catch {
            return false;
        }

        PythStructs.Price memory quotePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, DEFAULT_MAX_STALENESS) returns (PythStructs.Price memory _priceStruct)
        {
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

        PythStructs.Price memory basePriceStruct = pyth.getPriceNoOlderThan(baseFeedId, DEFAULT_MAX_STALENESS);
        PythStructs.Price memory quotePriceStruct = pyth.getPriceNoOlderThan(quoteFeedId, DEFAULT_MAX_STALENESS);

        uint256 basePrice = _priceStructToWad(basePriceStruct); // base/USD
        uint256 quotePrice = _priceStructToWad(quotePriceStruct); // quote/USD

        return inAmount * basePrice / quotePrice;
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
