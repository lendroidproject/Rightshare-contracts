pragma solidity 0.5.11;

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
  }

  // stores a `Metadata` struct for each IRight.
  mapping(uint256 => Metadata) public metadata;

  constructor() TradeableERC721Token("IRight Token", "IRT", address(0)) public {}

  /**
    * @dev updates token metadata
    */
  function _updateMetadata(uint256 version, uint256 parentId, uint256 startTime, uint256 endTime, address baseAssetAddress, uint256 baseAssetId, bool isExclusive) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = version;
    _meta.parentId = parentId;
    _meta.startTime = startTime;
    _meta.endTime = endTime;
    _meta.baseAssetAddress = baseAssetAddress;
    _meta.baseAssetId = baseAssetId;
    _meta.isExclusive = isExclusive;
  }

  /**
    * @dev Mint IRight Token and update metadata
    * @param addresses : address array [_to, baseAssetAddress]
    * @param values : uint256 array [parentId, endTime, baseAssetId, version]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    */
  function issue(address[2] calldata addresses, bool isExclusive, uint256[4] calldata values) external onlyOwner {
    require(addresses[1].isContract(), "invalid base asset address");
    require(values[0] > 0, "invalid parent id");
    require(values[1] > block.timestamp, "invalid expiry");
    require(values[2] > 0, "invalid base asset id");
    require(values[3] > 0, "invalid version");
    mintTo(addresses[0]);
    _updateMetadata(values[3], values[0], now, values[1], addresses[1], values[2], isExclusive);
  }

  function revoke(address from, uint256 tokenId) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    delete metadata[tokenId];
    _burn(from, tokenId);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat("i/", Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat(Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.bool2str(_meta.isExclusive), "/"),
        Strings.uint2str(_meta.version)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  function parentId(uint256 tokenId) external view returns (uint256) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    return _meta.parentId;
  }

  function baseAsset(uint256 tokenId) external view returns (address baseAssetAddress, uint256 baseAssetId) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    baseAssetAddress = _meta.baseAssetAddress;
    baseAssetId = _meta.baseAssetId;
  }

}
