// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.10;

import "../../RightsDao.sol";

/**
 * @title Shop
 * @dev Implements REC Shop.sol
 */
contract Shop is Ownable, ERC721Holder {

    using Address for address;
    using SafeMath for uint256;

    struct Item {
        uint256 id;
        address baseAssetAddress;
        uint256 baseAssetId;
        bool isActive;
        bytes32 hash;
        address fRightAddress;
        uint256 fRightId;
        address owner;
        uint256 totalSupply;
        uint256 maxSupply;
    }

    address payable public payoutContractAddress;

    uint256 public lastId;

    mapping(bytes32 => Item) public items;

    mapping(bytes32 => uint256) public hashToId;

    mapping(uint256 => bytes32) public idToHash;

    constructor(address payable payoutAddress) public {
        payoutContractAddress = payoutAddress;
    }

    function computeHash(address baseAssetAddress, uint256 baseAssetId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(baseAssetAddress, baseAssetId));
    }

    function list(address baseAssetAddress, uint256 baseAssetId, address fRightAddress, uint256 fRightId, uint256 maxSupply) external {
        bytes32 _hash = computeHash(baseAssetAddress, baseAssetId);
        require(hashToId[_hash] == 0, "Id with hash already exists");
        lastId = lastId.add(1);
        hashToId[_hash] = lastId;
        idToHash[lastId] = _hash;
        items[_hash] = Item({
            id: lastId,
            baseAssetAddress: baseAssetAddress,
            baseAssetId: baseAssetId,
            isActive: true,
            hash: _hash,
            fRightAddress: fRightAddress,
            fRightId: fRightId,
            owner: msg.sender,
            totalSupply: 0,
            maxSupply: maxSupply
        });
        // fRight token is transferred to this contract
        FRight(fRightAddress).safeTransferFrom(msg.sender, address(this), fRightId);
    }

    function delist(address baseAssetAddress, uint256 baseAssetId) external {
        bytes32 hashToDelist = computeHash(baseAssetAddress, baseAssetId);
        uint256 idToDelist = hashToId[hashToDelist];
        require(idToDelist > 0, "Id with hash does not exist");
        bytes32 lastItemHash = idToHash[lastId];
        items[lastItemHash].id = idToDelist;
        hashToId[lastItemHash] = idToDelist;
        idToHash[idToDelist] = lastItemHash;
        address fRightOwner = items[hashToDelist].owner;
        address fRightAddress = items[hashToDelist].fRightAddress;
        uint256 fRightId = items[hashToDelist].fRightId;
        delete items[hashToDelist];
        hashToId[hashToDelist] = 0;
        lastId = lastId.sub(1);
        // fRight token is transferred to its owner
        FRight(fRightAddress).safeTransferFrom(address(this), fRightOwner, fRightId);
    }

    function updateItemMaxSupply(address baseAssetAddress, uint256 baseAssetId, uint256 maxSupply) external {
         bytes32 _hash = computeHash(baseAssetAddress, baseAssetId);
         require(items[_hash].hash == _hash, "item does not exist");
         require(maxSupply.sub(items[_hash].totalSupply) >= 0);
         items[_hash].maxSupply = maxSupply;
    }

    function updateItemIsActive(address baseAssetAddress, uint256 baseAssetId, bool isActive) external {
         bytes32 _hash = computeHash(baseAssetAddress, baseAssetId);
         require(items[_hash].hash == _hash, "item does not exist");
         items[_hash].isActive = isActive;
    }

    function isBuyable(address baseAssetAddress, uint256 baseAssetId) public view returns(bool) {
         bytes32 _hash = computeHash(baseAssetAddress, baseAssetId);
         require(items[_hash].hash == _hash, "item does not exist");
         if (!items[_hash].isActive) {
             return false;
         }
        if (items[_hash].maxSupply.sub(items[_hash].totalSupply) <= 0) {
            return false;
        }
        return true;
    }

    function buy(address baseAssetAddress, uint256 baseAssetId, address daoAddress, uint256 iVersion, uint256 expiry) payable external {
         bytes32 _hash = computeHash(baseAssetAddress, baseAssetId);
         require(items[_hash].hash == _hash, "item does not exist");
         // update item
         require(isBuyable(baseAssetAddress, baseAssetId), "item is not buyable");
         items[_hash].totalSupply = items[_hash].totalSupply.add(1);
         // mint an i right to the msg.sender
         RightsDao(daoAddress).issueI([items[_hash].fRightId, expiry, iVersion]);
         // msg.value is routed to the payout contract address
         payoutContractAddress.transfer(msg.value);

    }
 }
