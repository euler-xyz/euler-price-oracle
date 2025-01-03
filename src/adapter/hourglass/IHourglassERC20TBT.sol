// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHourglassERC20TBT {
    function depositor() external view returns (address);
    function initialize(string calldata _name, string calldata _symbol, uint8 __decimals) external;
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}
