// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @author totomanov
/// @notice Stores oracle descriptions for all `IPriceOracle` implementations.
/// @dev Collected here to reduce clutter in oracle contracts and to make editing easier.
library OracleDescription {
    function ConfigurableConstantOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Constant",
            children: new address[](0)
        });
    }

    function ConstantBackoffLinearStrategy() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.OTHER,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Linear",
            children: new address[](0)
        });
    }

    function ConstantOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Constant",
            children: new address[](0)
        });
    }

    function CTokenV2Oracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Compound V2",
            children: new address[](0)
        });
    }

    function CurveLPThroughOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Curve LP Token",
            children: new address[](0)
        });
    }

    function GovernedChainlinkOracle(uint256 maxStaleness, address governor)
        internal
        pure
        returns (Description memory)
    {
        return Description({
            algorithm: Algorithm.VWAP,
            authority: Authority.GOVERNED,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: governor, supportsBidAskSpread: false}),
            name: "Chainlink",
            children: new address[](0)
        });
    }

    function GovernedUniswapV3Oracle(address governor) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.GEOMETRIC_MEAN_TWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: governor, supportsBidAskSpread: false}),
            name: "Uniswap V3",
            children: new address[](0)
        });
    }

    function ImmutableChainlinkOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.VWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Chainlink",
            children: new address[](0)
        });
    }

    function ImmutableChronicleOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.MEDIAN,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.SUBSCRIPTION,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Chronicle",
            children: new address[](0)
        });
    }

    function ImmutablePythOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: true}),
            name: "Pyth",
            children: new address[](0)
        });
    }

    function ImmutablePythEMAOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.EMA,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: true}),
            name: "Pyth",
            children: new address[](0)
        });
    }

    function ImmutableRouter() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Router",
            children: new address[](0)
        });
    }

    function ImmutableUniswapV3Oracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.GEOMETRIC_MEAN_TWAP,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Uniswap V3",
            children: new address[](0)
        });
    }

    function LinearStrategy() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.OTHER,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Linear",
            children: new address[](0)
        });
    }

    function SimpleAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_MAX,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Aggregator (Simple)",
            children: new address[](0)
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
            name: "Router",
            children: new address[](0)
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
            name: "Reth",
            children: new address[](0)
        });
    }

    function TellorSpotOracle(uint256 maxStaleness) internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: maxStaleness, governor: address(0), supportsBidAskSpread: false}),
            name: "Tellor",
            children: new address[](0)
        });
    }

    function YearnV2VaultOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.PUSH,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Yearn V2 Vault",
            children: new address[](0)
        });
    }

    function WeightedAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_WEIGHTED,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            name: "Aggregator (Weighted)",
            children: new address[](0)
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
            name: "Lido wstEth",
            children: new address[](0)
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
        address[] children;
    }
}
