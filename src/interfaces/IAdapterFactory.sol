// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

interface IAdapterFactory {
    function deploy(address base, address quote, bytes calldata extraData) external returns (address);
}
