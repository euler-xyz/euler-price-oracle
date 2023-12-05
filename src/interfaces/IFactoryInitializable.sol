// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

interface IFactoryInitializable {
    function initialize(address _governor) external;
}
