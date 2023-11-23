// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

library OracleDescription {
    function ConfigurableConstantOracle() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
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
            children: new address[](0)
        });
    }

    function FallbackRouter() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.SPOT,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.ADAPTER,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
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
            children: new address[](0)
        });
    }

    function MaxAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_MAX,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            children: new address[](0)
        });
    }

    function MedianAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_MEDIAN,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            children: new address[](0)
        });
    }

    function MeanAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_MEAN,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
            children: new address[](0)
        });
    }

    function MinAggregator() internal pure returns (Description memory) {
        return Description({
            algorithm: Algorithm.AGGREGATE_MIN,
            authority: Authority.IMMUTABLE,
            paymentModel: PaymentModel.FREE,
            requestModel: RequestModel.INTERNAL,
            variant: Variant.STRATEGY,
            configuration: Configuration({maxStaleness: 0, governor: address(0), supportsBidAskSpread: false}),
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
        address[] children;
    }
}
