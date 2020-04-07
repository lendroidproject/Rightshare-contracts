pragma solidity ^0.5.11;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';

import "./FRight.sol";
import "./IRight.sol";


contract RightsDao is Ownable, IERC721Receiver {

  using Address for address;

  int128 constant CONTRACT_TYPE_RIGHT_F = 1;
  int128 constant CONTRACT_TYPE_RIGHT_I = 2;

  mapping(int128 => address) public contracts;

  function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
      return this.onERC721Received.selector;
  }

  /**
    * @dev Set address of the Right.
    * @param rightType type of Right contract
    * @param rightAddress address of Right contract
    */
  function set_right(int128 rightType, address rightAddress) external onlyOwner returns (bool ok) {
    ok = false;
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    require(rightAddress.isContract(), "invalid contract address");
    contracts[rightType] = rightAddress;
    ok = true;
  }

  /**
    * @dev Transfer ownership of the RIght contract.
    * @param rightType type of Right contract
    * @param to address of the new owner
    */
  function transfer_right_ownership(int128 rightType, address to) external onlyOwner returns (bool ok) {
    ok = false;
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    if (rightType == CONTRACT_TYPE_RIGHT_F) {
      FRight(contracts[rightType]).transferOwnership(to);
    }
    else {
      IRight(contracts[rightType]).transferOwnership(to);
    }
    ok = true;
  }

  /**
    * @dev Transfer ownership of the RIght contract.
    * @param rightType type of Right contract
    * @param proxyRegistryAddress address of the Right's Proxy Registry
    */
  function set_right_proxy_registry(int128 rightType, address proxyRegistryAddress) external onlyOwner returns (bool ok) {
    ok = false;
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    if (rightType == CONTRACT_TYPE_RIGHT_F) {
      FRight(contracts[rightType]).setProxyRegistryAddress(proxyRegistryAddress);
    }
    else {
      IRight(contracts[rightType]).setProxyRegistryAddress(proxyRegistryAddress);
    }
    ok = true;
  }

  /**
    * @dev Freeze a given ERC721 Token
    * @param baseAssetAddress address of the ERC721 Token
    * @param baseAssetId id of the ERC721 Token
    * @param expiry timestamp until which the ERC721 Token is locked in the dao
    * @param isExclusive exclusivity of IRights for the ERC721 Token
    * @param maxISupply maximum supply of IRights for the ERC721 Token
    */
  function freeze(address baseAssetAddress, uint256 baseAssetId, uint256 expiry, bool isExclusive, uint256 maxISupply) external returns (bool ok) {
    ok = false;
    uint256 fRightId = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).freeze(msg.sender, expiry, baseAssetAddress, baseAssetId, isExclusive, maxISupply);
    require(fRightId != 0, "freeze unsuccessful");
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue(msg.sender, fRightId, expiry, baseAssetAddress, baseAssetId, isExclusive, maxISupply, 1);
    ERC721(baseAssetAddress).safeTransferFrom(msg.sender, address(this), baseAssetId);
    ok = true;
  }

  /**
    * @dev Mint an IRight token for a given FRight token Id
    * @param fRightId id of the FRight Token
    * @param expiry indicates timestamp until which the newly minted IRight is usable
    */
  function issue_i(uint256 fRightId, uint256 expiry) external returns (bool ok) {
    ok = false;
    bool isIMintAble = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isIMintAble(fRightId);
    require(isIMintAble);
    address fRightOwner = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).ownerOf(fRightId);
    require(fRightOwner == msg.sender);
    bool exclusivity = false;
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(fRightId);
    (uint256 fEndTime, uint256 fMaxISupply, uint256 circulatingISupply) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).endTimeAndISupplies(fRightId);
    require(expiry <= fEndTime);
    if (fMaxISupply == 1) {
      require(circulatingISupply == 0);
      exclusivity = true;
    }
    circulatingISupply += 1;
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue(msg.sender, fRightId, expiry, baseAssetAddress, baseAssetId, exclusivity, fMaxISupply, circulatingISupply);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).incrementCirculatingISupply(fRightId, 1);
    ok = true;
  }

  /**
    * @dev Burn an IRight token for a given IRight token Id
    * @param iRightId id of the IRight Token
    */
  function revoke_i(uint256 iRightId) external returns (bool ok) {
    ok = false;
    address iRightOwner = IRight(contracts[CONTRACT_TYPE_RIGHT_I]).ownerOf(iRightId);
    require(iRightOwner == msg.sender);
    (address baseAssetAddress, uint256 baseAssetId) = IRight(contracts[CONTRACT_TYPE_RIGHT_I]).baseAsset(iRightId);
    bool isBaseAssetFrozen = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isFrozen(baseAssetAddress, baseAssetId);
    if (isBaseAssetFrozen) {
      uint256 fRightId = IRight(contracts[CONTRACT_TYPE_RIGHT_I]).parentId(iRightId);
      require(fRightId != 0);
      FRight(contracts[CONTRACT_TYPE_RIGHT_F]).decrementCirculatingISupply(fRightId, 1);
    }
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).revoke(msg.sender, iRightId);
    ok = true;
  }

  /**
    * @dev Burn an FRight token for a given FRight token Id, and
    * @param fRightId id of the FRight Token
    */
  function unfreeze(uint256 fRightId) external returns (bool ok) {
    ok = false;
    bool isUnfreezable = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isUnfreezable(fRightId);
    require(isUnfreezable);
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(fRightId);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).unfreeze(msg.sender, fRightId);
    ERC721(baseAssetAddress).transferFrom(address(this), msg.sender, baseAssetId);
    ok = true;
  }

}
