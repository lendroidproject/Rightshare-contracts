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
  function _updateMetadata(uint256 version, uint256 startTime, uint256 endTime, address baseAssetAddress, uint256 baseAssetId, bool isExclusive, uint256 maxISupply, uint256 circulatingISupply) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = version;
    _meta.startTime = startTime;
    _meta.endTime = endTime;
    _meta.baseAssetAddress = baseAssetAddress;
    _meta.baseAssetId = baseAssetId;
    _meta.isExclusive = isExclusive;
    _meta.maxISupply = maxISupply;
    _meta.circulatingISupply = circulatingISupply;
  }

  /**
    * @dev Mint FRight Token and update mateadata
    * @param addresses : address array [_to, baseAssetAddress]
    * @param values : uint256 array [endTime, baseAssetId, maxISupply, version]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    */
  function freeze(address[2] calldata addresses, bool isExclusive, uint256[4] calldata values) external onlyOwner returns (uint256 rightId) {
    rightId = 0;
    require(addresses[1].isContract(), "invalid base asset address");
    require(values[0] > block.timestamp, "invalid expiry");
    require(values[1] > 0, "invalid base asset id");
    require(values[3] > 0, "invalid version");
    require(!isFrozen[addresses[1]][values[1]], "Asset is already frozen");
    isFrozen[addresses[1]][values[1]] = true;
    if (isExclusive) {
        require(values[2] == 1, "invalid maximum I supply");
    }
    else {
      require(values[2] > 1, "invalid maximum I supply");
    }
    mintTo(addresses[0]);
    _updateMetadata(values[3], now, values[0], addresses[1], values[1], isExclusive, values[2], 1);
    rightId = currentTokenId();
  }

  function isUnfreezable(uint256 tokenId) public view returns (bool) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    return (now >= _meta.endTime) || (_meta.circulatingISupply == 0);
  }

  function unfreeze(address from, uint256 tokenId) external onlyOwner {
    require(isUnfreezable(tokenId), "FRT: token is not unfreezable");
    delete isFrozen[metadata[tokenId].baseAssetAddress][metadata[tokenId].baseAssetId];
    delete metadata[tokenId];
    _burn(from, tokenId);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
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

  function incrementCirculatingISupply(uint256 tokenId, uint256 amount) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(_meta.maxISupply.sub(_meta.circulatingISupply) >= amount, "Circulating I Supply cannot be incremented");
    _meta.circulatingISupply = _meta.circulatingISupply.add(amount);
  }

  function decrementCirculatingISupply(uint256 tokenId, uint256 amount) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(_meta.maxISupply.sub(amount) >= _meta.circulatingISupply.sub(amount), "invalid amount");
    _meta.circulatingISupply = _meta.circulatingISupply.sub(amount);
    _meta.maxISupply = _meta.maxISupply.sub(amount);
  }

  function baseAsset(uint256 tokenId) external view returns (address baseAssetAddress, uint256 baseAssetId) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    baseAssetAddress = _meta.baseAssetAddress;
    baseAssetId = _meta.baseAssetId;
  }

  function isIMintAble(uint256 tokenId) external view returns (bool) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(!_meta.isExclusive, "cannot mint exclusive iRight");
    if (_meta.maxISupply.sub(_meta.circulatingISupply) > 0) {
      return true;
    }
    return false;
  }

  function endTimeAndMaxSupply(uint256 tokenId) external view returns (uint256 endTime, uint256 maxISupply) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    endTime = _meta.endTime;
    maxISupply = _meta.maxISupply;
  }
}
