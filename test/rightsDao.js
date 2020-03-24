const RightsDao = artifacts.require("RightsDao");

contract("RightsDao", (accounts) => {
  it("...should initialize with owner.", async () => {
    const rightsDao = await RightsDao.deployed();

    // Get owner
    const owner = await rightsDao.owner();

    assert.equal(owner, accounts[0], "owner is not deployer.");
  });
});
