// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {ICurveRegistry} from "src/adapter/curve/ICurveRegistry.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";

contract CurveLPThroughOracle is ImmutableAddressArray, IOracle {
    ICurveRegistry public immutable metaRegistry;
    ICurveRegistry public immutable stableRegistry;
    IOracle public immutable forwardOracle;
    address public immutable lpToken;
    address public immutable pool;

    error NotSupported(address base, address quote);
    error NoPoolFound(address lpToken);

    constructor(
        address _metaRegistry,
        address _stableRegistry,
        address _forwardOracle,
        address _lpToken,
        address[] memory _poolTokens
    ) ImmutableAddressArray(_poolTokens) {
        metaRegistry = ICurveRegistry(_metaRegistry);
        stableRegistry = ICurveRegistry(_stableRegistry);
        forwardOracle = IOracle(_forwardOracle);
        lpToken = _lpToken;

        address _pool = metaRegistry.get_pool_from_lp_token(lpToken);
        if (_pool == address(0)) revert NoPoolFound(lpToken);
        pool = _pool;

        address[8] memory poolTokens = metaRegistry.get_coins(pool);

        for (uint256 index = 0; index < 8;) {
            address poolToken = poolTokens[index];
            if (poolToken != _get(index)) break;
            unchecked {
                ++index;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) public view override returns (uint256) {
        if (base != lpToken) revert NotSupported(base, quote);

        uint256[8] memory balances = metaRegistry.get_balances(pool);

        uint256 outAmountSum;
        for (uint256 i = 0; i < cardinality; ++i) {
            uint256 tokenInAmount = balances[i];
            address poolToken = _get(i);
            uint256 outAmount = forwardOracle.getQuote(tokenInAmount, poolToken, quote);
            outAmountSum += outAmount;
        }

        uint256 supply = ERC20(lpToken).totalSupply();

        return inAmount * supply / outAmountSum;
    }

    function getQuotes(uint256 inAmount, address base, address quote) public view override returns (uint256, uint256) {
        uint256 outAmount = getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }
}
