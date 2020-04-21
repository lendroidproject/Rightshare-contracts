pragma solidity 0.5.11;

import "./Right.sol";


/** @title FRight
  * @author Lendroid Foundation
  * @notice A smart contract for Frozen Rights
  * @dev Tested with 100% branch coverage. Pending audit certificate.
  */
contract FRight is Right {
  // This stores metadata about a FRight token
  struct Metadata {
    uint256 version; // version of the FRight
    uint256 tokenId; // id of the FRight
    uint256 startTime; // timestamp when the FRight was created
    uint256 endTime; // timestamp until when the FRight is deemed useful
    address baseAssetAddress; // address of original NFT locked in the DAO
    uint256 baseAssetId; // id of original NFT locked in the DAO
    bool isExclusive; // indicates if the FRight is exclusive, aka, has only one IRight
    uint256 maxISupply; // maximum summply of IRights for this FRight
    uint256 circulatingISupply; // circulating summply of IRights for this FRight
  }

  // stores a Metadata struct for each FRight.
  mapping(uint256 => Metadata) public metadata;
  // stores information of original NFTs
  mapping(address => mapping(uint256 => bool)) public isFrozen;

  constructor() TradeableERC721Token("FRight Token", "FRT", address(0)) public {}

  /**
    * @notice Adds metadata about a FRight Token
    * @param version : uint256 representing the version of the FRight
    * @param startTime : uint256 creation timestamp of the FRight
    * @param endTime : uint256 expiry timestamp of the FRight
    * @param baseAssetAddress : address of original NFT
    * @param baseAssetId : id of original NFT
    * @param maxISupply : uint256 indicating maximum summply of IRights
    * @param circulatingISupply : uint256 indicating circulating summply of IRights
    */
  function _updateMetadata(uint256 version, uint256 startTime, uint256 endTime, address baseAssetAddress, uint256 baseAssetId, uint256 maxISupply, uint256 circulatingISupply) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.version = version;
    _meta.startTime = startTime;
    _meta.endTime = endTime;
    _meta.baseAssetAddress = baseAssetAddress;
    _meta.baseAssetId = baseAssetId;
    _meta.isExclusive = maxISupply == 1;
    _meta.maxISupply = maxISupply;
    _meta.circulatingISupply = circulatingISupply;
  }

  /**
    * @notice Creates a new FRight Token
    * @dev Mints FRight Token, and updates metadata & currentTokenId
    * @param addresses : address array [_to, baseAssetAddress]
    * @param values : uint256 array [endTime, baseAssetId, maxISupply, version]
    * @return uint256 : updated currentTokenId
    */
  function freeze(address[2] calldata addresses, uint256[4] calldata values) external onlyOwner returns (uint256) {
    require(addresses[1].isContract(), "invalid base asset address");
    require(values[0] > block.timestamp, "invalid expiry");
    require(values[1] > 0, "invalid base asset id");
    require(values[2] > 0, "invalid maximum I supply");
    require(values[3] > 0, "invalid version");
    require(!isFrozen[addresses[1]][values[1]], "Asset is already frozen");
    isFrozen[addresses[1]][values[1]] = true;
    mintTo(addresses[0]);
    _updateMetadata(values[3], now, values[0], addresses[1], values[1], values[2], 1);
    return currentTokenId();
  }

  /**
    * @notice Checks if a FRight can be unfrozen
    * @dev Returns true if the FRight either has expired, or has 0 circulating supply of IRights
    * @param tokenId : uint256 representing the FRight id
    * @return bool : indicating if the FRight can be unfrozen
    */
  function isUnfreezable(uint256 tokenId) public view returns (bool) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    return (now >= _meta.endTime) || (_meta.circulatingISupply == 0);
  }

  /**
    * @notice Unfreezes a FRight
    * @dev Deletes the metadata and burns the FRight token
    * @param tokenId : uint256 representing the FRight id
    */
  function unfreeze(address from, uint256 tokenId) external onlyOwner {
    require(isUnfreezable(tokenId), "FRT: token is not unfreezable");
    require(from != address(0), "from address cannot be zero");
    delete isFrozen[metadata[tokenId].baseAssetAddress][metadata[tokenId].baseAssetId];
    delete metadata[tokenId];
    _burn(from, tokenId);
  }

  /**
    * @notice Displays the api uri of a FRight token
    * @dev Reconstructs the uri from the FRight metadata
    * @param tokenId : uint256 representing the FRight id
    * @return string : api uri
    */
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

  /**
    * @notice Increment circulating supply of IRights for a FRight
    * @dev Update circulatingISupply of the FRight metadata
    * @param tokenId : uint256 representing the FRight id
    * @param amount : uint256 indicating increment amount
    */
  function incrementCirculatingISupply(uint256 tokenId, uint256 amount) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    require(amount > 0, "amount cannot be zero");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(_meta.maxISupply.sub(_meta.circulatingISupply) >= amount, "Circulating I Supply cannot be incremented");
    _meta.circulatingISupply = _meta.circulatingISupply.add(amount);
  }

  /**
    * @notice Decrement circulating supply of IRights for a FRight
    * @dev Decrement circulatingISupply and maxISupply of the FRight metadata
    * @param tokenId : uint256 representing the FRight id
    * @param amount : uint256 indicating decrement amount
    */
  function decrementCirculatingISupply(uint256 tokenId, uint256 amount) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    require(amount > 0, "amount cannot be zero");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(_meta.maxISupply.sub(amount) >= _meta.circulatingISupply.sub(amount), "invalid amount");
    _meta.circulatingISupply = _meta.circulatingISupply.sub(amount);
    _meta.maxISupply = _meta.maxISupply.sub(amount);
  }

  /**
    * @notice Displays information about the original NFT of a FRight token
    * @param tokenId : uint256 representing the FRight id
    * @return baseAssetAddress : address of original NFT
    * @return baseAssetId : id of original NFT
    */
  function baseAsset(uint256 tokenId) external view returns (address baseAssetAddress, uint256 baseAssetId) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    baseAssetAddress = _meta.baseAssetAddress;
    baseAssetId = _meta.baseAssetId;
  }

  /**
    * @notice Displays if a IRight can be minted from the given FRight
    * @param tokenId : uint256 representing the FRight id
    * @return bool : indicating if a IRight can be minted
    */
  function isIMintable(uint256 tokenId) external view returns (bool) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    require(!_meta.isExclusive, "cannot mint exclusive iRight");
    if (_meta.maxISupply.sub(_meta.circulatingISupply) > 0) {
      return true;
    }
    return false;
  }

  /**
    * @notice Displays the expiry of a FRight token
    * @param tokenId : uint256 representing the FRight id
    * @return uint256 : expiry as a timestamp
    */
  function endTime(uint256 tokenId) external view returns (uint256) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "FRT: token does not exist");
    return _meta.endTime;
  }
}
