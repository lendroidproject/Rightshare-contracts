pragma solidity ^0.6.0;

import "./Right.sol";

/**
 * @title IRight
 * IRight - a contract for NFT exclusive / non-exclusive Rights.
 */
contract IRight is Right {

  struct Metadata {
    uint256 parentId;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    address baseAssetAddress;
    uint256 baseAssetId;
    bool isExclusive;
    uint256 maxISupply;
    uint256 serialNumber;
  }

  // stores a `Metadata` struct for each IRight.
  mapping(uint256 => Metadata) public metadata;

  constructor() TradeableERC721Token("IRight Token", "IRT", address(0)) public {}

  /**
    * @dev updates token metadata
    */
  function _updateMetadata(uint256 _parentId, uint256 _startTime, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply, uint256 _serialNumber) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.parentId = _parentId;
    _meta.startTime = _startTime;
    _meta.endTime = _endTime;
    _meta.baseAssetAddress = _baseAssetAddress;
    _meta.baseAssetId = _baseAssetId;
    _meta.isExclusive = _isExclusive;
    _meta.maxISupply = _maxISupply;
    _meta.serialNumber = _serialNumber;
  }

  /**
    * @dev Add details to Token metadata after mint.
    * @param _to address of the future owner of the token
    */
  function issue(address _to, uint256 _parentId, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply, uint256 _serialNumber) public onlyOwner returns (bool _ok) {
    _ok = false;
    if (_isExclusive) {
        require(_maxISupply == 1);
        require(_serialNumber == 1);
    }
    else {
        require(_serialNumber <= _maxISupply);
    }
    mintTo(_to);
    _updateMetadata(_parentId, now, _endTime, _baseAssetAddress, _baseAssetId, _isExclusive, _maxISupply, _serialNumber);
    _ok = true;
  }

  function revoke(address _from, uint256 _tokenId) public onlyOwner returns (bool _ok) {
    _ok = false;
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "IRT: token does not exist");
    delete metadata[_tokenId];
    _burn(_from, _tokenId);
    _ok = true;
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory) {
    Metadata storage _meta = metadata[_tokenId];
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat(Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat("i/", Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.bool2str(_meta.isExclusive), "/", Strings.uint2str(_meta.maxISupply), "/"),
        Strings.uint2str(_meta.serialNumber)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  function parentId(uint256 _tokenId) external view returns (uint256 _parentId) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "FRT: token does not exist");
    _parentId = _meta.parentId;
  }

  function baseAsset(uint256 _tokenId) external view returns (address _baseAssetAddress, uint256 _baseAssetId) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "IRT: token does not exist");
    _baseAssetAddress = _meta.baseAssetAddress;
    _baseAssetId = _meta.baseAssetId;
  }

}
