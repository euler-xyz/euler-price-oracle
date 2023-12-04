// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {ICurveRegistry} from "src/adapter/curve/ICurveRegistry.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract CurveLPOracle is BaseOracle {
    ICurveRegistry public immutable metaRegistry;
    ICurveRegistry public immutable stableRegistry;
    IEOracle public immutable forwardOracle;

    struct CurveLPOracleConfig {
        address pool;
        address[] poolTokens;
    }

    mapping(address lpToken => CurveLPOracleConfig) public configs;

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

    function _initializeOracle(bytes memory _data) internal override {
        (address _forwardOracle, address[] memory _lpTokens) = abi.decode(_data, (address, address[]));

        uint256 length = _lpTokens.length;
        for (uint256 i = 0; i < length;) {
            address lpToken = _lpTokens[i];
            address pool = metaRegistry.get_pool_from_lp_token(lpToken);
            if (pool == address(0)) revert Errors.Curve_PoolNotFound(lpToken);

            address[8] memory poolTokens = metaRegistry.get_coins(pool);
            address[] memory poolTokensArr = new address[](8);

            uint256 maxIndex;
            for (uint256 j = 0; j < 8;) {
                address poolToken = poolTokens[j];
                if (poolToken == address(0)) {
                    assembly {
                        // update the length of `poolTokensArr`
                        mstore(poolTokensArr, add(j, 1))
                    }
                    break;
                }
                poolTokensArr[j] = poolToken;
                unchecked {
                    ++j;
                }
            }

            configs[lpToken] = CurveLPOracleConfig({pool: pool, poolTokens: poolTokensArr});

            unchecked {
                ++i;
            }
        }
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        CurveLPOracleConfig memory config = configs[base];
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
