// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISelfKisser {
    /// @notice Thrown if SelfKisser dead.
    error Dead();

    /// @notice Thrown if oracle not supported.
    /// @param oracle The oracle not supported.
    error OracleNotSupported(address oracle);

    /// @notice Emitted when SelfKisser killed.
    /// @param caller The caller's address.
    event Killed(address indexed caller);

    /// @notice Emitted when support for oracle added.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got added.
    event OracleSupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when support for oracle removed.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got removed.
    event OracleUnsupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when new address kissed on an oracle.
    /// @param caller The caller's address.
    /// @param oracle The oracle on which address `who` got kissed on.
    /// @param who The address that got kissed on oracle `oracle`.
    event SelfKissed(address indexed caller, address indexed oracle, address indexed who);

    // -- User Functionality --

    /// @notice Kisses caller on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss the caller on.
    function selfKiss(address oracle) external;

    /// @notice Kisses address `who` on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss address `who` on.
    /// @param who The address to kiss on oracle `oracle`.
    function selfKiss(address oracle, address who) external;

    // -- View Functionality --

    /// @notice Returns whether oracle `oracle` is supported.
    /// @param oracle The oracle to check whether its supported.
    /// @return True if oracle supported, false otherwise.
    function oracles(address oracle) external view returns (bool);

    /// @notice Returns the list of supported oracles.
    ///
    /// @dev May contain duplicates.
    ///
    /// @return List of supported oracles.
    function oracles() external view returns (address[] memory);

    /// @notice Returns whether SelfKisser is dead.
    /// @return True if SelfKisser dead, false otherwise.
    function dead() external view returns (bool);

    // -- Auth'ed Functionality --

    /// @notice Adds support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser not auth'ed on oracle `oracle`.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to add support for.
    function support(address oracle) external;

    /// @notice Removes support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to remove support for.
    function unsupport(address oracle) external;

    /// @notice Kills the contract.
    /// @dev Only callable by auth'ed address.
    function kill() external;
}
