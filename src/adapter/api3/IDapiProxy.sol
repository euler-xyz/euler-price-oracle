// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IDapiProxy
/// @author api3dao (https://github.com/api3dao/contracts/blob/e9487f14db13edf60a10ba3ece08c9a6c0e7f9a9/contracts/api3-server-v1/proxies/interfaces/IProxy.sol)
/// @notice Partial interface for API3 Data Feeds.
interface IDapiProxy {
    /// @notice Reads the dAPI that this proxy maps to
    function read() external view returns (int224 value, uint32 timestamp);
}
