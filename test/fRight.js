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

  describe('freeze : all rights', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 1
      _isExclusive = true
      _maxISupply = 1
      // Confirm FRight currentTokenId is 0
      assert.equal(await fRight.currentTokenId(), 0, "currentTokenId is not 0.")
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })

    it('mints fRight token to accounts[1]', async () => {
      // Confirm FRight currentTokenId is 1
      assert.equal(await fRight.ownerOf(1), accounts[1], "Incorrect owner of fRight token.")
    })

    it('updates the currentTokenId', async () => {
      // Confirm FRight currentTokenId is 1
      assert.equal(await fRight.currentTokenId(), 1, "currentTokenId is not 1.")
    })

    it('updates isFrozen', async () => {
      // Confirm FRight is not Unfreezable
      assert.equal(await fRight.isUnfreezable(1), false, "fRight should not be Unfreezable.")
    })

    it('updates baseAsset', async () => {
      result = await fRight.baseAsset(1)
      // Confirm baseAsset address
      assert.equal(result[0], _baseAssetAddress, "_baseAssetAddress cannot be 0x0.")
      // Confirm baseAsset id
      assert.equal(result[1], _baseAssetId, "_baseAssetId cannot be 0.")
    })

    it('updates endTimeAndISupplies', async () => {
      result = await fRight.endTimeAndISupplies(1)
      // Confirm _endTime
      assert.equal(result[0], _endTime, "_endTime is invalid.")
      // Confirm _maxISupply
      assert.equal(result[1], _maxISupply, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 1, "_circulatingISupply is invalid.")
    })

    it('should decrement CirculatingISupply', async () => {
      result = await fRight.endTimeAndISupplies(1)
      // Confirm _maxISupply
      assert.equal(result[1], 1, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 1, "_circulatingISupply is invalid.")
      // Decrement circulatingISupply, which also decrements maxISupply
      await fRight.decrementCirculatingISupply(1, 1, {from: owner})
      result = await fRight.endTimeAndISupplies(1)
      // Confirm _maxISupply
      assert.equal(result[1], 0, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 0, "_circulatingISupply is invalid.")
      // Decrement again will revert
      await expectRevert(
        fRight.decrementCirculatingISupply(1, 1, {from: owner}),
        'SafeMath: subtraction overflow',
      )
    })
  })

  describe('freeze : exclusive rights', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 2
      _isExclusive = true
      _maxISupply = 1
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })

    it('updates the tokenURI', async () => {
      const tokenURI = await fRight.tokenURI(2)
      // Confirm FRight tokenURI is correct
      assert.equal(tokenURI.toString(), `${API_BASE_URL}${_baseAssetAddress.toLowerCase()}/2/f/1609459200/1/1/1/1`, "tokenURI is incorrect.")
    })

    it('IMintAble is false', async () => {
      // Confirm FRight is not IMintAble
      assert.equal(await fRight.isIMintAble(2), false, "fRight should not be IMintAble.")
    })

    it('should not increment CirculatingISupply', async () => {
      result = await fRight.endTimeAndISupplies(2)
      // Confirm _maxISupply
      assert.equal(result[1], 1, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 1, "_circulatingISupply is invalid.")
      // Increment will revert
      await expectRevert(
        fRight.incrementCirculatingISupply(2, 1, {from: owner}),
        'Circulating I Supply cannot be incremented',
      )
    })
  })

  describe('freeze : non exclusive rights', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 3
      _isExclusive = false
      _maxISupply = 3
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })

    it('updates the tokenURI', async () => {
      const tokenURI = await fRight.tokenURI(3)
      // Confirm FRight tokenURI is correct
      assert.equal(tokenURI.toString(), `${API_BASE_URL}${_baseAssetAddress.toLowerCase()}/3/f/1609459200/0/3/1/1`, "tokenURI is incorrect.")
    })

    it('IMintAble is true', async () => {
      // Confirm FRight is not IMintAble
      assert.equal(await fRight.isIMintAble(3), true, "fRight should be IMintAble.")
    })

    it('should increment CirculatingISupply', async () => {
      result = await fRight.endTimeAndISupplies(3)
      // Confirm _maxISupply
      assert.equal(result[1], 3, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 1, "_circulatingISupply is invalid.")
      // Increment CirculatingISupply
      await fRight.incrementCirculatingISupply(3, 1, {from: owner});
      result = await fRight.endTimeAndISupplies(3)
      // Confirm _maxISupply
      assert.equal(result[1], 3, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 2, "_circulatingISupply is invalid.")
      // Increment CirculatingISupply
      await fRight.incrementCirculatingISupply(3, 1, {from: owner});
      result = await fRight.endTimeAndISupplies(3)
      // Confirm _maxISupply
      assert.equal(result[1], 3, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 3, "_circulatingISupply is invalid.")
      // Increment will revert
      await expectRevert(
        fRight.incrementCirculatingISupply(3, 1, {from: owner}),
        'Circulating I Supply cannot be incremented',
      )
    })
  })

  describe('freeze : reverts', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 4
      _isExclusive = true
      _maxISupply = 1
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })
    it('fails when called again', async () => {
      // Call freeze again
      await expectRevert(
        fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner}),
        'Asset is already frozen',
      )
    })
  })

  describe('unfreeze', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 5
      _isExclusive = true
      _maxISupply = 1
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })

    it('should pass when circulatingISupply is 0', async () => {
      // Decrement circulatingISupply, which also decrements maxISupply
      await fRight.decrementCirculatingISupply(5, 1, {from: owner})
      result = await fRight.endTimeAndISupplies(5)
      // Confirm _maxISupply
      assert.equal(result[1], 0, "_maxISupply is invalid.")
      // Confirm _circulatingISupply
      assert.equal(result[2], 0, "_circulatingISupply is invalid.")
      // Call unfreeze fails for incorrect fRight token owner
      await expectRevert(
        fRight.unfreeze(owner, 5, {from: owner}),
        'ERC721: burn of token that is not own',
      )
      // Call unfreeze
      await fRight.unfreeze(accounts[1], 5, {from: owner})
    })

    it('should fail for incorrect tokenId', async () => {
      // Call unfreeze will fail
      await expectRevert(
        fRight.unfreeze(accounts[1], 5, {from: owner}),
        'FRT: token does not exist',
      )
    })

    it('should fail when unfreezable', async () => {
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
      // Call unfreeze will fail
      await expectRevert(
        fRight.unfreeze(accounts[1], 6, {from: owner}),
        'FRT: token is not unfreezable',
      )
    })
  })

  describe('function calls with incorrect tokenId', () => {
    let _to, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 6
      _isExclusive = true
      _maxISupply = 1
      // Call freeze
      await fRight.freeze([_to, _baseAssetAddress], _isExclusive, [_endTime, _baseAssetId, _maxISupply, 1], {from: owner})
    })

    it('tokenURI fails', async () => {
      // Call tokenURI
      await expectRevert(
        fRight.tokenURI(8),
        'FRT: token does not exist',
      )
    })

    it('isUnfreezable fails', async () => {
      // Call isUnfreezable
      await expectRevert(
        fRight.isUnfreezable(8),
        'FRT: token does not exist',
      )
    })

    it('isIMintAble fails', async () => {
      // Call isIMintAble
      await expectRevert(
        fRight.isIMintAble(8),
        'FRT: token does not exist',
      )
    })

    it('baseAsset fails', async () => {
      // Call baseAsset
      await expectRevert(
        fRight.baseAsset(8),
        'FRT: token does not exist',
      )
    })

    it('endTimeAndISupplies fails', async () => {
      // Call endTimeAndISupplies
      await expectRevert(
        fRight.endTimeAndISupplies(8),
        'FRT: token does not exist',
      )
    })

    it('incrementCirculatingISupply fails', async () => {
      // Call incrementCirculatingISupply
      await expectRevert(
        fRight.incrementCirculatingISupply(8, 1, {from: owner}),
        'FRT: token does not exist',
      )
    })

    it('decrementCirculatingISupply fails', async () => {
      // Call decrementCirculatingISupply
      await expectRevert(
        fRight.decrementCirculatingISupply(8, 1, {from: owner}),
        'FRT: token does not exist',
      )
    })
  })

});
