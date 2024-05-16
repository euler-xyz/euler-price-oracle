import {
    addToCallback,
    CircuitValue,
    getStorage,
    div,
    add,
    mod,
    sub,
} from "@axiom-crypto/client";
  
export interface CircuitInputs {
    blockFrom: CircuitValue;
    blockTo: CircuitValue;
    numObservations: CircuitValue;
    pool: CircuitValue;
}

export const defaultInputs = {
    blockFrom: 19868719,
    blockTo: 19868819,
    numObservations: 5,
    pool: "0x7BeA39867e4169DBe237d55C8242a8f2fcDcc387",
}
  
export const circuitFunction = async (inputs: CircuitInputs) => {
    const prices: CircuitValue[] = [];
    if (inputs.blockFrom > inputs.blockTo) {
        throw Error("Invalid blocks.");
    }

    const blockDelta = sub(inputs.blockTo, inputs.blockFrom);
    if (blockDelta < inputs.numObservations) {
        throw Error("Invalid numObservations.");
    }
    
    const step = div(blockDelta, inputs.numObservations);
    for (let block = inputs.blockFrom; block.value() <= inputs.blockTo.value(); block = add(block, step)) {
        const poolStorage = getStorage(block, inputs.pool);
        const slot0 = await poolStorage.slot(0);
        const slot0Value = slot0.toCircuitValue();
        const sqrtPriceX96 = mod(slot0Value, 2n**160n);
        prices.push(sqrtPriceX96);
    }

    prices.sort();
    const mid = prices.length / 2;
    addToCallback(prices[mid]);
};