const { expectRevert } = require('@openzeppelin/test-helpers')

contract("RightsDao", (accounts) => {

  const RightsDao = artifacts.require("RightsDao");
  const FRight = artifacts.require("FRight");
  const IRight = artifacts.require("IRight");
  const NFT = artifacts.require("TradeableERC721Token");

  const owner = accounts[0]
  const API_BASE_URL = "https://rinkeby-rightshare-metadata.lendroid.com/api/v1/"

  let dao, fRight, iRight, nft

  beforeEach(async () => {
    dao = await RightsDao.deployed()
    fRight = await FRight.deployed()
    iRight = await IRight.deployed()
    nft = await NFT.deployed()
  })

  describe('constructor', () => {
    it('deploys with owner', async () => {
      assert.equal(owner, await dao.owner(), "owner is not deployer")
    })

    it('deploys with whitelisted_freeze_activated set to true', async () => {
      assert.equal(true, await dao.whitelisted_freeze_activated(), "whitelisted_freeze_activated is false during deployment")
    })

    it('deploys with current_f_version set to 1', async () => {
      assert.equal(1, await dao.current_f_version(), "current_f_version is not 1 during deployment")
    })

    it('deploys with current_i_version set to 1', async () => {
      assert.equal(1, await dao.current_i_version(), "current_i_version is not 1 during deployment")
    })
  })

  describe('deactivate_whitelisted_freeze', () => {
    it('succeeds only when already activated', async () => {
      assert.equal(true, await dao.whitelisted_freeze_activated(), "incorrect value of whitelisted_freeze_activated")
      // call by non owner will revert
      await expectRevert(
        dao.deactivate_whitelisted_freeze({from: accounts[1]}),
        'caller is not the owner',
      )
      // deactivate whitelisted freeze
      await dao.deactivate_whitelisted_freeze({from: owner})
      assert.equal(false, await dao.whitelisted_freeze_activated(), "incorrect value of whitelisted_freeze_activated")
      // call when already deactivated will revert
      await expectRevert(
        dao.deactivate_whitelisted_freeze({from: owner}),
        'revert',
      )
    })
  })

  describe('activate_whitelisted_freeze', () => {
    it('succeeds only when already deactivated', async () => {
      assert.equal(false, await dao.whitelisted_freeze_activated(), "incorrect value of whitelisted_freeze_activated")
      // call by non owner will revert
      await expectRevert(
        dao.activate_whitelisted_freeze({from: accounts[1]}),
        'caller is not the owner',
      )
      // deactivate whitelisted freeze
      await dao.activate_whitelisted_freeze({from: owner})
      assert.equal(true, await dao.whitelisted_freeze_activated(), "incorrect value of whitelisted_freeze_activated")
      // call when already activated will revert
      await expectRevert(
        dao.activate_whitelisted_freeze({from: owner}),
        'revert',
      )
    })
  })


  describe('toggle_whitelist_status', () => {
    it('succeeds only when called by owner', async () => {
      assert.equal(false, await dao.is_whitelisted(accounts[1]), "incorrect whitelist status")
      // call by non owner will revert
      await expectRevert(
        dao.toggle_whitelist_status(accounts[1], true, {from: accounts[1]}),
        'caller is not the owner',
      )
      // whitelist accounts[1]
      await dao.toggle_whitelist_status(accounts[1], true, {from: owner})
      assert.equal(true, await dao.is_whitelisted(accounts[1]), "incorrect whitelist status")
      // revoke whitelist status of accounts[1]
      await dao.toggle_whitelist_status(accounts[1], false, {from: owner})
      assert.equal(false, await dao.is_whitelisted(accounts[1]), "incorrect whitelist status")
    })
  })


  describe('set_current_f_version', () => {
    it('succeeds only when version > 0', async () => {
      assert.equal(1, await dao.current_f_version(), "incorrect current_f_version")
      // call by non owner will revert
      await expectRevert(
        dao.set_current_f_version(2, {from: accounts[1]}),
        'caller is not the owner',
      )
      // set_current_f_version to 2
      await dao.set_current_f_version(2, {from: owner})
      assert.equal(2, await dao.current_f_version(), "incorrect current_f_version")
      // call with version = 0 will revert
      await expectRevert(
        dao.set_current_f_version(0, {from: owner}),
        'revert',
      )
    })
  })


  describe('set_current_i_version', () => {
    it('succeeds only when version > 0', async () => {
      assert.equal(1, await dao.current_i_version(), "incorrect current_i_version")
      // call by non owner will revert
      await expectRevert(
        dao.set_current_i_version(2, {from: accounts[1]}),
        'caller is not the owner',
      )
      // set_current_f_version to 2
      await dao.set_current_i_version(2, {from: owner})
      assert.equal(2, await dao.current_i_version(), "incorrect current_i_version")
      // call with version = 0 will revert
      await expectRevert(
        dao.set_current_i_version(0, {from: owner}),
        'revert',
      )
    })
  })


  describe('set_right', () => {
    it('allows owner to set f right', async () => {
      // Confirm f right contract address has not been set to 0x0
      assert.equal(await dao.contracts(1), 0x0, "f right contract address is not 0x0.")
      // call with invalid contract type will revert
      await expectRevert(
        dao.set_right(0, fRight.address, {from: owner}),
        'invalid contract type',
      )
      await expectRevert(
        dao.set_right(3, fRight.address, {from: owner}),
        'invalid contract type',
      )
      // Set f right contract address
      await dao.set_right(1, fRight.address, {from: owner})
      // Confirm f right contract address
      assert.equal(await dao.contracts(1), fRight.address, "f right address has not been set correctly.")
      // call by non owner will revert
      await expectRevert(
        dao.set_right(1, nft.address, {from: accounts[1]}),
        'caller is not the owner',
      )
      // call with invalid contract address will revert
      await expectRevert(
        dao.set_right(1, owner, {from: owner}),
        'invalid contract address',
      )
      // call with 0x0 as contract address will revert
      await expectRevert(
        dao.set_right(1, 0x0, {from: owner}),
        'invalid address',
      )
    })

    it('allows owner to set i right', async () => {
      // Confirm f right contract address has not been set to 0x0
      assert.equal(await dao.contracts(2), 0x0, "i right contract address is not 0x0.")
      // Set i right contract address
      await dao.set_right(2, iRight.address, {from: owner})
      // Confirm i right contract address
      assert.equal(await dao.contracts(2), iRight.address, "i right address has not been set correctly.")
      // call by non owner will revert
      await expectRevert(
        dao.set_right(2, nft.address, {from: accounts[1]}),
        'caller is not the owner',
      )
      // call with invalid contract address will revert
      await expectRevert(
        dao.set_right(2, owner, {from: owner}),
        'invalid contract address',
      )
      // call with 0x0 as contract address will revert
      await expectRevert(
        dao.set_right(2, 0x0, {from: owner}),
        'invalid address',
      )
    })
  })

  describe('set_right_api_base_url', () => {

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
        dao.set_right_api_base_url(0, API_BASE_URL, {from: owner}),
        'invalid contract type',
      )
      await expectRevert(
        dao.set_right_api_base_url(3, API_BASE_URL, {from: owner}),
        'invalid contract type',
      )
      // call with invalid owner will revert
      await expectRevert(
        dao.set_right_api_base_url(1, API_BASE_URL, {from: accounts[1]}),
        'caller is not the owner',
      )
      // Set apiBaseURL
      await dao.set_right_api_base_url(1, API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await fRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })

    it('allows owner to set api base url of i right', async () => {
      // Confirm apiBaseURL has not been set
      assert.equal(await iRight.baseTokenURI(), "", "apiBaseURL is not empty when deployed.")
      // call with invalid owner will revert
      await expectRevert(
        dao.set_right_api_base_url(2, API_BASE_URL, {from: accounts[1]}),
        'caller is not the owner',
      )
      // Set apiBaseURL
      await dao.set_right_api_base_url(2, API_BASE_URL, {from: owner})
      // Confirm apiBaseURL has been set
      assert.equal(await iRight.baseTokenURI(), API_BASE_URL, "apiBaseURL has not been set correctly.")
    })
  })

  describe('set_right_proxy_registry', () => {

    it('allows owner to set proxy registry of f right', async () => {
      // transfer i right ownership to accounts[1]
      await dao.set_right_proxy_registry(1, accounts[1]);
      // call with invalid contract type will revert
      await expectRevert(
        dao.set_right_proxy_registry(0, accounts[1]),
        'invalid contract type',
      )
      await expectRevert(
        dao.set_right_proxy_registry(3, accounts[1]),
        'invalid contract type',
      )
      // call by non owner will revert
      await expectRevert(
        dao.set_right_proxy_registry(1, accounts[1], {from: accounts[1]}),
        'caller is not the owner',
      )
    })

    it('allows owner to set proxy registry of i right', async () => {
      // transfer i right ownership to accounts[1]
      await dao.set_right_proxy_registry(2, accounts[1]);
      // call by non owner will revert
      await expectRevert(
        dao.set_right_proxy_registry(2, accounts[1], {from: accounts[1]}),
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
      await dao.deactivate_whitelisted_freeze({from: owner})
    })

    it('fails for incorrect _maxISupply', async () => {
      // call by non owner will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [2, 1, 1], {from: owner}),
        'revert',
      )
    })

    it('fails for incorrect _baseAssetId', async () => {
      // call by non owner will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, 2, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'revert',
      )
    })

    it('fails if whitelisted freeze is activated and caller is not whitelisted', async () => {
      // activate whitelisted freeze
      await dao.activate_whitelisted_freeze({from: owner})
      // call by non owner will revert
      await expectRevert(
        dao.freeze( _baseAssetAddress, _baseAssetId, _endTime, _isExclusive, [_maxISupply, 1, 1], {from: owner}),
        'revert',
      )
      // deactivate whitelisted freeze
      await dao.deactivate_whitelisted_freeze({from: owner})
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

  describe('issue_i', () => {
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
      // Call issue_i
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      // call by non owner will fail
      await expectRevert(
        dao.issue_i([_f_right_id, _expiry, 1], {from: accounts[2]}),
        'revert',
      )
      // call with expiry > endtime will fail
      await expectRevert(
        dao.issue_i([_f_right_id, _endTime+1, 1], {from: accounts[2]}),
        'revert',
      )
      // Call issue_i again will work
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      // call issue_i again will fail
      await expectRevert(
        dao.issue_i([_f_right_id, _expiry, 1], {from: owner}),
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
      // call issue_i will fail
      await expectRevert(
        dao.issue_i([_f_right_id, _expiry, 1], {from: owner}),
        'revert',
      )
    })
  })

  describe('revoke_i', () => {
    let _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply

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
      // Call issue_i
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(7, await iRight.currentTokenId(), 'is wrong id value')
      // call revoke_i will fail with non owner
      await expectRevert(
        dao.revoke_i(7, {from: accounts[1]}),
        'revert',
      )
      // Call revoke_i
      await dao.revoke_i(7, {from: owner})
      // Call issue_i
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(8, await iRight.currentTokenId(), 'is wrong id value')
      // Call revoke_i
      await dao.revoke_i(8, {from: owner})
      // 1-1
      // call issue_i will fail
      await expectRevert(
        dao.issue_i([_f_right_id, _expiry, 1], {from: owner}),
        'revert',
      )
      // Call revoke_i
      await dao.revoke_i(6, {from: owner})
      // call revoke_i will fail
      await expectRevert(
        dao.revoke_i(8, {from: owner}),
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
      // Call issue_i
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      currentTokenId = await iRight.currentTokenId()
      assert.equal(10, currentTokenId.toString(), 'is wrong id value')
      // Call revoke_i
      await dao.revoke_i(10, {from: owner})
      // Call issue_i
      await dao.issue_i([_f_right_id, _expiry, 1], {from: owner})
      assert.equal(11, await iRight.currentTokenId(), 'is wrong id value')
      // Call revoke_i
      await dao.revoke_i(11, {from: owner})
      // Call revoke_i
      await dao.revoke_i(9, {from: owner})
      // call unfreeze will succeed
      await dao.unfreeze(_f_right_id, {from: owner})
      // call unfreeze will fail
      await expectRevert(
        dao.unfreeze(_f_right_id, {from: owner}),
        'revert',
      )
    })
  })

});
