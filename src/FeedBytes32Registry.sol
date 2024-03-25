// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {Governable} from "src/lib/Governable.sol";

contract FeedBytes32Registry is Governable {
    mapping(address base => mapping(address quote => bytes32 feed)) public getFeed;

    event FeedSet(address indexed base, address indexed quote, bytes32 indexed feed);

    constructor(address _governor) Governable(_governor) {}

    function setFeeds(address[] calldata bases, address[] calldata quotes, bytes32[] calldata feeds)
        external
        onlyGovernor
    {
        if (bases.length != quotes.length || quotes.length != feeds.length) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        for (uint256 i = 0; i < bases.length; ++i) {
            _setFeed(bases[i], quotes[i], feeds[i]);
        }
    }

    function _setFeed(address _base, address _quote, bytes32 _feed) internal {
        if (getFeed[_base][_quote] != 0) revert Errors.PriceOracle_InvalidConfiguration();
        getFeed[_base][_quote] = _feed;
        emit FeedSet(_base, _quote, _feed);
    }
}
