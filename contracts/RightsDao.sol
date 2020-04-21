pragma solidity 0.5.11;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';

import "./FRight.sol";
import "./IRight.sol";


/** @title RightsDao
 * @author Lendroid Foundation
 * @notice DAO that handles NFTs, FRights, and IRights
 * @dev Tested with 100% branch coverage. Pending audit certificate.
 */
contract RightsDao is Ownable, IERC721Receiver {

  using Address for address;
  using SafeMath for uint256;

  int128 constant CONTRACT_TYPE_RIGHT_F = 1;
  int128 constant CONTRACT_TYPE_RIGHT_I = 2;

  // stores contract addresses of FRight and IRight
  mapping(int128 => address) public contracts;

  // stores addresses that have been whitelisted to perform freeze calls
  mapping(address => bool) public isWhitelisted;

  // stores whether freeze calls require caller to be whitelisted
  bool public whitelistedFreezeActivated = true;

  // stores latest current version of FRight
  uint256 public currentFVersion = 1;
  // stores latest current version of IRight
  uint256 public currentIVersion = 1;

  constructor(address fRightContractAddress, address iRightContractAddress) public {
    require(fRightContractAddress.isContract(), "invalid fRightContractAddress");
    require(iRightContractAddress.isContract(), "invalid iRightContractAddress");
    contracts[CONTRACT_TYPE_RIGHT_F] = fRightContractAddress;
    contracts[CONTRACT_TYPE_RIGHT_I] = iRightContractAddress;
  }

  function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
    * @notice Internal function to record if freeze calls must be made only by whitelisted accounts
    * @dev set whitelistedFreezeActivated value as true or false
    * @param activate : bool indicating the toggle value
    */
  function _toggleWhitelistedFreeze(bool activate) internal {
    if (activate) {
      require(!whitelistedFreezeActivated, "whitelisted freeze is already activated");
    }
    else {
      require(whitelistedFreezeActivated, "whitelisted freeze is already deactivated");
    }
    whitelistedFreezeActivated = activate;
  }

  /**
    * @notice Allows the owner to specify that freeze calls require sender to be whitelisted
    * @dev set whitelistedFreezeActivated value as true
    */
  function activateWhitelistedFreeze() external onlyOwner returns (bool) {
    _toggleWhitelistedFreeze(true);
    return true;
  }

  /**
    * @notice Allows the owner to specify that freeze calls do not require sender to be whitelisted
    * @dev set whitelistedFreezeActivated value as true
    */
  function deactivateWhitelistedFreeze() external onlyOwner returns (bool) {
    _toggleWhitelistedFreeze(false);
    return true;
  }

  /**
    * @notice Allows owner to add / remove given address to / from whitelist
    * @param addr : given address
    * @param status : bool indicating whitelist status of given address
    * @return bool : indicating the whitelist status has been set
    */
  function toggleWhitelistStatus(address addr, bool status) external onlyOwner returns (bool) {
    require(addr != address(0), "invalid address");
    isWhitelisted[addr] = status;
    return true;
  }

  /**
    * @notice Allows owner to increment the current f version
    * @dev Increment currentFVersion by 1
    * @return bool : indicating the current f version has been incremented
    */
  function incrementCurrentFVersion() external onlyOwner returns (bool) {
    currentFVersion = currentFVersion.add(1);
    return true;
  }

  /**
    * @notice Allows owner to increment the current i version
    * @dev Increment currentIVersion by 1
    * @return bool : indicating the current i version has been incremented
    */
  function incrementCurrentIVersion() external onlyOwner returns (bool) {
    currentIVersion = currentIVersion.add(1);
    return true;
  }

  /**
    * @notice Allows owner to set the base api url of F or I Right token
    * @dev Set base url of the server API representing the metadata of a Right Token
    * @param rightType type of Right contract
    * @param url API base url
    * @return bool : indicating the base api url of the Right token has been set
    */
  function setRightApiBaseUrl(int128 rightType, string calldata url) external onlyOwner returns (bool) {
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    if (rightType == CONTRACT_TYPE_RIGHT_F) {
      FRight(contracts[rightType]).setApiBaseUrl(url);
    }
    else {
      IRight(contracts[rightType]).setApiBaseUrl(url);
    }
    return true;
  }

  /**
    * @notice Allows owner to set the proxy registry address of F or I Right token
    * @dev Set proxy registry address of the Right Token
    * @param rightType type of Right contract
    * @param proxyRegistryAddress address of the Right's Proxy Registry
    * @return bool : indicating the proxy registry address of the Right token has been set
    */
  function setRightProxyRegistry(int128 rightType, address proxyRegistryAddress) external onlyOwner returns (bool) {
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    if (rightType == CONTRACT_TYPE_RIGHT_F) {
      FRight(contracts[rightType]).setProxyRegistryAddress(proxyRegistryAddress);
    }
    else {
      IRight(contracts[rightType]).setProxyRegistryAddress(proxyRegistryAddress);
    }
    return true;
  }

  /**
    * @notice Freezes a given NFT Token
    * @dev Send the NFT to this contract, mint 1 FRight Token and 1 IRight Token
    * @param baseAssetAddress : address of the NFT
    * @param baseAssetId : id of the NFT
    * @param expiry : timestamp until which the NFT is locked in the dao
    * @param values : uint256 array [maxISupply, f_version, i_version]
    * @return bool : indicating the given NFT has been frozen
    */
  function freeze(address baseAssetAddress, uint256 baseAssetId, uint256 expiry, uint256[3] calldata values) external returns (bool) {
    if (whitelistedFreezeActivated) {
      require(isWhitelisted[msg.sender], "sender is not whitelisted");
    }
    require(values[0] > 0, "invalid maximum I supply");
    require(expiry > block.timestamp, "expiry should be in the future");
    require((values[1] > 0) && (values[1] <= currentFVersion), "invalid f version");
    require((values[2] > 0) && (values[2] <= currentIVersion), "invalid i version");
    uint256 fRightId = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).freeze([msg.sender, baseAssetAddress], [expiry, baseAssetId, values[0], values[1]]);
    // set exclusivity of IRights for the NFT
    bool isExclusive = values[0] == 1;
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue([msg.sender, baseAssetAddress], isExclusive, [fRightId, expiry, baseAssetId, values[2]]);
    ERC721(baseAssetAddress).safeTransferFrom(msg.sender, address(this), baseAssetId);
    return true;
  }

  /**
    * @notice Issues a IRight for a given FRight
    * @dev Check if IRight can be minted, Mint 1 IRight, Increment FRight.circulatingISupply by 1
    * @param values : uint256 array [fRightId, expiry, i_version]
    * @return bool : indicating 1 IRight was successfully issued
    */
  function issueI(uint256[3] calldata values) external returns (bool) {
    require(values[1] > block.timestamp, "expiry should be in the future");
    require((values[2] > 0) && (values[2] <= currentIVersion), "invalid i version");
    require(FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isIMintable(values[0]), "cannot mint iRight");
    require(msg.sender == FRight(contracts[CONTRACT_TYPE_RIGHT_F]).ownerOf(values[0]), "sender is not the owner of fRight");
    uint256 fEndTime = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).endTime(values[0]);
    require(values[1] <= fEndTime, "expiry cannot exceed fRight expiry");
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(values[0]);
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue([msg.sender, baseAssetAddress], false, [values[0], values[1], baseAssetId, values[2]]);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).incrementCirculatingISupply(values[0], 1);
    return true;
  }

  /**
    * @notice Revokes a given IRight. The IRight can be revoked at any time.
    * @dev Burn the IRight token. If the corresponding FRight exists, decrement its circulatingISupply by 1
    * @param iRightId : id of the IRight token
    * @return bool : indicating the IRight was successfully revoked
    */
  function revokeI(uint256 iRightId) external returns (bool) {
    require(msg.sender == IRight(contracts[CONTRACT_TYPE_RIGHT_I]).ownerOf(iRightId), "sender is not the owner of iRight");
    (address baseAssetAddress, uint256 baseAssetId) = IRight(contracts[CONTRACT_TYPE_RIGHT_I]).baseAsset(iRightId);
    bool isBaseAssetFrozen = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isFrozen(baseAssetAddress, baseAssetId);
    if (isBaseAssetFrozen) {
      uint256 fRightId = IRight(contracts[CONTRACT_TYPE_RIGHT_I]).parentId(iRightId);
      FRight(contracts[CONTRACT_TYPE_RIGHT_F]).decrementCirculatingISupply(fRightId, 1);
    }
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).revoke(msg.sender, iRightId);
    return true;
  }

  /**
    * @notice Unfreezes a given FRight. The FRight can be unfrozen if either it has expired or it has nil issued IRights
    * @dev Burn the FRight token for a given token Id, and return the original NFT back to the caller
    * @param fRightId : id of the FRight token
    * @return bool : indicating the FRight was successfully unfrozen
    */
  function unfreeze(uint256 fRightId) external returns (bool) {
    require(FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isUnfreezable(fRightId), "fRight is unfreezable");
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(fRightId);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).unfreeze(msg.sender, fRightId);
    ERC721(baseAssetAddress).transferFrom(address(this), msg.sender, baseAssetId);
    return true;
  }

}
