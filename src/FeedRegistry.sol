// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {Governable} from "src/lib/Governable.sol";

contract FeedRegistry is Governable {
    mapping(address base => mapping(address quote => bytes32 feedId)) public feeds;

    event FeedSet(address indexed base, address indexed quote, bytes32 indexed feedId);

    constructor(address _governor) Governable(_governor) {}

    function setFeeds(address[] calldata bases, address[] calldata quotes, bytes32[] calldata feedIds)
        external
        onlyGovernor
    {
        if (bases.length != quotes.length || quotes.length != feedIds.length) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        for (uint256 i = 0; i < bases.length; ++i) {
            _setFeed(bases[i], quotes[i], feedIds[i]);
        }
    }

    function _setFeed(address _base, address _quote, bytes32 _feedId) internal {
        if (feeds[_base][_quote] != 0) revert Errors.PriceOracle_InvalidConfiguration();
        feeds[_base][_quote] = _feedId;
        emit FeedSet(_base, _quote, _feedId);
    }
}
