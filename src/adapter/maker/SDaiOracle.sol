// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";

/// @title SDaiOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Maker sDai <-> Dai.
contract SDaiOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "SDaiOracle";
    /// @notice The address of the Dai token.
    /// @dev This address will not change.
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /// @notice The address of the sDai token.
    /// @dev This address will not change.
    address public constant SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    /// @notice Get a quote by querying the exchange rate from the DSR Pot contract.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `SDAI` or `DAI`.
    /// @param quote The token that is the unit of account. Either `DAI` or `SDAI`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == SDAI && quote == DAI) {
            return IERC4626(SDAI).convertToAssets(inAmount);
        } else if (base == DAI && quote == SDAI) {
            return IERC4626(SDAI).convertToShares(inAmount);
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
