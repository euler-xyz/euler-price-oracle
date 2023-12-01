// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BeaconProxy} from "./BeaconProxy.sol";
import {MetaProxyFactory} from "./MetaProxyFactory.sol";

interface IComponent {
    function initialize() external;
}

abstract contract GenericFactory is MetaProxyFactory {
    // Constants

    uint256 constant REENTRANCYLOCK__UNLOCKED = 1;
    uint256 constant REENTRANCYLOCK__LOCKED = 2;

    // State

    struct ProxyConfig {
        bool upgradeable;
        address implementation; // may be an out-of-date value, if upgradeable
        bytes trailingData;
    }

    uint256 private reentrancyLock;
    address private upgradeAdmin;
    address private currentImplementation;

    mapping(address proxy => ProxyConfig) public proxyLookup;
    address[] public proxyList;

    // Events

    event Genesis();

    event ProxyCreated(address indexed proxy, bool upgradeable, address implementation, bytes trailingData);

    event SetImplementation(address indexed newImplementation);
    event SetUpgradeAdmin(address indexed newUpgradeAdmin);

    // Errors

    error E_Reentrancy();
    error E_Unauthorized();
    error E_Implementation();
    error E_BadAddress();

    // Modifiers

    modifier nonReentrant() {
        if (reentrancyLock != REENTRANCYLOCK__UNLOCKED) revert E_Reentrancy();

        reentrancyLock = REENTRANCYLOCK__LOCKED;
        _;
        reentrancyLock = REENTRANCYLOCK__UNLOCKED;
    }

    modifier adminOnly() {
        if (msg.sender != upgradeAdmin) revert E_Unauthorized();
        _;
    }

    constructor(address admin) {
        emit Genesis();

        reentrancyLock = REENTRANCYLOCK__UNLOCKED;

        upgradeAdmin = admin;

        emit SetUpgradeAdmin(admin);
    }

    function createProxy(bool upgradeable, bytes memory trailingData) internal returns (address) {
        if (currentImplementation == address(0)) revert E_Implementation();

        address proxy;

        if (upgradeable) {
            proxy = address(new BeaconProxy(trailingData));
        } else {
            proxy = _metaProxyFromBytes(currentImplementation, trailingData);
        }

        IComponent(proxy).initialize();

        proxyLookup[proxy] =
            ProxyConfig({upgradeable: upgradeable, implementation: currentImplementation, trailingData: trailingData});

        proxyList.push(proxy);

        emit ProxyCreated(proxy, upgradeable, currentImplementation, trailingData);

        return proxy;
    }

    // EVault beacon and implementation upgrade

    function implementation() external view returns (address) {
        return currentImplementation;
    }

    function setImplementation(address newImplementation) external nonReentrant adminOnly {
        if (newImplementation == address(0)) revert E_BadAddress();
        currentImplementation = newImplementation;
        emit SetImplementation(newImplementation);
    }

    // Admin roles

    function setUpgradeAdmin(address newUpgradeAdmin) external nonReentrant adminOnly {
        if (newUpgradeAdmin == address(0)) revert E_BadAddress();
        upgradeAdmin = newUpgradeAdmin;
        emit SetUpgradeAdmin(newUpgradeAdmin);
    }

    function getUpgradeAdmin() external view returns (address) {
        return upgradeAdmin;
    }
}
