// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.10;


import "../../Right.sol";


/**
 * @title PayoutToken
 * @notice ERC721 contract that can withdraw
 */
contract PayoutToken is Right {

  constructor() ERC721("Payout Token", "PYT") public {}

}
