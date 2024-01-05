// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

abstract contract EOracleDescPropTest is Test {
    IEOracle internal oracle;
    OracleDescription.Description internal initialDesc;

    function setUp() public {
        oracle = IEOracle(_deployOracle());
        initialDesc = oracle.description();
    }

    function statefulFuzz_Description_Available() public view {
        oracle.description();
    }

    function statefulFuzz_Description_NameConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(desc.name, initialDesc.name);
    }

    function statefulFuzz_Description_AlgorithmConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.algorithm), uint8(initialDesc.algorithm));
    }

    function statefulFuzz_Description_AuthorityConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.authority), uint8(initialDesc.authority));
    }

    function statefulFuzz_Description_PaymentModelConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.paymentModel), uint8(initialDesc.paymentModel));
    }

    function statefulFuzz_Description_RequestModelConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.requestModel), uint8(initialDesc.requestModel));
    }

    function statefulFuzz_Description_VariantConstant() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.variant), uint8(initialDesc.variant));
    }

    function _deployOracle() internal virtual returns (address);
}
