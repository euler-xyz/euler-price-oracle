// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {ICurveRegistry} from "src/adapter/curve/ICurveRegistry.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract CurveLPOracle is BaseOracle {
    struct Config {
        address pool;
        address[] poolTokens;
    }

    ICurveRegistry public immutable metaRegistry;
    ICurveRegistry public immutable stableRegistry;
    IEOracle public immutable forwardOracle;

    mapping(address lpToken => Config) public configs;

    constructor(
        address _metaRegistry,
        address _stableRegistry,
        address _forwardOracle,
        address[] memory _initialLpTokens
    ) {
        metaRegistry = ICurveRegistry(_metaRegistry);
        stableRegistry = ICurveRegistry(_stableRegistry);
        forwardOracle = IEOracle(_forwardOracle);

        uint256 length = _initialLpTokens.length;
        for (uint256 i = 0; i < length;) {
            address lpToken = _initialLpTokens[i];
            _setConfig(lpToken);

            unchecked {
                ++i;
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
        return OracleDescription.CurveLPOracle();
    }

    function _setConfig(address lpToken) private {
        address pool = metaRegistry.get_pool_from_lp_token(lpToken);
        if (pool == address(0)) revert Errors.Curve_PoolNotFound(lpToken);

        address[8] memory poolTokens = metaRegistry.get_coins(pool);
        address[] memory poolTokensArr = new address[](8);

        uint256 maxIndex;
        for (uint256 i = 0; i < 8;) {
            address poolToken = poolTokens[i];
            if (poolToken == address(0)) {
                assembly {
                    // update the length of `poolTokensArr`
                    mstore(poolTokensArr, add(i, 1))
                }
                break;
            }
            poolTokensArr[i] = poolToken;
            unchecked {
                ++i;
            }
        }

        configs[lpToken] = Config(pool, poolTokensArr);
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        Config memory config = configs[base];
        if (config.pool == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        // TODO: inverse support

        uint256[8] memory balances = metaRegistry.get_balances(config.pool);

        uint256 outAmountSum;
        uint256 numPoolTokens = config.poolTokens.length;
        for (uint256 i = 0; i < numPoolTokens;) {
            uint256 tokenInAmount = balances[i];
            address poolToken = config.poolTokens[i];
            uint256 outAmount = forwardOracle.getQuote(tokenInAmount, poolToken, quote);
            outAmountSum += outAmount;

            unchecked {
                ++i;
            }
        }

        uint256 supply = ERC20(base).totalSupply();

        return inAmount * supply / outAmountSum;
    }
}
