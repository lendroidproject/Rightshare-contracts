const { expectRevert } = require('@openzeppelin/test-helpers')


contract("TradeableERC721Token", (accounts) => {

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
  const OwnableDelegateProxy = artifacts.require("OwnableDelegateProxy")
  const ProxyRegistry = artifacts.require("ProxyRegistry")
  const owner = accounts[0]

  let proxy, proxyRegistry

  before(async () => {
    proxy = await OwnableDelegateProxy.new()
    proxyRegistry = await ProxyRegistry.new()
    operator = proxy.address
  })

  describe('setProxy', () => {

    it('fails when proxyContractAddress is invalid', async () => {
      // call when proxyContractAddress = ZERO_ADDRESS will revert
      await expectRevert(
        proxyRegistry.setProxy(owner, ZERO_ADDRESS, {from: owner}),
        'invalid proxy contract address',
      )
      // call when proxyContractAddress is not ZERO_ADDRESS and not contract address will revert
      await expectRevert(
        proxyRegistry.setProxy(owner, accounts[1], {from: owner}),
        'invalid proxy contract address',
      )
    })

    it('fails when called by non-owner', async () => {
      // call by non-owner
      await expectRevert(
        proxyRegistry.setProxy(accounts[1], operator, {from: accounts[1]}),
        'caller is not the owner',
      )
    })

    it('succeeds when proxyContractAddress is valid', async () => {
      assert.equal(ZERO_ADDRESS, await proxyRegistry.proxies(owner), "proxy address for owner should be ZERO_ADDRESS")
      // call when proxyContractAddress = operator
      await proxyRegistry.setProxy(owner, operator, {from: owner})
      assert.equal(operator, await proxyRegistry.proxies(owner), "proxy address for owner should not be ZERO_ADDRESS")
    })

  })

});


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
      it('should invoke ProxyRegistryAddress and return false', async () => {
        assert.equal(false, await token.isApprovedForAll(owner, operator), "owner has not authorized proxy")
      })

      it('should invoke ProxyRegistryAddress and return true', async () => {
        // call when proxyContractAddress = operator
        await proxyRegistry.setProxy(owner, operator, {from: owner})
        assert.equal(true, await token.isApprovedForAll(owner, operator), "owner has authorized proxy")
      })

    })

  })


});
