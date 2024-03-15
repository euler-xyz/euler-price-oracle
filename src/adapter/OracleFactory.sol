// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {RedstoneCoreFactory} from "src/adapter/redstone/RedstoneCoreFactory.sol";
import {PythFactory} from "src/adapter/pyth/PythFactory.sol";
import {SDAI, DAI, DSR_POT, STETH, WSTETH, RETH, WETH} from "test/utils/EthereumAddresses.sol";

contract OracleFactory {
    mapping(address factory => bool) public adapterFactories;
    mapping(address base => mapping(address quote => address)) public singletonAdapters;

    constructor(address _governor) {
        adapterFactories[address(new RedstoneCoreFactory(_governor))] = true;
        adapterFactories[address(new PythFactory(_governor))] = true;

        _setSingletonAdapter(STETH, WSTETH, address(new LidoOracle(STETH, WSTETH)), true);
        _setSingletonAdapter(DAI, SDAI, address(new SDaiOracle(DAI, SDAI, DSR_POT)), true);
        _setSingletonAdapter(WETH, RETH, address(new RethOracle(WETH, RETH)), true);
    }

    function deploy(address factory, address base, address quote, uint256 maxStaleness) external returns (address) {

    }

    function _setSingletonAdapter(address base, address quote, address oracle, bool populateInverse) internal {
        singletonAdapters[base][quote] = oracle;
        if (populateInverse) singletonAdapters[quote][base] = oracle;
    }
}
