const { expectRevert } = require('@openzeppelin/test-helpers')

contract("IRight", (accounts) => {

  const IRight = artifacts.require("IRight");
  const NFT = artifacts.require("TradeableERC721Token");

  const owner = accounts[0]
  const API_BASE_URL = "https://rightshare-metadata.lendroid.com/api/v1/"
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

  let iRight, nft

  beforeEach(async () => {
    iRight = await IRight.deployed()
    nft = await NFT.deployed()
  })

  describe('constructor', () => {
    it('deploys with owner', async () => {
      assert.equal(owner, await iRight.owner(), "owner is not deployer")
    })
  })

  describe('setApiBaseUrl', () => {
    it('allows owner to set Api Url', async () => {
      // Confirm apiBaseURL has not been set
      assert.equal(await iRight.baseTokenURI(), "", "apiBaseURL is not empty when deployed.")
      // Set apiBaseURL
      await iRight.setApiBaseUrl(API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await iRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })
  })

  describe('setProxyRegistryAddress', () => {
    it('allows owner to set Proxy Registry Address', async () => {
      // Set ProxyRegistryAddress
      await iRight.setProxyRegistryAddress(accounts[5], {from: owner})
    })
  })

  describe('issue : all rights', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 1
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 1
      _isExclusive = true
      _maxISupply = 1
      _serialNumber = 1
      // Confirm IRight currentTokenId is 0
      assert.equal(await iRight.currentTokenId(), 0, "currentTokenId is not 0.")
      // Call issue
      await iRight.issue([_to, _baseAssetAddress], _isExclusive, [_parentId, _endTime, _baseAssetId, 1], {from: owner})
    })

    it('mints iRight token to accounts[1]', async () => {
      // Confirm IRight currentTokenId is 1
      assert.equal(await iRight.ownerOf(1), accounts[1], "Incorrect owner of iRight token.")
    })

    it('updates the currentTokenId', async () => {
      // Confirm IRight currentTokenId is 1
      assert.equal(await iRight.currentTokenId(), 1, "currentTokenId is not 1.")
    })

    it('updates the parentId', async () => {
      // Confirm IRight currentTokenId is 1
      assert.equal(await iRight.parentId(1), _parentId, "_parentId is incorrect.")
    })

    it('updates baseAsset', async () => {
      result = await iRight.baseAsset(1)
      // Confirm baseAsset address
      assert.equal(result[0], _baseAssetAddress, "_baseAssetAddress cannot be 0x0.")
      // Confirm baseAsset id
      assert.equal(result[1], _baseAssetId, "_baseAssetId cannot be 0.")
    })
  })

  describe('issue : exclusive rights', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 2
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 2
      _isExclusive = true
      _maxISupply = 1
      _serialNumber = 1
      // Call issue
      await iRight.issue([_to, _baseAssetAddress], _isExclusive, [_parentId, _endTime, _baseAssetId, 1], {from: owner})
    })

    it('updates the tokenURI', async () => {
      const tokenURI = await iRight.tokenURI(2)
      // Confirm IRight tokenURI is correct
      assert.equal(tokenURI.toString(), `${API_BASE_URL}i/${_baseAssetAddress.toLowerCase()}/2/1609459200/1/1`, "tokenURI is incorrect.")
    })
  })

  describe('issue : non exclusive rights', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 3
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 3
      _isExclusive = false
      _maxISupply = 3
      _serialNumber = 2
      // Call issure
      await iRight.issue([_to, _baseAssetAddress], _isExclusive, [_parentId, _endTime, _baseAssetId, 1], {from: owner})
    })

    it('updates the tokenURI', async () => {
      const tokenURI = await iRight.tokenURI(3)
      // Confirm IRight tokenURI is correct
      assert.equal(tokenURI.toString(), `${API_BASE_URL}i/${_baseAssetAddress.toLowerCase()}/3/1609459200/0/1`, "tokenURI is incorrect.")
    })
  })

  describe('issue : reverts', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 4
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 4
    })

    it('should fail if to is ZERO_ADDRESS', async () => {
      // Call issue fails if to is ZERO_ADDRESS
      await expectRevert(
        iRight.issue([ZERO_ADDRESS, _baseAssetAddress], true, [_parentId, _endTime, _baseAssetId, 1], {from: owner}),
        'revert',
      )
    })

    it('should fail if _baseAssetAddress is ZERO_ADDRESS', async () => {
      // Call issue fails if _baseAssetAddress is ZERO_ADDRESS
      await expectRevert(
        iRight.issue([_to, ZERO_ADDRESS], true, [_parentId, _endTime, _baseAssetId, 1], {from: owner}),
        'invalid base asset address',
      )
    })

    it('should fail if _parentId is 0', async () => {
      // Call issue fails if _parentId is 0
      await expectRevert(
        iRight.issue([_to, _baseAssetAddress], true, [0, _endTime, _baseAssetId, 1], {from: owner}),
        'invalid parent id',
      )
    })

    it('should fail if _endTime is invalid', async () => {
      // Call issue fails if version is 0
      await expectRevert(
        iRight.issue([_to, _baseAssetAddress], true, [_parentId, 0, _baseAssetId, 1], {from: owner}),
        'invalid expiry',
      )
    })

    it('should fail if _baseAssetId is 0', async () => {
      // Call issue fails if _baseAssetId is 0
      await expectRevert(
        iRight.issue([_to, _baseAssetAddress], true, [_parentId, _endTime, 0, 1], {from: owner}),
        'invalid base asset id',
      )
    })

    it('should fail if version is 0', async () => {
      // Call issue fails if version is 0
      await expectRevert(
        iRight.issue([_to, _baseAssetAddress], true, [_parentId, _endTime, _baseAssetId, 0], {from: owner}),
        'invalid version',
      )
    })

  })

  describe('revoke', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 4
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 4
      _isExclusive = true
      _maxISupply = 1
      _serialNumber = 1
      // Call issue
      await iRight.issue([_to, _baseAssetAddress], _isExclusive, [_parentId, _endTime, _baseAssetId, 1], {from: owner})
    })

    it('should pass when token exists', async () => {
      // Call revoke fails for incorrect iRight token owner
      await expectRevert(
        iRight.revoke(owner, 4, {from: owner}),
        'ERC721: burn of token that is not own',
      )
      // Call revoke
      await iRight.revoke(accounts[1], 4, {from: owner})
    })

    it('should fail for incorrect tokenId', async () => {
      // Call revoke will fail
      await expectRevert(
        iRight.revoke(accounts[1], 4, {from: owner}),
        'IRT: token does not exist',
      )
    })

  })

  describe('function calls with incorrect tokenId', () => {
    let _to, _parentId, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _to = accounts[1]
      _parentId = 5
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 5
      _isExclusive = true
      _maxISupply = 1
      _serialNumber = 1
      // Call issue
      await iRight.issue([_to, _baseAssetAddress], _isExclusive, [_parentId, _endTime, _baseAssetId, 1], {from: owner})
    })

    it('revoke fails', async () => {
      // Call revoke with tokenId = 0
      await expectRevert(
        iRight.revoke(owner, 0, {from: owner}),
        'invalid token id',
      )

    })

    it('tokenURI fails', async () => {
      // Call tokenURI with tokenId = 0
      await expectRevert(
        iRight.tokenURI(0),
        'invalid token id',
      )

      // Call tokenURI
      await expectRevert(
        iRight.tokenURI(8),
        'IRT: token does not exist',
      )
    })

    it('parentId fails', async () => {
      // Call parentId with tokenId = 0
      await expectRevert(
        iRight.parentId(0),
        'invalid token id',
      )

      // Call parentId
      await expectRevert(
        iRight.parentId(8),
        'IRT: token does not exist',
      )
    })

    it('baseAsset fails', async () => {
      // Call baseAsset with tokenId = 0
      await expectRevert(
        iRight.baseAsset(0),
        'invalid token id',
      )

      // Call baseAsset
      await expectRevert(
        iRight.baseAsset(8),
        'IRT: token does not exist',
      )
    })

  })

});
