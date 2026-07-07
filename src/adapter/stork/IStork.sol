pragma solidity ^0.8.0;

interface IStorkTemporalNumericValueUnsafeGetter {
    function getTemporalNumericValueUnsafeV1(
        bytes32 id
    ) external view returns (StorkStructs.TemporalNumericValue memory value);
}

contract StorkStructs {
    struct TemporalNumericValue {
        uint64 timestampNs; // nanosecond level precision timestamp of latest publisher update in batch
        int192 quantizedValue;
    }
}
