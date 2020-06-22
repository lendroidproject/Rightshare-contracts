// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.10;

import "./Right.sol";


/** @title IRight
  * @author Lendroid Foundation
  * @notice A smart contract for Interim Rights
  * @dev Audit certificate : https://github.com/lendroidproject/Rightshare-contracts/blob/master/audit-report.pdf
  */
contract IRight is Right {
  // This stores metadata about a IRight token
  struct Metadata {
    uint256 version; // version of the IRight
    uint256 parentId; // id of the FRight
    uint256 tokenId; // id of the IRight
    uint256 startTime; // timestamp when the IRight was created
    uint256 endTime; // timestamp until when the IRight is deemed useful
    address baseAssetAddress; // address of original NFT locked in the DAO
    uint256 baseAssetId; // id of original NFT locked in the DAO
    bool isExclusive; // indicates if the IRight is exclusive, aka, is the only IRight for the FRight
  }

  // stores a `Metadata` struct for each IRight.
  mapping(uint256 => Metadata) public metadata;

  constructor() ERC721("IRight Token", "IRT") public {}

  /**
    * @notice Adds metadata about a IRight Token
    * @param version : uint256 representing the version of the IRight
    * @param parentId : uint256 representing the id of the FRight
    * @param startTime : uint256 creation timestamp of the IRight
    * @param endTime : uint256 expiry timestamp of the IRight
    * @param baseAssetAddress : address of original NFT
    * @param baseAssetId : id of original NFT
    * @param isExclusive : bool indicating exclusivity of IRight
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
    * @notice Creates a new IRight Token
    * @dev Mints IRight Token, and updates metadata & currentTokenId
    * @param addresses : address array [_to, baseAssetAddress]
    * @param isExclusive : boolean indicating exclusivity of the FRight Token
    * @param values : uint256 array [parentId, endTime, baseAssetId, version]
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

  /**
    * @notice Revokes a IRight
    * @dev Deletes the metadata and burns the IRight token
    * @param from : address of the IRight owner
    * @param tokenId : uint256 representing the IRight id
    */
  function revoke(address from, uint256 tokenId) external onlyOwner {
    require(tokenId > 0, "invalid token id");
    require(from != address(0), "from address cannot be zero");
    require(from == ownerOf(tokenId), "from address is not owner of tokenId");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    delete metadata[tokenId];
    _burn(tokenId);
  }

  /**
    * @notice Updates the api uri of a IRight token
    * @dev Reconstructs and saves the uri from the FRight metadata
    * @param tokenId : uint256 representing the IRight id
    */
  function _updateTokenURI(uint256 tokenId) private {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    string memory _tokenURI = ExtendedStrings.strConcat(
        ExtendedStrings.strConcat("i/", ExtendedStrings.address2str(_meta.baseAssetAddress), "/", ExtendedStrings.uint2str(_meta.baseAssetId), "/"),
        ExtendedStrings.strConcat(ExtendedStrings.uint2str(_meta.endTime), "/"),
        ExtendedStrings.strConcat(ExtendedStrings.bool2str(_meta.isExclusive), "/"),
        ExtendedStrings.uint2str(_meta.version)
    );
    _setTokenURI(tokenId, _tokenURI);
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
  function baseAsset(uint256 tokenId) external view returns (address baseAssetAddress, uint256 baseAssetId) {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    baseAssetAddress = _meta.baseAssetAddress;
    baseAssetId = _meta.baseAssetId;
  }

}
