// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IPriceOracle {
    error PO_BaseUnsupported();
    error PO_QuoteUnsupported();
    error PO_Overflow();
    error PO_NoPath();

    function name() external view returns (string memory);

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 out);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOut, uint256 askOut);

    function getTick(uint256 inAmount, address base, address quote) external view returns (uint256 tick);
    function getTicks(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidTick, uint256 askTick);
}
