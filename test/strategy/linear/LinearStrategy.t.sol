// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {LinearStrategy} from "src/strategy/linear/LinearStrategy.sol";

contract LinearStrategyTest is Test {
    uint256 private constant SHUFFLE_ITERATIONS = 10;
    address private immutable oracle0;
    address private immutable oracle1;
    address private immutable oracle2;
    address private immutable oracle3;
    address private immutable oracle4;
    address private immutable oracle5;
    address private immutable oracle6;
    address private immutable oracle7;

    constructor() {
        oracle0 = makeAddr("oracle0");
        oracle1 = makeAddr("oracle1");
        oracle2 = makeAddr("oracle2");
        oracle3 = makeAddr("oracle3");
        oracle4 = makeAddr("oracle4");
        oracle5 = makeAddr("oracle5");
        oracle6 = makeAddr("oracle6");
        oracle7 = makeAddr("oracle7");
    }

    function test_GetQuote_RevertsWhen_AllRevert(uint256 inAmount, address base, address quote) public {
        address[] memory oracles = _oracleArr(3);
        LinearStrategy strategy = new LinearStrategy(oracles);

        _mockGetQuoteRevert(0);
        _mockGetQuoteRevert(1);
        _mockGetQuoteRevert(2);

        vm.expectRevert(Errors.EOracle_NoAnswer.selector);
        strategy.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Integrity_AtLeastOneReturns(
        LibPRNG.PRNG memory prng,
        uint256 inAmount,
        address base,
        address quote,
        uint256 outAmount
    ) public {
        address[] memory oracles = _oracleArr(3);

        _mockGetQuoteRevert(0);
        _mockGetQuoteRevert(1);
        _mockGetQuoteReturn(2, outAmount);
        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            _shuffleOracles(prng, oracles);
            LinearStrategy strategy = new LinearStrategy(oracles);

            uint256 actualOutAmount = strategy.getQuote(inAmount, base, quote);

            assertEq(outAmount, actualOutAmount);
        }
    }

    function test_GetQuote_Integrity_ReturnsFirstAnswer(
        LibPRNG.PRNG memory prng,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        address[] memory oracles = _oracleArr(3);

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            _shuffleOracles(prng, oracles);
            LinearStrategy strategy = new LinearStrategy(oracles);
            _mockGetQuoteReturn(0, uint256(uint160(oracles[0])));
            _mockGetQuoteReturn(1, uint256(uint160(oracles[1])));
            _mockGetQuoteReturn(2, uint256(uint160(oracles[2])));

            uint256 outAmount = strategy.getQuote(inAmount, base, quote);
            assertEq(outAmount, uint256(uint160(oracles[0])));
        }
    }

    function test_GetQuotes_RevertsWhen_AllRevert(uint256 inAmount, address base, address quote) public {
        address[] memory oracles = _oracleArr(3);
        LinearStrategy strategy = new LinearStrategy(oracles);

        _mockGetQuotesRevert(0);
        _mockGetQuotesRevert(1);
        _mockGetQuotesRevert(2);

        vm.expectRevert(Errors.EOracle_NoAnswer.selector);
        strategy.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_Integrity_AtLeastOneReturns(
        LibPRNG.PRNG memory prng,
        uint256 inAmount,
        address base,
        address quote,
        uint256 bidOutAmount,
        uint256 askOutAmount
    ) public {
        address[] memory oracles = _oracleArr(3);

        _mockGetQuotesRevert(0);
        _mockGetQuotesRevert(1);
        _mockGetQuotesReturn(2, bidOutAmount, askOutAmount);
        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            _shuffleOracles(prng, oracles);
            LinearStrategy strategy = new LinearStrategy(oracles);

            (uint256 actualBid, uint256 actualAsk) = strategy.getQuotes(inAmount, base, quote);
            assertEq(bidOutAmount, actualBid);
            assertEq(askOutAmount, actualAsk);
        }
    }

    function test_GetQuotes_Integrity_ReturnsFirstAnswer(
        LibPRNG.PRNG memory prng,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        address[] memory oracles = _oracleArr(3);

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            _shuffleOracles(prng, oracles);
            LinearStrategy strategy = new LinearStrategy(oracles);

            _mockGetQuotesReturn(0, uint256(uint160(oracles[0])), uint256(uint160(oracles[0])) + 1);
            _mockGetQuotesReturn(1, uint256(uint160(oracles[1])), uint256(uint160(oracles[1])) + 1);
            _mockGetQuotesReturn(2, uint256(uint160(oracles[2])), uint256(uint160(oracles[2])) + 1);

            (uint256 bidOutAmount, uint256 askOutAmount) = strategy.getQuotes(inAmount, base, quote);
            assertEq(bidOutAmount, uint256(uint160(oracles[0])));
            assertEq(askOutAmount, uint256(uint160(oracles[0])) + 1);
        }
    }

    function _oracleArr(uint256 length) private view returns (address[] memory) {
        assert(length > 0 && length <= 8);
        address[] memory oracles = new address[](length);

        for (uint256 i = 0; i < 8; ++i) {
            if (i >= length) break;
            oracles[i] = _nthOracle(i);
        }

        return oracles;
    }

    function _mockGetQuoteRevert(uint256 index) private {
        address oracle = _nthOracle(index);
        vm.mockCallRevert(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), "oops");
    }

    function _mockGetQuoteReturn(uint256 index, uint256 outAmount) private {
        address oracle = _nthOracle(index);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(outAmount));
    }

    function _mockGetQuotesRevert(uint256 index) private {
        address oracle = _nthOracle(index);
        vm.mockCallRevert(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), "oops");
    }

    function _mockGetQuotesReturn(uint256 index, uint256 bidOutAmount, uint256 askOutAmount) private {
        address oracle = _nthOracle(index);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), abi.encode(bidOutAmount, askOutAmount));
    }

    function _nthOracle(uint256 index) private view returns (address) {
        if (index == 0) return oracle0;
        if (index == 1) return oracle1;
        if (index == 2) return oracle2;
        if (index == 3) return oracle3;
        if (index == 4) return oracle4;
        if (index == 5) return oracle5;
        if (index == 6) return oracle6;
        if (index == 7) return oracle7;
        revert();
    }

    function _shuffleOracles(LibPRNG.PRNG memory prng, address[] memory oracles) private view {
        uint256[] memory a = _castArr(oracles);
        LibPRNG.shuffle(prng, a);
        oracles = _castArr(a);
    }

    /// @dev taken from @solady/test/Libsort.t.sol
    function _castArr(address[] memory a) private view returns (uint256[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }

    /// @dev taken from @solady/test/Libsort.t.sol
    function _castArr(uint256[] memory a) private view returns (address[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }
}
