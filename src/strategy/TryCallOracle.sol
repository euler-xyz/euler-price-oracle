// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

/// @author totomanov
/// @notice Call IPriceOracle without reverting
/// @dev Uses staticcall. Rejects returndata with invalid length.
abstract contract TryCallOracle {
    /// @notice Try to call `IPriceOracle.getQuote` on `oracle`.
    /// @dev Returns false if the call failed or returned data with the wrong length.
    /// @param oracle The contract to call
    /// @return Whether the call was successful
    /// @return The returned `outAmount` or 0 if the call failed
    function _tryGetQuote(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256 /* outAmount */ )
    {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IPriceOracle.getQuote, (inAmount, base, quote)));

        if (!success || returnData.length != 32) return (false, 0);
        uint256 outAmount = abi.decode(returnData, (uint256));
        return (true, outAmount);
    }

    /// @notice Try to call `IPriceOracle.getQuotes` on `oracle`.
    /// @dev Returns false if the call failed or returned data with the wrong length.
    /// @param oracle The contract to call
    /// @return Whether the call was successful
    /// @return The returned `bidOutAmount` or 0 if the call failed
    /// @return The returned `askOutAmount` or 0 if the call failed
    function _tryGetQuotes(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256, /* bidOutAmount */ uint256 /* askOutAmount */ )
    {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IPriceOracle.getQuotes, (inAmount, base, quote)));

        if (!success || returnData.length != 64) return (false, 0, 0);
        (uint256 bidOutAmount, uint256 askOutAmount) = abi.decode(returnData, (uint256, uint256));
        return (true, bidOutAmount, askOutAmount);
    }
}
