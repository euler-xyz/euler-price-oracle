// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken) external view returns (address);
    function get_balances(address pool) external view returns (uint256[8] memory);
    function get_coins(address pool) external view returns (address[8] memory);
}
