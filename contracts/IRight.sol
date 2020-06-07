pragma solidity 0.5.11;

import "./Right.sol";


/** @title IRight
  * @author Lendroid Foundation
  * @notice A smart contract for Interim Rights
  * @dev Audit certificate : pending
  */
contract IRight is Right {

  enum Category { NONEXCLUSIVE, EXCLUSIVE, FUN }

  // This stores metadata about a IRight token
  struct Metadata {
    uint256 version; // version of the IRight
    uint256 parentId; // id of the FRight
    uint256 tokenId; // id of the IRight
    uint256 startTime; // timestamp when the IRight was created
    uint256 endTime; // timestamp until when the IRight is deemed useful
    address baseAssetAddress; // address of original NFT locked in the DAO
    uint256 baseAssetId; // id of original NFT locked in the DAO
    Category category; // category of IRight
    string purpose; // purpose for which the IRight can be used
  }

  // stores a `Metadata` struct for each IRight.
  mapping(uint256 => Metadata) public metadata;

  // [address][tokenAddress][tokenId] = tokens owned by address
  mapping(address => mapping(address => mapping(uint256 => Counters.Counter))) public rights;

  constructor() TradeableERC721Token("IRight Token", "IRT", address(0)) public {}

  /**
    * @notice Adds metadata about a IRight Token
    * @param version : uint256 representing the version of the IRight
    * @param parentId : uint256 representing the id of the FRight
    * @param startTime : uint256 creation timestamp of the IRight
    * @param endTime : uint256 expiry timestamp of the IRight
    * @param baseAssetAddress : address of original NFT
    * @param baseAssetId : id of original NFT
    * @param category : category of IRight
    * @param purpose : purpose of IRight
    */
  function _updateMetadata(uint256 version, uint256 parentId, uint256 startTime, uint256 endTime, address baseAssetAddress, uint256 baseAssetId, Category category, string memory purpose) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = version;
    _meta.parentId = parentId;
    _meta.startTime = startTime;
    _meta.endTime = endTime;
    _meta.baseAssetAddress = baseAssetAddress;
    _meta.baseAssetId = baseAssetId;
    _meta.category = category;
    _meta.purpose = purpose;
  }

  /**
    * @notice Creates a new IRight Token
    * @dev Mints IRight Token, and updates metadata & currentTokenId
    * @param addresses : address array [_to, baseAssetAddress]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    * @param values : uint256 array [parentId, endTime, baseAssetId, version]
    */
  function issue(address[2] calldata addresses, bool isExclusive, uint256[4] calldata values) external onlyOwner {
    require(addresses[1].isContract(), "invalid base asset address");
    require(values[1] > block.timestamp, "invalid expiry");
    require(values[2] > 0, "invalid base asset id");
    require(values[3] > 0, "invalid version");
    Category category = Category.FUN;
    if (values[0] > 0) {
      category = isExclusive ? Category.EXCLUSIVE : Category.NONEXCLUSIVE;
    }
    rights[addresses[0]][addresses[1]][values[2]].increment();
    mintTo(addresses[0]);

    _updateMetadata(values[3], values[0], now, values[1], addresses[1], values[2], category, "fun");
  }


  function _burn(address owner, uint256 tokenId) internal {
    require(tokenId > 0, "invalid token id");
    require(owner != address(0), "from address cannot be zero");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    super._burn(owner, tokenId);
    rights[owner][_meta.baseAssetAddress][_meta.baseAssetId].decrement();
    delete metadata[tokenId];
  }

  /**
    * @notice Revokes a IRight
    * @dev Deletes the metadata and burns the IRight token
    * @param from : address of the IRight owner
    * @param tokenId : uint256 representing the IRight id
    */
  function revoke(address from, uint256 tokenId) external onlyOwner {
    _burn(from, tokenId);
  }

  /**
    * @notice Displays the api uri of a IRight token
    * @dev Reconstructs the uri from the FRight metadata
    * @param tokenId : uint256 representing the IRight id
    * @return string : api uri
    */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    string memory _metadataUri = Strings.strConcat(
        Strings.strConcat("i/", Strings.address2str(_meta.baseAssetAddress), "/", Strings.uint2str(_meta.baseAssetId), "/"),
        Strings.strConcat(Strings.uint2str(_meta.endTime), "/"),
        Strings.strConcat(Strings.uint2str(uint(_meta.category)), "/"),
        Strings.uint2str(_meta.version)
    );
    return Strings.strConcat(
        baseTokenURI(),
        _metadataUri
    );
  }

  /**
    * @notice Displays the FRight id of a IRight token
    * @param tokenId : uint256 representing the FRight id
    * @return uint256 : parentId from the IRights metadata
    */
  function parentId(uint256 tokenId) external view returns (uint256) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    return _meta.parentId;
  }

  /**
    * @notice Displays information about the original NFT of a IRight token
    * @param tokenId : uint256 representing the IRight id
    * @return baseAssetAddress : address of original NFT
    * @return baseAssetId : id of original NFT
    */
  function baseAsset(uint256 tokenId) public view returns (address baseAssetAddress, uint256 baseAssetId) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    baseAssetAddress = _meta.baseAssetAddress;
    baseAssetId = _meta.baseAssetId;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    (address baseAssetAddress, uint256 baseAssetId) = baseAsset(tokenId);
    rights[from][baseAssetAddress][baseAssetId].decrement();
    rights[to][baseAssetAddress][baseAssetId].increment();
    _safeTransferFrom(from, to, tokenId, _data);
  }

  function _transferFrom(address from, address to, uint256 tokenId) internal {
    super._transferFrom(from, to, tokenId);
    (address baseAssetAddress, uint256 baseAssetId) = baseAsset(tokenId);
    rights[from][baseAssetAddress][baseAssetId].decrement();
    rights[to][baseAssetAddress][baseAssetId].increment();
  }

  function hasRight(address who, address baseAssetAddress, uint256 baseAssetId) external view returns (bool) {
    return rights[who][baseAssetAddress][baseAssetId].current() > 0;
  }

}
