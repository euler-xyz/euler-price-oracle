// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title Denominations
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Conventional representation of non-token assets.
/// @dev Currencies are represented by ISO 4217 numeric codes.
library Denominations {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address internal constant AUD = address(36);
    address internal constant CAD = address(124);
    address internal constant CNY = address(156);
    address internal constant HKD = address(344);
    address internal constant JPY = address(392);
    address internal constant SGD = address(702);
    address internal constant CHF = address(756);
    address internal constant GBP = address(826);
    address internal constant USD = address(840);
    address internal constant XAU = address(959);
    address internal constant XAG = address(961);
    address internal constant EUR = address(978);
    address internal constant NO_CURRENCY = address(999);
}
