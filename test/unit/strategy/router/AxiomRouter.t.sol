// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {EFactory} from "@euler-vault/EFactory/EFactory.sol";
import {AxiomRouter} from "src/strategy/router/AxiomRouter.sol";

contract StubERC4626 {
    address public asset;
    uint256 private rate;

    constructor(address _asset, uint256 _rate) {
        asset = _asset;
        rate = _rate;
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return shares * rate / 1e18;
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return assets * 1e18 / rate;
    }
}

contract StubEOracle {
    mapping(address => mapping(address => uint256)) prices;

    function setPrice(address base, address quote, uint256 price) external {
        prices[base][quote] = price;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return inAmount * prices[base][quote] / 1e18;
    }
}

contract StubEFactory {
    mapping(address => bool) public isProxy;

    function setIsProxy(address x, bool y) public {
        isProxy[x] = y;
    }
}

contract AxiomRouterTest is Test {
    address GOVERNOR = makeAddr("GOVERNOR");
    StubEFactory eFactory;
    AxiomRouter router;

    address WETH = makeAddr("WETH");
    address eWETH;
    address eeWETH;

    address DAI = makeAddr("DAI");
    address eDAI;
    address eeDAI;

    StubEOracle eOracle;

    function setUp() public {
        eFactory = new StubEFactory();
        router = new AxiomRouter(address(eFactory));
        router.initialize(GOVERNOR);

        eWETH = address(new StubERC4626(WETH, 1.2e18));
        eFactory.setIsProxy(eWETH, true);

        eeWETH = address(new StubERC4626(eWETH, 1.1e18));
        eFactory.setIsProxy(eeWETH, true);

        eDAI = address(new StubERC4626(DAI, 1.5e18));
        eFactory.setIsProxy(eDAI, true);

        eeDAI = address(new StubERC4626(eDAI, 1.25e18));
        eFactory.setIsProxy(eeDAI, true);

        eOracle = new StubEOracle();
        eOracle.setPrice(WETH, DAI, 2500e18);
        eOracle.setPrice(DAI, WETH, 0.0004e18);

        vm.prank(GOVERNOR);
        router.govSetConfig(WETH, DAI, address(eOracle));
        vm.prank(GOVERNOR);
        router.govSetConfig(DAI, WETH, address(eOracle));
    }

    function test_GetQuote_Nested() public {
        console2.log("WETH/DAI=%s", router.getQuote(1e18, WETH, DAI));
        console2.log("eWETH/DAI=%s", router.getQuote(1e18, eWETH, DAI));
        console2.log("eeWETH/DAI=%s", router.getQuote(1e18, eeWETH, DAI));

        console2.log("WETH/eDAI=%s", router.getQuote(1e18, WETH, eDAI));
        console2.log("WETH/eeDAI=%s", router.getQuote(1e18, WETH, eeDAI));

        console2.log("eWETH/eDAI=%s", router.getQuote(1e18, eWETH, eDAI));
        console2.log("eeWETH/eeDAI=%s", router.getQuote(1e18, eeWETH, eeDAI));
    }

    function test_GetQuote_InverseProperty(uint256 inAmount, uint256 i, uint256 j) public {
        address[] memory tokens = new address[](6);
        tokens[0] = WETH;
        tokens[1] = eWETH;
        tokens[2] = eeWETH;
        tokens[3] = DAI;
        tokens[4] = eDAI;
        tokens[5] = eeDAI;

        inAmount = bound(inAmount, 1, type(uint128).max);
        i = bound(i, 0, tokens.length - 2);
        j = bound(j, i + 1, tokens.length - 1);

        uint256 outAmount_ij = router.getQuote(inAmount, tokens[i], tokens[j]);
        uint256 outAmount_ij_ji = router.getQuote(outAmount_ij, tokens[j], tokens[i]);

        assertApproxEqAbs(outAmount_ij_ji, inAmount, 10);
    }

    function test_GetQuote_ClosedLoopProperty(uint256 inAmount, LibPRNG.PRNG memory prng) public {
        address[] memory tokens = new address[](6);
        tokens[0] = WETH;
        tokens[1] = eWETH;
        tokens[2] = eeWETH;
        tokens[3] = DAI;
        tokens[4] = eDAI;
        tokens[5] = eeDAI;

        _shuffle(prng, tokens);

        inAmount = bound(inAmount, 1e18, type(uint128).max);

        uint256 initInAmount = inAmount;

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 j = (i + 1) % tokens.length;
            inAmount = router.getQuote(inAmount, tokens[i], tokens[j]);
        }
        assertApproxEqRel(initInAmount, inAmount, 0.00000001e18);
    }

    function _shuffle(LibPRNG.PRNG memory prng, address[] memory a) private {
        uint256[] memory a_;
        assembly {
            a_ := a
        }
        LibPRNG.shuffle(prng, a_);
    }
}
