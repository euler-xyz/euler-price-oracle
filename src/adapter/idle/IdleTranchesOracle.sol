// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {IIdleCDO} from "./IIdleCDO.sol";
import {IIdleTranche} from "./IIdleTranche.sol";

/// @title IdleTranchesOracle
/// @custom:security-contact security@euler.xyz
/// @author Idle DAO (https://idle.finance)
/// @notice Adapter for pricing Idle tranches to their respective underlying.
/// @dev Do not use this oracle for pricing a borrowable Idle tranche.
contract IdleTranchesOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "IdleTranchesOracle";
    /// @notice The address of the CDO contract.
    address public immutable cdo;
    /// @notice The address of the tranche contract.
    address public immutable tranche;
    /// @notice The address of the tranche's asset.
    address public immutable underlying;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy an IdleTranchesOracle.
    /// @param _cdo The address of the Idle CDO contract.
    /// @param _tranche The address of a tranche corresponding to the CDO.
    constructor(address _cdo, address _tranche) {
        if (IIdleTranche(_tranche).minter() != _cdo) revert Errors.PriceOracle_InvalidConfiguration();

        cdo = _cdo;
        tranche = _tranche;
        underlying = IIdleCDO(_cdo).token();
        uint8 trancheDecimals = _getDecimals(_tranche);
        uint8 underlyingDecimals = _getDecimals(underlying);
        // IdleCDO returns a value with `underlyings` decimals.
        scale = ScaleUtils.calcScale(trancheDecimals, underlyingDecimals, underlyingDecimals);
    }

    /// @notice Get the quote from the IdleCDO contract.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, tranche, _quote, underlying);
        uint256 rate = IIdleCDO(cdo).virtualPrice(tranche);
        if (rate == 0) revert Errors.PriceOracle_InvalidAnswer();
        return ScaleUtils.calcOutAmount(inAmount, rate, scale, inverse);
    }
}
