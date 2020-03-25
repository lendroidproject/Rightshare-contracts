var FRight = artifacts.require("FRight");
var IRight = artifacts.require("IRight");
var RightsDao = artifacts.require("RightsDao");
var NFT = artifacts.require("TradeableERC721Token");

module.exports = function(deployer, accounts) {
  deployer.deploy(FRight);
  deployer.deploy(IRight);
  deployer.deploy(RightsDao);
  deployer.deploy(NFT, "Test Non Fungible Token", "TNFT", "0x944aa1C909BDDEC81F8346165Cc205F24aceE4FD");
};
