# @version 0.1.0b16
# @notice Implementation of the RightsDao contract
# @dev THIS CONTRACT HAS NOT BEEN AUDITED


contract Right:
  def setProxyRegistryAddress(_proxyRegistryAddress: address) -> bool: modifying
  def baseAsset(_tokenId: uint256) -> (address, uint256): constant
  def ownerOf(_tokenId: uint256) -> address: constant
  def transferOwnership(newOwner: address): modifying


contract ERC721:
  def transferFrom(_from: address, _to: address, _tokenId: uint256): modifying


contract FRight:
  def freeze(_to: address, _endTime: timestamp, _baseAssetAddress: address, _baseAssetId: uint256, _isExclusive: bool, _maxISupply: uint256) -> uint256: modifying
  def unfreeze(_from: address, _right_id: uint256) -> bool: modifying
  def isFrozen(_baseAssetAddress: address, _baseAssetId: uint256) -> bool: constant
  def isUnfreezable(_tokenId: uint256) -> bool: constant
  def isIMintAble(_tokenId: uint256) -> bool: constant
  def endTimeAndISupplies(_tokenId: uint256) -> (uint256, uint256, uint256): constant
  def incrementCirculatingISupply(_tokenId: uint256, _amount: uint256) -> bool: modifying
  def decrementCirculatingISupply(_tokenId: uint256, _amount: uint256) -> bool: modifying


contract IRight:
  def issue(_to: address, _parentId: uint256, _endTime: timestamp, _baseAssetAddress: address, _baseAssetId: uint256, _isExclusive: bool, _maxISupply: uint256, _serialNumber: uint256) -> bool: modifying
  def revoke(_from: address, _right_id: uint256) -> bool: modifying
  def parentId(_tokenId: uint256) -> uint256: constant


owner: public(address)

# contract_type => contract_address
contracts: public(map(int128, address))

CONTRACT_TYPE_RIGHT_F: constant(int128) = 1
CONTRACT_TYPE_RIGHT_I: constant(int128) = 2


@public
def __init__():
  self.owner = msg.sender


@public
def set_right(_type: int128, _address: address) -> bool:
  assert msg.sender == self.owner
  assert _type in [CONTRACT_TYPE_RIGHT_F, CONTRACT_TYPE_RIGHT_I]
  assert _address.is_contract
  self.contracts[_type] = _address
  return True


@public
def transfer_right_ownership(_type: int128, _to: address) -> bool:
  assert msg.sender == self.owner
  assert _type in [CONTRACT_TYPE_RIGHT_F, CONTRACT_TYPE_RIGHT_I]
  assert self.contracts[_type].is_contract
  Right(self.contracts[_type]).transferOwnership(_to)
  return True


@public
def set_right_proxy_registry(_type: int128, _proxy_registry: address) -> bool:
  assert msg.sender == self.owner
  assert _type in [CONTRACT_TYPE_RIGHT_F, CONTRACT_TYPE_RIGHT_I]
  assert self.contracts[_type].is_contract
  # set _proxyRegistryAddress
  _external_call_successful: bool = Right(self.contracts[_type]).setProxyRegistryAddress(_proxy_registry)
  assert _external_call_successful
  return True


@public
def freeze(_base_asset_address: address, _base_asset_id: uint256, _expiry: timestamp, _is_exclusive: bool, _max_i_supply: uint256) -> bool:
  _f_right_id: uint256 = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).freeze(msg.sender, _expiry, _base_asset_address, _base_asset_id, _is_exclusive, _max_i_supply)
  assert not _f_right_id == 0
  _external_call_successful: bool = IRight(self.contracts[CONTRACT_TYPE_RIGHT_I]).issue(msg.sender, _f_right_id, _expiry, _base_asset_address, _base_asset_id, _is_exclusive, _max_i_supply, 1)
  assert _external_call_successful
  ERC721(_base_asset_address).transferFrom(msg.sender, self, _base_asset_id)
  return True


@public
def issue_i(_f_right_id: uint256, _expiry: uint256) -> bool:
  _is_i_mintable: bool = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).isIMintAble(_f_right_id)
  assert _is_i_mintable
  _f_right_owner: address = Right(self.contracts[CONTRACT_TYPE_RIGHT_F]).ownerOf(_f_right_id)
  assert _f_right_owner == msg.sender
  _base_asset_address: address = ZERO_ADDRESS
  _base_asset_id: uint256 = 0
  _f_end_time: uint256 = 0
  _f_max_i_supply: uint256 = 0
  _circulating_i_supply: uint256 = 0
  _exclusivity: bool = False
  _base_asset_address, _base_asset_id = Right(self.contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(_f_right_id)
  _f_end_time, _f_max_i_supply, _circulating_i_supply = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).endTimeAndISupplies(_f_right_id)
  assert _expiry <= _f_end_time
  if _f_max_i_supply == 1:
    _exclusivity = True
    assert _circulating_i_supply == 0
  _circulating_i_supply += 1
  _external_call_successful: bool = IRight(self.contracts[CONTRACT_TYPE_RIGHT_I]).issue(msg.sender, _f_right_id, _expiry, _base_asset_address, _base_asset_id, _exclusivity, _f_max_i_supply, _circulating_i_supply)
  assert _external_call_successful
  _external_call_successful = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).incrementCirculatingISupply(_f_right_id, 1)
  assert _external_call_successful
  return True


@public
def revoke_i(_i_right_id: uint256) -> bool:
  _i_right_owner: address = Right(self.contracts[CONTRACT_TYPE_RIGHT_I]).ownerOf(_i_right_id)
  assert _i_right_owner == msg.sender
  _base_asset_address: address = ZERO_ADDRESS
  _base_asset_id: uint256 = 0
  _base_asset_address, _base_asset_id = Right(self.contracts[CONTRACT_TYPE_RIGHT_I]).baseAsset(_i_right_id)
  _is_base_asset_frozen: bool = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).isFrozen(_base_asset_address, _base_asset_id)
  _external_call_successful: bool = False
  if _is_base_asset_frozen:
    _f_right_id: uint256 = IRight(self.contracts[CONTRACT_TYPE_RIGHT_I]).parentId(_i_right_id)
    assert not _f_right_id == 0
    _external_call_successful = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).decrementCirculatingISupply(_f_right_id, 1)
    assert _external_call_successful
  _external_call_successful = IRight(self.contracts[CONTRACT_TYPE_RIGHT_I]).revoke(msg.sender, _i_right_id)
  assert _external_call_successful
  return True


@public
def unfreeze(_f_right_id: uint256) -> bool:
  _is_unfreezable: bool = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).isUnfreezable(_f_right_id)
  assert _is_unfreezable
  _base_asset_address: address = ZERO_ADDRESS
  _base_asset_id: uint256 = 0
  _base_asset_address, _base_asset_id = Right(self.contracts[CONTRACT_TYPE_RIGHT_F]).baseAsset(_f_right_id)
  _external_call_successful: bool = FRight(self.contracts[CONTRACT_TYPE_RIGHT_F]).unfreeze(msg.sender, _f_right_id)
  assert _external_call_successful
  ERC721(_base_asset_address).transferFrom(self, msg.sender, _base_asset_id)
  return True
