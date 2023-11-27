// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {ICurveRegistry} from "src/adapter/curve/ICurveRegistry.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";

contract CurveLPThroughOracle is BaseOracle, ImmutableAddressArray {
    ICurveRegistry public immutable metaRegistry;
    ICurveRegistry public immutable stableRegistry;
    IPriceOracle public immutable forwardOracle;
    address public immutable lpToken;
    address public immutable pool;

    constructor(
        address _metaRegistry,
        address _stableRegistry,
        address _forwardOracle,
        address _lpToken,
        address[] memory _poolTokens
    ) ImmutableAddressArray(_poolTokens) {
        metaRegistry = ICurveRegistry(_metaRegistry);
        stableRegistry = ICurveRegistry(_stableRegistry);
        forwardOracle = IPriceOracle(_forwardOracle);
        lpToken = _lpToken;

        address _pool = metaRegistry.get_pool_from_lp_token(lpToken);
        if (_pool == address(0)) revert Errors.Curve_PoolNotFound(lpToken);
        pool = _pool;

        address[8] memory poolTokens = metaRegistry.get_coins(pool);

        for (uint256 index = 0; index < 8;) {
            address poolToken = poolTokens[index];
            if (poolToken != _arrayGet(index)) break;
            unchecked {
                ++index;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.CurveLPThroughOracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        if (base != lpToken) revert Errors.PriceOracle_NotSupported(base, quote);

        uint256[8] memory balances = metaRegistry.get_balances(pool);

        uint256 outAmountSum;
        for (uint256 i = 0; i < cardinality; ++i) {
            uint256 tokenInAmount = balances[i];
            address poolToken = _arrayGet(i);
            uint256 outAmount = forwardOracle.getQuote(tokenInAmount, poolToken, quote);
            outAmountSum += outAmount;
        }

        uint256 supply = ERC20(lpToken).totalSupply();

        return inAmount * supply / outAmountSum;
    }
}
