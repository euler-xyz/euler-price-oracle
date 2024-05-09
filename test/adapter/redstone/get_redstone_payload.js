const {DataServiceWrapper} = require("@redstone-finance/evm-connector");

async function getPayload() {
  const feed = process.argv[2];
  const redstonePayload = await (new DataServiceWrapper({
    dataServiceId: "redstone-primary-prod",
    dataFeeds: [feed],
    uniqueSignersCount: 3
  }).getBytesDataForAppending());
  console.log(redstonePayload);
}

getPayload();