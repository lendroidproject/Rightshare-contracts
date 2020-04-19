const { expectRevert, time } = require('@openzeppelin/test-helpers')

contract("RightsDao", (accounts) => {

  const RightsDao = artifacts.require("RightsDao");
  const FRight = artifacts.require("FRight");
  const IRight = artifacts.require("IRight");
  const NFT = artifacts.require("TradeableERC721Token");

  const owner = accounts[0]
  const API_BASE_URL = "https://rinkeby-rightshare-metadata.lendroid.com/api/v1/"
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

  let dao, fRight, iRight, nft

  beforeEach(async () => {
    dao = await RightsDao.deployed()
    fRight = await FRight.deployed()
    iRight = await IRight.deployed()
    nft = await NFT.deployed()
  })

  describe('constructor', () => {

    it('fails when deployed with invalid fRightContractAddress', async () => {
      // call when fRightContractAddress = ZERO_ADDRESS will revert
      await expectRevert(
        RightsDao.new(ZERO_ADDRESS, iRight.address),
        'invalid fRightContractAddress',
      )
      // call when fRightContractAddress is not ZERO_ADDRESS and not contract will revert
      await expectRevert(
        RightsDao.new(accounts[1], iRight.address),
        'invalid fRightContractAddress',
      )
    })

    it('fails when deployed with invalid iRightContractAddress', async () => {
      // call when iRightContractAddress = ZERO_ADDRESS will revert
      await expectRevert(
        RightsDao.new(fRight.address, ZERO_ADDRESS),
        'invalid iRightContractAddress',
      )
      // call when iRightContractAddress is not ZERO_ADDRESS and not contract will revert
      await expectRevert(
        RightsDao.new(fRight.address, accounts[1]),
        'invalid iRightContractAddress',
      )
    })

    it('deploys with owner', async () => {
      assert.equal(owner, await dao.owner(), "owner is not deployer")
    })

    it('deploys with whitelistedFreezeActivated set to true', async () => {
      assert.equal(true, await dao.whitelistedFreezeActivated(), "whitelistedFreezeActivated is false during deployment")
    })

    it('deploys with currentFVersion set to 1', async () => {
      assert.equal(1, await dao.currentFVersion(), "currentFVersion is not 1 during deployment")
    })

    it('deploys with currentIVersion set to 1', async () => {
      assert.equal(1, await dao.currentIVersion(), "currentIVersion is not 1 during deployment")
    })
  })

  describe('deactivateWhitelistedFreeze', () => {
    it('succeeds only when already activated', async () => {
      assert.equal(true, await dao.whitelistedFreezeActivated(), "incorrect value of whitelistedFreezeActivated")
      // call by non owner will revert
      await expectRevert(
        dao.deactivateWhitelistedFreeze({from: accounts[1]}),
        'caller is not the owner',
      )
      // deactivate whitelisted freeze
      await dao.deactivateWhitelistedFreeze({from: owner})
      assert.equal(false, await dao.whitelistedFreezeActivated(), "incorrect value of whitelistedFreezeActivated")
      // call when already deactivated will revert
      await expectRevert(
        dao.deactivateWhitelistedFreeze({from: owner}),
        'whitelisted freeze is already deactivated',
      )
    })
  })

  describe('activateWhitelistedFreeze', () => {
    it('succeeds only when already deactivated', async () => {
      assert.equal(false, await dao.whitelistedFreezeActivated(), "incorrect value of whitelistedFreezeActivated")
      // call by non owner will revert
      await expectRevert(
        dao.activateWhitelistedFreeze({from: accounts[1]}),
        'caller is not the owner',
      )
      // activate whitelisted freeze
      await dao.activateWhitelistedFreeze({from: owner})
      assert.equal(true, await dao.whitelistedFreezeActivated(), "incorrect value of whitelistedFreezeActivated")
      // call when already activated will revert
      await expectRevert(
        dao.activateWhitelistedFreeze({from: owner}),
        'whitelisted freeze is already activated',
      )
    })
  })


  describe('toggleWhitelistStatus', () => {
    it('succeeds only when called by owner', async () => {
      assert.equal(false, await dao.isWhitelisted(accounts[1]), "incorrect whitelist status")
      // call by non owner will revert
      await expectRevert(
        dao.toggleWhitelistStatus(accounts[1], true, {from: accounts[1]}),
        'caller is not the owner',
      )
      // whitelist accounts[1]
      await dao.toggleWhitelistStatus(accounts[1], true, {from: owner})
      assert.equal(true, await dao.isWhitelisted(accounts[1]), "incorrect whitelist status")
      // revoke whitelist status of accounts[1]
      await dao.toggleWhitelistStatus(accounts[1], false, {from: owner})
      assert.equal(false, await dao.isWhitelisted(accounts[1]), "incorrect whitelist status")
    })

  })


  describe('incrementCurrentFVersion', () => {
    it('succeeds only when version > 0', async () => {
      assert.equal(1, await dao.currentFVersion(), "incorrect currentFVersion")
      // call by non owner will revert
      await expectRevert(
        dao.incrementCurrentFVersion({from: accounts[1]}),
        'caller is not the owner',
      )
      // incrementCurrentFVersion to 2
      await dao.incrementCurrentFVersion({from: owner})
      assert.equal(2, await dao.currentFVersion(), "incorrect currentFVersion")
    })
  })


  describe('incrementCurrentIVersion', () => {
    it('succeeds only when version > 0', async () => {
      assert.equal(1, await dao.currentIVersion(), "incorrect currentIVersion")
      // call by non owner will revert
      await expectRevert(
        dao.incrementCurrentIVersion({from: accounts[1]}),
        'caller is not the owner',
      )
      // incrementCurrentFVersion to 2
      await dao.incrementCurrentIVersion({from: owner})
      assert.equal(2, await dao.currentIVersion(), "incorrect currentIVersion")
    })
  })

  describe('setRightApiBaseUrl', () => {

    before(async () => {
      // transfer fright ownership to dao
      await fRight.transferOwnership(dao.address);
      // transfer iright ownership to dao
      await iRight.transferOwnership(dao.address);
    })

    it('allows owner to set api base url of f right', async () => {
      // Confirm apiBaseURL has not been set
      assert.equal(await fRight.baseTokenURI(), "", "apiBaseURL is not empty when deployed.")
      // call with invalid contract type will revert
      await expectRevert(
        dao.setRightApiBaseUrl(0, API_BASE_URL, {from: owner}),
        'invalid contract type',
      )
      await expectRevert(
        dao.setRightApiBaseUrl(3, API_BASE_URL, {from: owner}),
        'invalid contract type',
      )
      // call with invalid owner will revert
      await expectRevert(
        dao.setRightApiBaseUrl(1, API_BASE_URL, {from: accounts[1]}),
        'caller is not the owner',
      )
      // Set apiBaseURL
      await dao.setRightApiBaseUrl(1, API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await fRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })

    it('allows owner to set api base url of i right', async () => {
      // Confirm apiBaseURL has not been set
      assert.equal(await iRight.baseTokenURI(), "", "apiBaseURL is not empty when deployed.")
      // call with invalid owner will revert
      await expectRevert(
        dao.setRightApiBaseUrl(2, API_BASE_URL, {from: accounts[1]}),
        'caller is not the owner',
      )
      // Set apiBaseURL
      await dao.setRightApiBaseUrl(2, API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await iRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })
  })

  describe('setRightProxyRegistry', () => {

    it('allows owner to set proxy registry of f right', async () => {
      // transfer i right ownership to accounts[1]
      await dao.setRightProxyRegistry(1, accounts[1]);
      // call with invalid contract type will revert
      await expectRevert(
        dao.setRightProxyRegistry(0, accounts[1]),
        'invalid contract type',
      )
      await expectRevert(
        dao.setRightProxyRegistry(3, accounts[1]),
        'invalid contract type',
      )
      // call by non owner will revert
      await expectRevert(
        dao.setRightProxyRegistry(1, accounts[1], {from: accounts[1]}),
        'caller is not the owner',
      )
      // call with contract address = ZERO_ADDRESS will revert
      await expectRevert(
        dao.setRightProxyRegistry(1, ZERO_ADDRESS),
        'invalid proxy registry address',
      )
    })

    it('allows owner to set proxy registry of i right', async () => {
      // transfer i right ownership to accounts[1]
      await dao.setRightProxyRegistry(2, accounts[1]);
      // call by non owner will revert
      await expectRevert(
        dao.setRightProxyRegistry(2, accounts[1], {from: accounts[1]}),
        'caller is not the owner',
      )
    })
  })

  describe('freeze : exclusive rights', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    before(async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 1
      _isExclusive = true
      _maxISupply = 1
      // approves
      await nft.approve(dao.address, 1, {from: owner})
      // deactivate whitelisted freeze
      await dao.deactivateWhitelistedFreeze({from: owner})
    })

    it('fails for incorrect _maxISupply', async () => {
      // call with _maxISupply = 0
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [0, 1, 1], {from: owner}),
        'invalid maximum I supply',
      )

      // call with _maxISupply = 2
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [2, 1, 1], {from: owner}),
        'invalid maximum I supply',
      )
    })

    it('fails for incorrect _baseAssetId', async () => {
      // call by non owner will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, 2, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'revert',
      )
    })

    it('fails for incorrect _endTime', async () => {
      // call with past _endTime will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, 0, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'expiry should be in the future',
      )
    })

    it('fails for incorrect f_version', async () => {
      // call with f_version = 0 will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 0, 1], {from: owner}),
        'invalid f version',
      )

      // call with f_version = 3 will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 3, 1], {from: owner}),
        'invalid f version',
      )
    })

    it('fails for incorrect i_version', async () => {
      // call with i_version = 0 will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 0], {from: owner}),
        'invalid i version',
      )

      // call with i_version = 3 will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 3], {from: owner}),
        'invalid i version',
      )
    })

    it('fails if whitelisted freeze is activated and caller is not whitelisted', async () => {
      // activate whitelisted freeze
      await dao.activateWhitelistedFreeze({from: owner})
      // call by non owner will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'sender is not whitelisted',
      )
      // deactivate whitelisted freeze
      await dao.deactivateWhitelistedFreeze({from: owner})
    })

    it('succeeds', async () => {
      // Call freeze
      await dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // call freeze again will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'revert',
      )
    })
  })

  describe('issueI', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    it('works for non exclusive', async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 2
      _isExclusive = false
      _maxISupply = 3
      _f_right_id = 2
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 2, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // Call issueI
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      // call by non owner will fail
      await expectRevert(
        dao.issueI([_f_right_id, _expiry, 1], {from: accounts[2]}),
        'revert',
      )
      // call with expiry < current timestamp will fail
      await expectRevert(
        dao.issueI([_f_right_id, 1000000, 1], {from: owner}),
        'expiry should be in the future',
      )
      // call with expiry > endtime will fail
      await expectRevert(
        dao.issueI([_f_right_id, _endTime+1, 1], {from: owner}),
        'expiry cannot exceed fRight expiry',
      )
      // call with i_version = 0 will fail
      await expectRevert(
        dao.issueI([_f_right_id, _endTime, 0], {from: owner}),
        'invalid i version',
      )
      // call with i_version > 2 will fail
      await expectRevert(
        dao.issueI([_f_right_id, _endTime, 3], {from: owner}),
        'invalid i version',
      )
      // Call issueI again will work
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      // call issueI again will fail
      await expectRevert(
        dao.issueI([_f_right_id, _expiry, 1], {from: owner}),
        'revert',
      )
    })

    it('fails for exclusive', async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 3
      _isExclusive = true
      _maxISupply = 1
      _f_right_id = 3
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 3, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // call issueI will fail
      await expectRevert(
        dao.issueI([_f_right_id, _expiry, 1], {from: owner}),
        'revert',
      )
    })
  })

  describe('revokeI', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

    it('fails when tokenId is 0', async () => {
      // call issueI again will fail
      await expectRevert(
        dao.revokeI(0, {from: accounts[1]}),
        'ERC721: owner query for nonexistent token.',
      )
    })

    it('succeeds for non exclusive', async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 4
      _isExclusive = false
      _maxISupply = 3
      _f_right_id = 4
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 4, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // Call issueI
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(7, await iRight.currentTokenId(), 'is wrong id value')
      // call revokeI will fail with non owner of iRight
      await expectRevert(
        dao.revokeI(7, {from: accounts[1]}),
        'sender is not the owner of iRight',
      )
      // Call revokeI
      await dao.revokeI(7, {from: owner})
      // Call issueI
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(8, await iRight.currentTokenId(), 'is wrong id value')
      // Call revokeI
      await dao.revokeI(8, {from: owner})
      // 1-1
      // call issueI will fail
      await expectRevert(
        dao.issueI([_f_right_id, _expiry, 1], {from: owner}),
        'revert',
      )
      // Call revokeI
      await dao.revokeI(6, {from: owner})
      // call revokeI will fail
      await expectRevert(
        dao.revokeI(8, {from: owner}),
        'revert',
      )
    })

  })

  describe('unfreeze', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, currentTokenId

    it('succeeds when all i tokens are revoked', async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 5
      _isExclusive = false
      _maxISupply = 3
      _f_right_id = 5
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 5, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // call unfreeze will fail
      await expectRevert(
        dao.unfreeze(_f_right_id, {from: owner}),
        'revert',
      )
      // Call issueI
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      currentTokenId = await iRight.currentTokenId()
      assert.equal(10, currentTokenId.toString(), 'is wrong id value')
      // Call revokeI
      await dao.revokeI(10, {from: owner})
      // Call issueI
      await dao.issueI([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(11, await iRight.currentTokenId(), 'is wrong id value')
      // Call revokeI
      await dao.revokeI(11, {from: owner})
      // Call revokeI
      await dao.revokeI(9, {from: owner})
      // call unfreeze will succeed
      await dao.unfreeze(_f_right_id, {from: owner})
      // call unfreeze will fail
      await expectRevert(
        dao.unfreeze(_f_right_id, {from: owner}),
        'revert',
      )
    })
  })

  describe('when freeze can be performed only by whitelisted accounts', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, currentTokenId

    it('succeeds only when activateWhitelistedFreeze is true and sender is whitelisted', async () => {
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 6
      _isExclusive = true
      _maxISupply = 1
      _f_right_id = 6
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 6, {from: owner})
      // activate whitelisted freeze
      await dao.activateWhitelistedFreeze({from: owner})
      // whitelist owner
      await dao.toggleWhitelistStatus(owner, true, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // call revokeI will succeed
      await dao.revokeI(12, {from: owner})
      // call unfreeze will succeed
      await dao.unfreeze(_f_right_id, {from: owner})
    })
  })

  describe('unfreeze and iRevoke after expiry of rights', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, currentTokenId

    it('succeeds when all i tokens are revoked', async () => {
      // deactivate whitelisted freeze
      await dao.deactivateWhitelistedFreeze({from: owner})
      // Mint NFT to owner
      await nft.mintTo(owner);
      _endTime = 1609459200
      _baseAssetAddress = web3.utils.toChecksumAddress(nft.address)
      _baseAssetId = 7
      _isExclusive = true
      _maxISupply = 1
      _f_right_id = 7
      _expiry = 1609459190
      // approves
      await nft.approve(dao.address, 7, {from: owner})
      // Call freeze
      await dao.freeze(_baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner})
      // time travel to _expiry
      await time.increaseTo(time.duration.seconds(_endTime+1))
      // call unfreeze will succeed
      await dao.unfreeze(_f_right_id, {from: owner})
      // call revokeI will succeed
      await dao.revokeI(13, {from: owner})
    })
  })

});
