// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Stores oracle descriptions for all `IEOracle` implementations.
/// @dev Collected here to reduce clutter in oracle contracts.
library OracleDescription {
    function ChainlinkOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.VWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Chainlink"
        });
    }

    function UniswapV3Oracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.GEOMETRIC_MEAN_TWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Uniswap V3"
        });
    }

    function RedstoneCoreOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.MEDIAN,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.PER_REQUEST,
            requestModel: RequestModel.PULL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Redstone Core"
        });
    }

    function PythOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.VWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.PER_REQUEST,
            requestModel: RequestModel.PULL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: true}),
            name: "Pyth"
        });
    }

    function SimpleRouter(address governor) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.UNKNOWN,
            authority: Authority.GOVERNED,
            paymentModel: PaymentModel.UNKNOWN,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: governor, supportsBidAskSpread: false}),
            name: "Router"
        });
    }

    function RethOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Reth"
        });
    }

    function LidoOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Lido wstEth"
        });
    }

    function ERC4626Oracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "ERC4626"
        });
    }

    enum Algorithm {
        SPOT,
        MEDIAN,
        SMA,
        EMA,
        ARITHMETIC_MEAN_TWAP,
        GEOMETRIC_MEAN_TWAP,
        VWAP,
        OTHER,
        UNKNOWN
    }

    enum Authority {
        IMMUTABLE,
        GOVERNED,
        OTHER,
        UNKNOWN
    }

    enum PaymentModel {
        FREE,
        SUBSCRIPTION,
        PER_REQUEST,
        OTHER,
        UNKNOWN
    }

    enum RequestModel {
        PUSH,
        PULL,
        SIGNATURE,
        INTERNAL,
        OTHER,
        UNKNOWN
    }

    enum Variant {
        ADAPTER,
        STRATEGY
    }

    struct Configuration {
        uint256 maxStaleness;
        address governor;
        bool supportsBidAskSpread;
    }

    struct Description {
        Algorithm algorithm;
        Authority authority;
        PaymentModel paymentModel;
        RequestModel requestModel;
        Variant variant;
        Configuration configuration;
        string name;
    }
}
