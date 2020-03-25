const { expectRevert } = require('@openzeppelin/test-helpers')

contract("FRight", (accounts) => {

  const FRight = artifacts.require("FRight");
  const NFT = artifacts.require("TradeableERC721Token");

  const owner = accounts[0]
  const API_BASE_URL = "https://rinkeby-rightshare-metadata.lendroid.com/api/v1/"

  let fRight, nft

  beforeEach(async () => {
    fRight = await FRight.deployed()
    nft = await NFT.deployed()
  })

  describe('constructor', () => {
    it('deploys with owner', async () => {
      assert.equal(owner, await fRight.owner(), "owner is not deployer")
    })
  })

  describe('setApiBaseUrl', () => {
    it('allows owner to set Api Url', async () => {
      // Confirm apiBaseURL has not been set
      assert.equal(await fRight.baseTokenURI(), "", "apiBaseURL is not empty when deployed.")
      // Set apiBaseURL
      await fRight.setApiBaseUrl(API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await fRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })
  })

  describe('setProxyRegistryAddress', () => {
    it('allows owner to set Proxy Registry Address', async () => {
      // Set ProxyRegistryAddress
      await fRight.setProxyRegistryAddress(accounts[5], {from: owner})
    })
  })

  describe('freeze', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    beforeEach(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1585699199
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 1
      _isExclusive = true
      _maxISupply = 1
    })

    context('when called by the owner', () => {

      context('when baseAsset is not frozen', () => {


        it('freeze succeeds : updates the currentTokenId', async () => {
          // Confirm FRight currentTokenId is 0
          assert.equal(await fRight.currentTokenId(), 0, "currentTokenId is not 0.")
          // Call freeze
          await fRight.freeze(_to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, {from: owner})
          // Confirm FRight currentTokenId is 1
          assert.equal(await fRight.currentTokenId(), 1, "currentTokenId is not 1.")
        })

        it('freeze succeeds : updates the tokenURI', async () => {
          const tokenURI = await fRight.tokenURI(1)
          // Confirm FRight tokenURI is correct
          assert.equal(tokenURI.toString(), `${API_BASE_URL}${_baseAssetAddress.toLowerCase()}/1/f/1585699199/1/1/1`, "tokenURI is incorrect.")
        })

        it('freeze succeeds : updates isFrozen', async () => {
          // Confirm FRight is not Unfreezable
          assert.equal(await fRight.isUnfreezable(1), false, "fRight should not be Unfreezable.")
        })

        it('freeze succeeds : updates circulatingISupply', async () => {
          // Confirm FRight is not IMintAble
          assert.equal(await fRight.isIMintAble(1), false, "fRight should not be IMintAble.")
        })

        it('freeze succeeds : updates baseAsset', async () => {
          result = await fRight.baseAsset(1)
          // Confirm baseAsset address
          assert.equal(result[0], _baseAssetAddress, "_baseAssetAddress cannot be 0x0.")
          // Confirm baseAsset id
          assert.equal(result[1], _baseAssetId, "_baseAssetId cannot be 0.")
        })

        it('freeze succeeds : updates endTimeAndISupplies', async () => {
          result = await fRight.endTimeAndISupplies(1)
          // Confirm _endTime
          assert.equal(result[0], _endTime, "_endTime is invalid.")
          // Confirm _maxISupply
          assert.equal(result[1], _maxISupply, "_maxISupply is invalid.")
          // Confirm _circulatingISupply
          assert.equal(result[2], 1, "_circulatingISupply is invalid.")
        })
      })

      context('when baseAsset is frozen', () => {
        it('freeze fails', async () => {
          // Call freeze again
          await expectRevert(
            fRight.freeze(_to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, {from: owner}),
            'Asset is already frozen',
          )
        })
      })
    })
  })
});
