// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Chainlink Push Oracles.
contract ChainlinkOracle is IEOracle {
    /// @dev The address of Wrapped Ether.
    address public immutable base;
    address public immutable quote;
    address public immutable feed;
    uint256 public immutable maxStaleness;
    uint256 public immutable maxDuration;
    bool public immutable inverse;
    uint8 internal immutable baseDecimals;
    uint8 internal immutable quoteDecimals;

    constructor(
        address _base,
        address _quote,
        address _feed,
        uint256 _maxStaleness,
        uint256 _maxDuration,
        bool _inverse
    ) {
        base = _base;
        quote = _quote;
        feed = _feed;
        maxStaleness = _maxStaleness;
        maxDuration = _maxDuration;
        inverse = _inverse;
        baseDecimals = ERC20(_base).decimals();
        quoteDecimals = ERC20(_quote).decimals();
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view virtual returns (uint256) {
        return _getQuote(inAmount, _base, _quote);
    }

    function getQuotes(uint256 inAmount, address _base, address _quote)
        external
        view
        virtual
        returns (uint256, uint256)
    {
        uint256 outAmount = _getQuote(inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function description() external view virtual returns (OracleDescription.Description memory) {
        return OracleDescription.ChainlinkOracle(maxStaleness);
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view returns (uint256) {
        if (_base != base || _quote != quote) revert Errors.EOracle_NotSupported(_base, _quote);

        bytes memory feedCalldata = abi.encodeCall(AggregatorV3Interface.latestRoundData, ());
        (bool success, bytes memory returnData) = feed.staticcall(feedCalldata);
        if (!success) revert Errors.Chainlink_CallReverted(returnData);

        (, int256 answer, uint256 startedAt, uint256 updatedAt,) =
            abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));

        if (answer <= 0) revert Errors.Chainlink_InvalidAnswer(answer);
        if (updatedAt == 0) revert Errors.Chainlink_RoundIncomplete();

        uint256 roundDuration = updatedAt - startedAt;
        if (roundDuration > maxDuration) {
            revert Errors.Chainlink_RoundTooLong(roundDuration, maxDuration);
        }

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > maxStaleness) {
            revert Errors.EOracle_TooStale(staleness, maxStaleness);
        }

        uint256 unitPrice = uint256(answer);
        if (inverse) return (inAmount * 10 ** quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** baseDecimals;
    }
}
