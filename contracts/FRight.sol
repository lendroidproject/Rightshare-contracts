pragma solidity 0.5.11;

import "./Right.sol";

/**
 * @title FRight
 * FRight - a contract for Frozen Rights
 */
contract FRight is Right {

  struct Metadata {
    uint256 version;
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
  function _updateMetadata(uint256 _version, uint256 _startTime, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply, uint256 _circulatingISupply) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = _version;
    _meta.startTime = _startTime;
    _meta.endTime = _endTime;
    _meta.baseAssetAddress = _baseAssetAddress;
    _meta.baseAssetId = _baseAssetId;
    _meta.isExclusive = _isExclusive;
    _meta.maxISupply = _maxISupply;
    _meta.circulatingISupply = _circulatingISupply;
  }

  /**
    * @dev Mint FRight Token and update mateadata
    * @param addresses : address array [_to, _baseAssetAddress]
    * @param values : uint256 array [_endTime, _baseAssetId, _maxISupply, _version]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    */
  function freeze(address[2] memory addresses, bool isExclusive, uint256[4] memory values) public onlyOwner returns (uint256 _rightId) {
    _rightId = 0;
    require(!isFrozen[addresses[1]][values[1]], "Asset is already frozen");
    isFrozen[addresses[1]][values[1]] = true;
    if (isExclusive) {
        require(values[2] == 1);
    }
    mintTo(addresses[0]);
    _updateMetadata(values[3], now, values[0], addresses[1], values[1], isExclusive, values[2], 1);
    _rightId = currentTokenId();
  }

  function unfreeze(address _from, uint256 _tokenId) public onlyOwner {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    require(isFrozen[_meta.baseAssetAddress][_meta.baseAssetId], "Asset is not frozen");
    require((now >= _meta.endTime) || (_meta.circulatingISupply == 0), "FRT: token is not unfreezable");
    delete isFrozen[_meta.baseAssetAddress][_meta.baseAssetId];
    delete metadata[_tokenId];
    _burn(_from, _tokenId);
  }

  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat(Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat("f/", Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.bool2str(_meta.isExclusive), "/", Strings.uint2str(_meta.maxISupply), "/"),
        Strings.strConcat(Strings.uint2str(_meta.circulatingISupply) , "/"),
        Strings.uint2str(_meta.version)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  function incrementCirculatingISupply(uint256 _tokenId, uint256 _amount) external onlyOwner {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    require(_meta.maxISupply.sub(_meta.circulatingISupply) >= _amount, "Circulating I Supply cannot be incremented");
    _meta.circulatingISupply += _amount;
  }

  function decrementCirculatingISupply(uint256 _tokenId, uint256 _amount) external onlyOwner {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    if (_meta.circulatingISupply.sub(_amount) >= 0) {
      require(_meta.maxISupply.sub(_amount) >= _meta.circulatingISupply.sub(_amount));
      _meta.circulatingISupply -= _amount;
      _meta.maxISupply -= _amount;
    }
  }

  function isUnfreezable(uint256 _tokenId) external view returns (bool _unfreezable) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    require(isFrozen[_meta.baseAssetAddress][_meta.baseAssetId], "Asset is not frozen");
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

  function endTimeAndMaxSupply(uint256 _tokenId) external view returns (uint256 _endTime, uint256 _maxISupply) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    _endTime = _meta.endTime;
    _maxISupply = _meta.maxISupply;
  }
}
