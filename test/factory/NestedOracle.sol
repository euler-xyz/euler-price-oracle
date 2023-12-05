// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IEOracle} from "src/interfaces/IEOracle.sol";

contract ParentOracle {
    function initialize(address) external {}

    function scalar() public pure virtual returns (uint256) {
        return 3;
    }

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        (address base, address child) = UNPACK();
        return scalar() * IEOracle(child).getQuote(_inAmount, _base, _quote);
    }

    function UNPACK() internal pure returns (address base, address child) {
        assembly {
            base := shr(96, calldataload(sub(calldatasize(), 72)))
            child := shr(96, calldataload(sub(calldatasize(), 52)))
        }
    }
}

contract ParentOracle2 {
    function initialize(address) external {}

    function scalar() public pure virtual returns (uint256) {
        return 5;
    }

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        (address base, address child) = UNPACK();
        return scalar() * IEOracle(child).getQuote(_inAmount, _base, _quote);
    }

    function UNPACK() internal pure returns (address base, address child) {
        assembly {
            base := shr(96, calldataload(sub(calldatasize(), 72)))
            child := shr(96, calldataload(sub(calldatasize(), 52)))
        }
    }
}

contract ChildOracle {
    function initialize(address) external {}

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        (address base, uint160 outAmount) = UNPACK();
        return uint256(outAmount);
    }

    function UNPACK() internal pure returns (address base, uint160 outAmount) {
        assembly {
            base := shr(96, calldataload(sub(calldatasize(), 72)))
            outAmount := shr(96, calldataload(sub(calldatasize(), 52)))
        }
    }
}
