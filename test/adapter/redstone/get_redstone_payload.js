const {DataServiceWrapper} = require("@redstone-finance/evm-connector");
const {getSignersForDataServiceId} = require("@redstone-finance/sdk");

async function getPayload() {
  const feed = process.argv[2];
  const wrapper = new DataServiceWrapper({
    dataServiceId: "redstone-primary-prod",
    dataPackagesIds: [feed],
    uniqueSignersCount: 3,
    authorizedSigners: getSignersForDataServiceId("redstone-primary-prod")
  });
  const redstonePayload = await wrapper.getBytesDataForAppending();
  console.log(redstonePayload);
}

getPayload();
