const { expectRevert } = require('@openzeppelin/test-helpers')

contract("TradeableERC721Token", (accounts) => {

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
  const TradeableERC721Token = artifacts.require("TradeableERC721Token")
  const OwnableDelegateProxy = artifacts.require("OwnableDelegateProxy")
  const ProxyRegistry = artifacts.require("ProxyRegistry")
  const owner = accounts[0]

  let operator, token, proxy, proxyRegistry

  describe('when ProxyRegistryAddress is ZERO_ADDRESS', () => {

    beforeEach(async () => {
      token = await TradeableERC721Token.new("Mock Non Fungible Token", "MNFT", ZERO_ADDRESS)
      operator = accounts[1]
    })

    describe('constructor', () => {
      it('deploys with owner', async () => {
        assert.equal(owner, await token.owner(), "owner is not deployer")
      })

      it('deploys with currentTokenId 0', async () => {
        assert.equal(0, await token.currentTokenId(), "currentTokenId is not 0 during deployment")
      })

      it('deploys with empty baseTokenURI', async () => {
        assert.equal("", await token.baseTokenURI(), "baseTokenURI is not empty during deployment")
      })

    })

    describe('tokenURI', () => {
      it('should work when tokenId is 0', async () => {
        assert.equal("0", await token.tokenURI(0), "invalid output for tokenId 0")
      })

    })

    describe('isApprovedForAll', () => {
      it('should just return if owner has authorized operator, without invoking ProxyRegistryAddress', async () => {
        // call with invalid owner will revert
        await expectRevert(
          token.isApprovedForAll(ZERO_ADDRESS, operator),
          'owner address cannot be zero',
        )

        // call with invalid operator will revert
        await expectRevert(
          token.isApprovedForAll(owner, ZERO_ADDRESS),
          'operator address cannot be zero',
        )

        assert.equal(false, await token.isApprovedForAll(owner, operator), "owner has not authorized operator")
      })

    })

  })


  describe('when ProxyRegistryAddress is not ZERO_ADDRESS', () => {

    beforeEach(async () => {
      proxy = await OwnableDelegateProxy.new()
      proxyRegistry = await ProxyRegistry.new()
      token = await TradeableERC721Token.new("Mock Non Fungible Token", "MNFT", proxyRegistry.address)
      operator = proxy.address
    })

    describe('isApprovedForAll', () => {
      it('should invoke ProxyRegistryAddress', async () => {
        assert.equal(false, await token.isApprovedForAll(owner, operator), "owner has not authorized proxy")
      })

    })

  })


});
