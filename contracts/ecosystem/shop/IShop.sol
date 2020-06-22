// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.10;

/**
 * @title Shop
 * @dev Implements REC Shop.sol
 */

interface IShop {

  function list(address baseAssetAddress, uint256 baseAssetId, address fRightAddress, uint256 fRightId, uint256 maxSupply) external;

  function delist(address baseAssetAddress, uint256 baseAssetId) external;

  function isBuyable(address baseAssetAddress, uint256 baseAssetId) external view returns(bool);

  function buy(address baseAssetAddress, uint256 baseAssetId, address daoAddress, uint256 iVersion, uint256 expiry) payable external;

}
