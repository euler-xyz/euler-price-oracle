// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {Governable} from "src/lib/Governable.sol";

contract FeedRegistry is Governable {
    enum FeedType {
        Bytes32,
        Address
    }

    FeedType internal immutable feedType;
    mapping(address base => mapping(address quote => address feed)) private _addressFeeds;
    mapping(address base => mapping(address quote => bytes32 feed)) private _bytes32Feeds;

    event AddressFeedSet(address indexed base, address indexed quote, address indexed feed);
    event Bytes32FeedSet(address indexed base, address indexed quote, bytes32 indexed feed);

    constructor(address _governor, FeedType _feedType) Governable(_governor) {
        feedType = _feedType;
    }

    function setFeeds(address[] calldata bases, address[] calldata quotes, address[] calldata feeds)
        external
        onlyFeedType(FeedType.Address)
        onlyGovernor
    {
        if (bases.length != quotes.length || quotes.length != feeds.length) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        for (uint256 i = 0; i < bases.length; ++i) {
            _setFeed(bases[i], quotes[i], feeds[i]);
        }
    }

    function setFeeds(address[] calldata bases, address[] calldata quotes, bytes32[] calldata feeds)
        external
        onlyFeedType(FeedType.Bytes32)
        onlyGovernor
    {
        if (bases.length != quotes.length || quotes.length != feeds.length) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        for (uint256 i = 0; i < bases.length; ++i) {
            _setFeed(bases[i], quotes[i], feeds[i]);
        }
    }

    function getAddressFeed(address base, address quote) public view onlyFeedType(FeedType.Address) returns (address) {
        return _addressFeeds[base][quote];
    }

    function getBytes32Feed(address base, address quote) public view onlyFeedType(FeedType.Bytes32) returns (bytes32) {
        return _bytes32Feeds[base][quote];
    }

    function _setFeed(address _base, address _quote, address _feed) internal {
        if (_addressFeeds[_base][_quote] != address(0)) revert Errors.PriceOracle_InvalidConfiguration();
        _addressFeeds[_base][_quote] = _feed;
        emit AddressFeedSet(_base, _quote, _feed);
    }

    function _setFeed(address _base, address _quote, bytes32 _feed) internal {
        if (_bytes32Feeds[_base][_quote] != 0) revert Errors.PriceOracle_InvalidConfiguration();
        _bytes32Feeds[_base][_quote] = _feed;
        emit Bytes32FeedSet(_base, _quote, _feed);
    }

    modifier onlyFeedType(FeedType _feedType) {
        if (_feedType != feedType) revert("");
        _;
    }
}
