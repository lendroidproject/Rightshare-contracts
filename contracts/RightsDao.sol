pragma solidity 0.5.11;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';

import "./FRight.sol";
import "./IRight.sol";


contract RightsDao is Ownable, IERC721Receiver {

  using Address for address;
  using SafeMath for uint256;

  int128 constant CONTRACT_TYPE_RIGHT_F = 1;
  int128 constant CONTRACT_TYPE_RIGHT_I = 2;

  mapping(int128 => address) public contracts;

  mapping(address => bool) public is_whitelisted;

  bool public whitelisted_freeze_activated = true;

  uint256 public current_f_version = 1;
  uint256 public current_i_version = 1;

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
    * @dev set whitelisted_freeze_activated value as true or false
    * @param activate toggle value
    */
  function _toggle_whitelisted_freeze(bool activate) internal {
    if (activate) {
      require(!whitelisted_freeze_activated);
    }
    else {
      require(whitelisted_freeze_activated);
    }
    whitelisted_freeze_activated = activate;
  }


  /**
    * @dev set whitelisted_freeze_activated value as true
    */
  function activate_whitelisted_freeze() external onlyOwner returns (bool ok) {
    ok = false;
    _toggle_whitelisted_freeze(true);
    ok = true;
  }


  /**
    * @dev set whitelisted_freeze_activated value as false
    */
  function deactivate_whitelisted_freeze() external onlyOwner returns (bool ok) {
    ok = false;
    _toggle_whitelisted_freeze(false);
    ok = true;
  }


  /**
    * @dev add / remove given address to / from whitelist
    * @param addr given address
    * @param status whitelist status of given address
    */
  function toggle_whitelist_status(address addr, bool status) external onlyOwner returns (bool ok) {
    ok = false;
    is_whitelisted[addr] = status;
    ok = true;
  }


  /**
    * @dev Increment current f version
    */
  function increment_current_f_version() external onlyOwner returns (bool ok) {
    ok = false;
    current_f_version = current_f_version.add(1);
    ok = true;
  }

  /**
    * @dev Increment current i version
    */
  function increment_current_i_version() external onlyOwner returns (bool ok) {
    ok = false;
    current_i_version = current_i_version.add(1);
    ok = true;
  }


  /**
    * @dev Set base url of the server API representing the metadata of a RIght Token
    * @param rightType type of Right contract
    * @param url API base url
    */
  function set_right_api_base_url(int128 rightType, string calldata url) external onlyOwner returns (bool ok) {
    ok = false;
    require((rightType == CONTRACT_TYPE_RIGHT_F) || (rightType == CONTRACT_TYPE_RIGHT_I), "invalid contract type");
    if (rightType == CONTRACT_TYPE_RIGHT_F) {
      FRight(contracts[rightType]).setApiBaseUrl(url);
    }
    else {
      IRight(contracts[rightType]).setApiBaseUrl(url);
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
    * @param values uint256 array [maxISupply, f_version, i_version]
    */
  function freeze(address baseAssetAddress, uint256 baseAssetId, uint256 expiry, bool isExclusive, uint256[3] calldata values) external returns (bool ok) {
    ok = false;
    if (whitelisted_freeze_activated) {
      require(is_whitelisted[msg.sender]);
    }
    require((values[1] > 0) && (values[1] <= current_f_version), "invalid f version");
    require((values[2] > 0) && (values[2] <= current_i_version), "invalid i version");
    uint256 fRightId = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).freeze([msg.sender, baseAssetAddress], isExclusive, [expiry, baseAssetId, values[0], values[1]]);
    require(fRightId != 0, "freeze unsuccessful");
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue([msg.sender, baseAssetAddress], isExclusive, [fRightId, expiry, baseAssetId, values[2]]);
    ERC721(baseAssetAddress).safeTransferFrom(msg.sender, address(this), baseAssetId);
    ok = true;
  }

  /**
    * @dev Mint an IRight token for a given FRight token Id
    * @param values uint256 array [fRightId, expiry, i_version]
    */
  function issue_i(uint256[3] calldata values) external returns (bool ok) {
    ok = false;
    require((values[2] > 0) && (values[2] <= current_i_version), "invalid i version");
    require(FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isIMintAble(values[0]));
    require(msg.sender == FRight(contracts[CONTRACT_TYPE_RIGHT_F]).ownerOf(values[0]));
    (uint256 fEndTime, uint256 fMaxISupply) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).endTimeAndMaxSupply(values[0]);
    require(fMaxISupply > 0);
    require(values[1] <= fEndTime);
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(values[0]);
    IRight(contracts[CONTRACT_TYPE_RIGHT_I]).issue([msg.sender, baseAssetAddress], false, [values[0], values[1], baseAssetId, values[2]]);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).incrementCirculatingISupply(values[0], 1);
    ok = true;
  }

  /**
    * @dev Burn an IRight token for a given IRight token Id
    * @param iRightId id of the IRight Token
    */
  function revoke_i(uint256 iRightId) external returns (bool ok) {
    ok = false;
    require(msg.sender == IRight(contracts[CONTRACT_TYPE_RIGHT_I]).ownerOf(iRightId));
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
    require(FRight(contracts[CONTRACT_TYPE_RIGHT_F]).isUnfreezable(fRightId));
    (address baseAssetAddress, uint256 baseAssetId) = FRight(contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(fRightId);
    FRight(contracts[CONTRACT_TYPE_RIGHT_F]).unfreeze(msg.sender, fRightId);
    ERC721(baseAssetAddress).transferFrom(address(this), msg.sender, baseAssetId);
    ok = true;
  }

}
