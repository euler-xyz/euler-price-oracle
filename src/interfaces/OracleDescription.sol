// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

library OracleDescription {
    enum Algorithm {
        SPOT,
        MEDIAN,
        SMA,
        EMA,
        ARITHMETIC_MEAN_TWAP,
        GEOMETRIC_MEAN_TWAP,
        VWAP
    }

    enum Authority {
        IMMUTABLE,
        GOVERNED
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
        Configuration configuration;
    }
}
