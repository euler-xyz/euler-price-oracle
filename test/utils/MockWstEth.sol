// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract MockWstEth {
    uint256 internal _tokensPerStEth;
    uint256 internal _stEthPerToken;

    function tokensPerStEth() external view returns (uint256) {
        return _tokensPerStEth;
    }

    function stEthPerToken() external view returns (uint256) {
        return _stEthPerToken;
    }

    function setTokensPerStEth(uint256 x) external {
        _tokensPerStEth = x;
    }

    function setStEthPerToken(uint256 x) external {
        _stEthPerToken = x;
    }
}
