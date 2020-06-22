// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.10;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-solidity/contracts/access/Ownable.sol';
import './ExtendedStrings.sol';


/** @title Right
 * @author Lendroid Foundation
 * @notice A smart contract for NFT Rights
 * @dev Audit certificate : https://github.com/lendroidproject/Rightshare-contracts/blob/master/audit-report.pdf
 */
abstract contract Right is ERC721, Ownable {

  using ExtendedStrings for string;

  uint256 private _currentTokenId = 0;

  function _mintTo(address to) internal {
    require(to != address(0), "ERC721: mint to the zero address");
    uint256 newTokenId = _getNextTokenId();
    _mint(to, newTokenId);
    _incrementTokenId();
  }

  /**
    * @notice Allows owner to mint a a token to a given address
    * dev Mints a new token to the given address, increments currentTokenId
    * @param to address of the future owner of the token
    */
  function mintTo(address to) public onlyOwner {
    _mintTo(to);
  }


  function batchMintTo(address[] memory addresses) external {
    for (uint8 i=0; i<addresses.length; i++) {
      _mintTo(addresses[i]);
    }
  }

  /**
    * @notice Displays the id of the latest token that was minted
    * @return uint256 : latest minted token id
    */
  function currentTokenId() public view returns (uint256) {
    return _currentTokenId;
  }

  /**
    * @notice Displays the id of the next token that will be minted
    * @dev Calculates the next token ID based on value of _currentTokenId
    * @return uint256 : id of the next token
    */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
    * @notice Increments the value of _currentTokenId
    * @dev Internal function that increases the value of _currentTokenId by 1
    */
  function _incrementTokenId() private  {
    _currentTokenId = _currentTokenId.add(1);
  }

  /**
    * @notice set the base api url of the Right token
    * @param url : string representing the api url
    */
  function setApiBaseUrl(string memory url) external onlyOwner {
    _setBaseURI(url);
  }

}
