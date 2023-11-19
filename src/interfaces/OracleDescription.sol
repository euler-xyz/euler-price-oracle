// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

enum Authority {
    PERMISSIONLESS,
    GOVERNED
}

enum Algorithm {
    SPOT,
    MEDIAN,
    SMA,
    EMA,
    ARITHMETIC_MEAN_TWAP,
    GEOMETRIC_MEAN_TWAP,
    VWAP
}

enum PaymentModel {
    FREE,
    SUBSCRIPTION,
    PER_REQUEST
}

enum RequestModel {
    PUSH,
    PULL,
    SIGNATURE
}

struct UpdateConditions {
    uint256 deviationThreshold;
    uint256 timeSinceLastUpdate;
}

struct ConsumerSettings {
    uint256 maxStaleness;
    uint256 maxPrice;
}

struct OracleDescription {
    Authority authority;
    Algorithm algorithm;
    PaymentModel paymentModel;
    RequestModel requestModel;
    UpdateConditions updateConditions;
    ConsumerSettings consumerSettings;
    bool supportsBidAskSpread;
}
