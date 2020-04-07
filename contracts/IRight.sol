pragma solidity ^0.5.11;

import "./Right.sol";

/**
 * @title IRight
 * IRight - a contract for NFT exclusive / non-exclusive Rights.
 */
contract IRight is Right {

  struct Metadata {
    uint256 version;
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
  function _updateMetadata(uint256 _version, uint256 _parentId, uint256 _startTime, uint256 _endTime, address _baseAssetAddress, uint256 _baseAssetId, bool _isExclusive, uint256 _maxISupply, uint256 _serialNumber) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = _version;
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
    * @dev Mint IRight Token and update mateadata
    * @param addresses : address array [_to, _baseAssetAddress]
    * @param values : uint256 array [_parentId, _endTime, _baseAssetId, _maxISupply, _serialNumber, _version]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    */
  function issue(address[2] memory addresses, bool isExclusive, uint256[6] memory values) public onlyOwner returns (bool _ok) {
    _ok = false;
    if (isExclusive) {
        require(values[3] == 1, "IRT: Exclusive token should have maximum supply 1");
        require(values[4] == 1, "IRT: Exclusive token should have serial number 1");
    }
    else {
        require(values[4] <= values[3], "IRT: Serial number cannot be greater than maximum supply");
    }
    mintTo(addresses[0]);
    _updateMetadata(values[5], values[0], now, values[1], addresses[1], values[2], isExclusive, values[3], values[4]);
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

  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "IRT: token does not exist");
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat(Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat("i/", Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.bool2str(_meta.isExclusive), "/", Strings.uint2str(_meta.maxISupply), "/"),
        Strings.strConcat(Strings.uint2str(_meta.serialNumber) , "/"),
        Strings.uint2str(_meta.version)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  function parentId(uint256 _tokenId) external view returns (uint256 _parentId) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "IRT: token does not exist");
    _parentId = _meta.parentId;
  }

  function baseAsset(uint256 _tokenId) external view returns (address _baseAssetAddress, uint256 _baseAssetId) {
    Metadata storage _meta = metadata[_tokenId];
    require(_meta.tokenId == _tokenId, "IRT: token does not exist");
    _baseAssetAddress = _meta.baseAssetAddress;
    _baseAssetId = _meta.baseAssetId;
  }

}
