// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {FeedIdentifier} from "src/lib/FeedIdentifier.sol";
import {Governable} from "src/lib/Governable.sol";

/// @title FeedRegistry
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Stores a list of feed identifiers used when deploying external oracles.
contract FeedRegistry is Governable {
    /// @notice FeedIdentifier configured for base/quote.
    /// @dev Address types are still stored as `bytes32`.
    mapping(address base => mapping(address quote => FeedIdentifier)) public getFeed;

    /// @notice Configure a feed to correspond to base/quote.
    /// @param base The address of the base token.
    /// @param quote The address of the quote token.
    /// @param feed The address of the feed that corresponds to base/quote.
    event FeedSet(address indexed base, address indexed quote, FeedIdentifier indexed feed);

    /// @notice Deploy FeedRegistry.
    /// @param _governor The address of the governor.
    constructor(address _governor) Governable(_governor) {}

    /// @notice Configure the feeds that correspond to base/quote pairs.
    /// @param bases Array of base token addresses.
    /// @param quotes Array of quote token addresses.
    /// @param feeds Array of feed identifiers of type `address`.
    /// @dev Only callable by the governor and if the feed type is `address`.
    function govSetFeeds(address[] memory bases, address[] memory quotes, FeedIdentifier[] memory feeds)
        external
        onlyGovernor
    {
        if (bases.length != quotes.length || quotes.length != feeds.length) {
            revert Errors.FeedRegistry_InvalidConfiguration();
        }

        for (uint256 i = 0; i < bases.length; ++i) {
            address base = bases[i];
            address quote = quotes[i];
            FeedIdentifier feed = feeds[i];

            if (getFeed[base][quote].toBytes32() != 0) revert Errors.FeedRegistry_InvalidConfiguration();
            getFeed[base][quote] = feed;
            emit FeedSet(base, quote, feed);
        }
    }
}
