var FRight = artifacts.require("FRight");
var IRight = artifacts.require("IRight");
var RightsDao = artifacts.require("RightsDao");
var NFT = artifacts.require("TradeableERC721Token");

module.exports = function(deployer, accounts) {
  deployer.deploy(FRight);
  deployer.deploy(IRight);
  deployer.deploy(RightsDao);
  deployer.deploy(NFT, "Test Non Fungible Token", "TNFT", "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7");
};
