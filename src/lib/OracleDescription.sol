// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Stores oracle descriptions for all `IEOracle` implementations.
/// @dev Collected here to reduce clutter in oracle contracts.
library OracleDescription {
    function ChainlinkOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.VWAP,
            authority: Authority.GOVERNED,
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
            authority: Authority.GOVERNED,
            paymentModel: PaymentModel.PER_REQUEST,
            requestModel: RequestModel.PULL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Linear"
        });
    }

    function SimpleRouter() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
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

    function WstEthOracle() internal pure returns (Description memory) {
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

    enum Algorithm {
        SPOT,
        MEDIAN,
        SMA,
        EMA,
        ARITHMETIC_MEAN_TWAP,
        GEOMETRIC_MEAN_TWAP,
        VWAP,
        AGGREGATE_MAX,
        AGGREGATE_MEAN,
        AGGREGATE_MEDIAN,
        AGGREGATE_MIN,
        AGGREGATE_WEIGHTED,
        OTHER
    }

    enum Authority {
        IMMUTABLE,
        GOVERNED,
        OTHER
    }

    enum PaymentModel {
        FREE,
        SUBSCRIPTION,
        PER_REQUEST,
        OTHER
    }

    enum RequestModel {
        PUSH,
        PULL,
        SIGNATURE,
        INTERNAL,
        OTHER
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
