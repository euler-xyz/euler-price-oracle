// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {hevm} from "test/echidna/IHevm.sol";
import {ConstantOracle} from "src/adapter/constant/ConstantOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";

contract ConstantOracleEchidnaTest {
    address internal constant GOVERNOR = address(0x10000);
    ConstantOracle internal oracle;
    uint256 internal zooz;

    struct Cache {
        bool success;
        bytes returnData;
    }

    mapping(bytes4 => Cache) internal cache;

    struct QuoteArgs {
        uint256 inAmount;
        address base;
        address quote;
        uint256 delta;
    }

    QuoteArgs internal quoteArgs;

    constructor() {
        oracle = new ConstantOracle();
        oracle.initialize(GOVERNOR);
    }

    function setRandomArgs(uint256 inAmount, address base, address quote, uint256 delta) external {
        quoteArgs = QuoteArgs(inAmount, base, quote, delta);
    }

    function govSetConfig(ConstantOracle.ConfigParams memory params) external {
        hevm.prank(GOVERNOR);
        oracle.govSetConfig(params);
    }

    function getQuote(uint256 inAmount, address base, address quote) public returns (uint256) {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IEOracle.getQuote, (inAmount, base, quote)));
        cache[IEOracle.getQuote.selector] = Cache(success, returnData);

        return abi.decode(returnData, (uint256));
    }

    function getQuotes(uint256 inAmount, address base, address quote) public returns (uint256, uint256) {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IEOracle.getQuotes, (inAmount, base, quote)));
        cache[IEOracle.getQuotes.selector] = Cache(success, returnData);

        return abi.decode(returnData, (uint256, uint256));
    }

    function echidna_GetQuote_NeverReturnsZero() public returns (bool) {
        Cache memory c = cache[IEOracle.getQuote.selector];
        if (!c.success) return true;

        uint256 outAmount = abi.decode(c.returnData, (uint256));
        return outAmount > 0;
    }

    function echidna_GetQuotes_NeverReturnsZero() public returns (bool) {
        Cache memory c = cache[IEOracle.getQuotes.selector];
        if (!c.success) return true;

        (uint256 bid, uint256 ask) = abi.decode(c.returnData, (uint256, uint256));
        return bid > 0 && ask > 0;
    }
}
