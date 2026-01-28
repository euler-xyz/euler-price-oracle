// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";


interface CorkOracle {
    function isActiveSwapToken(address asset) external view returns (bool);
    function getQuote(address base, address quote, uint256 refAmount, uint256 swapTokensTotal) external view returns (uint256);
}

/// @title CorkCustomRiskManagerOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter that applies custom health score calculation for Cork protected looping.
contract CorkCustomRiskManagerOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "CorkCustomRiskManagerOracle";
    /// @notice The address of the base asset.
    address public immutable refAsset;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice Address of the EVC contract
    address public immutable evc;
    /// @notice Address of the Cork oracle calculating the value of REF collateral
    address public immutable corkOracle;


    constructor(address _base, address _quote, address _evc, address _corkOracle) {
        refAsset = _base;
        quote = _quote;
        evc = _evc;
        corkOracle = _corkOracle;
    }

    function _getQuote(uint256 _encodedAccount, address _base, address _quote) internal view override returns (uint256) {
        require(_base == refAsset && _quote == quote, "direction not supported");
        address account = address(uint160(_encodedAccount));

        uint256 swapTokensTotal;
        uint256 refAmount;
        address[] memory collaterals = IEVC(evc).getCollaterals(account);

        for (uint i; i < collaterals.length; i++) {
            IERC4626 collateral = IERC4626(collaterals[i]);
            address asset = collateral.asset();

            if (CorkOracle(corkOracle).isActiveSwapToken(asset)) {
                swapTokensTotal += collateral.convertToAssets(collateral.balanceOf(account));
            } else if (asset == refAsset) {
                refAmount = collateral.convertToAssets(collateral.balanceOf(account));
            }
        }

        return CorkOracle(corkOracle).getQuote(refAsset, quote, refAmount, swapTokensTotal);
    }
}


contract StubCorkOracle {
    uint constant REF_PRICE_WAD = 1e18;
    address immutable refToken;

    constructor(address _refToken) {
        refToken = _refToken;
    }

    function isActiveSwapToken(address asset) external view returns (bool) {
        return asset != refToken;
    }

    function getQuote(address /* base */, address /* quote */, uint256 refAmount, uint256 swapTokensTotal) external pure returns (uint256) {
        return swapTokensTotal >= refAmount ? refAmount * REF_PRICE_WAD / 1e18 : 0;
    }
}