// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";

contract EOracleHandler is Test {
    struct ReturnItem {
        bool hasReturned;
        bytes value;
    }

    mapping(bytes4 => ReturnItem) public returnCache;

    address public oracle;
    address internal agent;
    address internal overriddenAgent;
    address private deployer;
    address private constant ALICE = address(0xa11ce);
    address private constant BOB = address(0xb0b);
    address private constant CHARLIE = address(0xc11a611e);

    constructor(address _oracle) {
        oracle = _oracle;
    }

    function initialize(address _governor, uint256 agentSeed) external useAgent(agentSeed) {
        BaseOracle(oracle).initialize(_governor);
    }

    function transferGovernance(address newGovernor, uint256 agentSeed) external useAgent(agentSeed) {
        BaseOracle(oracle).transferGovernance(newGovernor);
    }

    function renounceGovernance(uint256 agentSeed) external useAgent(agentSeed) {
        BaseOracle(oracle).renounceGovernance();
    }

    function governor(uint256 agentSeed) external useAgent(agentSeed) returns (address) {
        return BaseOracle(oracle).governor();
    }

    function initialized(uint256 agentSeed) external useAgent(agentSeed) returns (bool) {
        return BaseOracle(oracle).initialized();
    }

    function finalized(uint256 agentSeed) external useAgent(agentSeed) returns (bool) {
        return BaseOracle(oracle).finalized();
    }

    function governed(uint256 agentSeed) external useAgent(agentSeed) returns (bool) {
        return BaseOracle(oracle).governed();
    }

    function getQuote(uint256 agentSeed, uint256 inAmount, address base, address quote)
        external
        useAgent(agentSeed)
        returns (uint256)
    {
        uint256 outAmount = IEOracle(oracle).getQuote(inAmount, base, quote);
        _cacheReturn(abi.encode(outAmount));
        return outAmount;
    }

    function getQuotes(uint256 agentSeed, uint256 inAmount, address base, address quote)
        external
        useAgent(agentSeed)
        returns (uint256, uint256)
    {
        (uint256 bid, uint256 ask) = IEOracle(oracle).getQuotes(inAmount, base, quote);
        _cacheReturn(abi.encode(bid, ask));
        return (bid, ask);
    }

    function setNextAgent(address nextAgent) external {
        overriddenAgent = nextAgent;
    }

    function _cacheReturn(bytes memory data) internal {
        returnCache[msg.sig] = ReturnItem(true, data);
    }

    function _agents() internal view returns (address[] memory) {
        address[] memory a = new address[](6);
        a[0] = oracle;
        a[1] = deployer;
        a[2] = BaseOracle(oracle).governor();
        a[3] = ALICE;
        a[4] = BOB;
        a[5] = CHARLIE;
        return a;
    }

    modifier useAgent(uint256 agentSeed) {
        if (overriddenAgent != address(0)) {
            agent = overriddenAgent;
        } else {
            address[] memory agents = _agents();
            agent = agents[bound(agentSeed, 0, agents.length - 1)];
        }

        vm.startPrank(agent);
        _;
        vm.stopPrank();
        overriddenAgent = address(0);
    }
}
