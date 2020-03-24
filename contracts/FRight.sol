pragma solidity ^0.5.11;

import "./Right.sol";

/**
 * @title FRight
 * FRight - a contract for Frozen Rights
 */
contract FRight is Right {

  struct Metadata {
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    address baseAssetAddress;
    uint256 baseAssetId;
    bool isExclusive;
    uint256 maxISupply;
    uint256 circulatingISupply;
  }

  // stores a `Metadata` struct for each FRight.
  mapping(uint256 => Metadata) public metadata;
  // stores information for frozen NFTs
  mapping(address => mapping(uint256 => bool)) public isFrozen;

  constructor() TradeableERC721Token("FRight Token", "FRT", address(0)) public {}



  /**
    * @dev updates token metadata
    */
  function _updateMetadata(uint256 _startTime, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply, uint256 _circulatingISupply) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.startTime = _startTime;
    _meta.endTime = _endTime;
    _meta.baseAssetAddress = _baseAssetAddress;
    _meta.baseAssetId = _baseAssetId;
    _meta.isExclusive = _isExclusive;
    _meta.maxISupply = _maxISupply;
    _meta.circulatingISupply = _circulatingISupply;
  }

  /**
    * @dev Add details to Token metadata after mint.
    * @param _to address of the future owner of the token
    */
  function freeze(address _to, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply) public onlyOwner returns (uint256 _rightId) {
    _rightId = 0;
    require(!isFrozen[_baseAssetAddress][_baseAssetId], "Asset is already frozen");
    isFrozen[_baseAssetAddress][_baseAssetId] = true;
    if (_isExclusive) {
        require(_maxISupply == 1);
    }
    mintTo(_to);
    _updateMetadata(now, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, 1);
    _rightId = currentTokenId();
  }

  function unfreeze(address _from, uint256 _tokenId) public onlyOwner returns (bool _ok) {
    _ok = false;
    Metadata storage _meta = metadata[_tokenId];
    require(isFrozen[_meta.baseAssetAddress][_meta.baseAssetId], "Asset is not frozen");
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    delete isFrozen[_meta.baseAssetAddress][_meta.baseAssetId];
    delete metadata[_tokenId];
    _burn(_from, _tokenId);
    _ok = true;
  }


  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat(Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat("f/", Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.bool2str(_meta.isExclusive), "/", Strings.uint2str(_meta.maxISupply), "/"),
        Strings.uint2str(_meta.circulatingISupply)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  function incrementCirculatingISupply(uint256 _tokenId, uint256 _amount) external onlyOwner returns (bool _ok) {
    _ok = false;
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    if (_meta.maxISupply.sub(_meta.circulatingISupply) >= _amount) {
      _meta.circulatingISupply += _amount;
      _ok = true;
    }
  }

  function decrementCirculatingISupply(uint256 _tokenId, uint256 _amount) external onlyOwner returns (bool _ok) {
    _ok = false;
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    if (_meta.circulatingISupply.sub(_amount) >= 0) {
      require(_meta.maxISupply.sub(_amount) >= _meta.circulatingISupply.sub(_amount));
      _meta.circulatingISupply -= _amount;
      _meta.maxISupply -= _amount;
      _ok = true;
    }
  }

  function isUnfreezable(uint256 _tokenId) external view returns (bool _unfreezable) {
    Metadata storage _meta = metadata[_tokenId];
    require(isFrozen[_meta.baseAssetAddress][_meta.baseAssetId], "Asset is not frozen");
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    _unfreezable = (now >= _meta.endTime) || (_meta.circulatingISupply == 0);
  }

  function baseAsset(uint256 _tokenId) external view returns (address _baseAssetAddress, uint256 _baseAssetId) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    _baseAssetAddress = _meta.baseAssetAddress;
    _baseAssetId = _meta.baseAssetId;
  }

  function isIMintAble(uint256 _tokenId) external view returns (bool _mintable) {
    _mintable = false;
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    if (_meta.maxISupply.sub(_meta.circulatingISupply) > 0) {
      _mintable = true;
    }
  }

  function endTimeAndISupplies(uint256 _tokenId) external view returns (uint256 _endTime, uint256 _maxISupply, uint256 _circulatingISupply) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    _endTime = _meta.endTime;
    _maxISupply = _meta.maxISupply;
    _circulatingISupply = _meta.circulatingISupply;
  }
}
