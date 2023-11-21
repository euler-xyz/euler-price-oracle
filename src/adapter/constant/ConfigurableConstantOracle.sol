// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract ConfigurableConstantOracle {
    uint256 public constant PRECISION_DECIMALS = 27;

    mapping(address base => mapping(address quote => uint256 rate)) public configs;

    error AlreadyConfigured(address base, address quote);
    error ArityMismatch(uint256 arityA, uint256 arityB, uint256 arityC);
    error NotConfigured(address base, address quote);

    constructor(address[] memory bases, address[] memory quotes, uint256[] memory rates) {
        if (bases.length != quotes.length || quotes.length != rates.length) {
            revert ArityMismatch(bases.length, quotes.length, rates.length);
        }

        uint256 length = bases.length;
        for (uint256 i = 0; i < length;) {
            _initConfig(bases[i], quotes[i], rates[i]);
            unchecked {
                ++i;
            }
        }
    }

    function canQuote(uint256, address base, address quote) external view returns (bool) {
        return configs[base][quote] != 0;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        uint256 rate = _getOrRevertConfig(base, quote);
        uint256 price = inAmount * rate / 10 ** PRECISION_DECIMALS;
        return price;
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 rate = _getOrRevertConfig(base, quote);
        uint256 price = inAmount * rate / 10 ** PRECISION_DECIMALS;
        return (price, price);
    }

    function _initConfig(address base, address quote, uint256 rate) internal {
        if (configs[base][quote] != 0) revert AlreadyConfigured(base, quote);
        configs[base][quote] = rate;
    }

    function _getOrRevertConfig(address base, address quote) internal view returns (uint256) {
        uint256 rate = configs[base][quote];
        if (rate == 0) revert NotConfigured(base, quote);
        return rate;
    }
}
