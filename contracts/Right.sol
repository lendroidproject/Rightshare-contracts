pragma solidity 0.5.11;

import "./TradeableERC721Token.sol";


/** @title Right
 * @author Lendroid Foundation
 * @notice A smart contract for NFT Rights
 * @dev Tested with 100% branch coverage. Pending audit certificate.
 */
contract Right is TradeableERC721Token {

  string private _apiBaseUrl = "";

  /**
    * @notice Displays the base api url of the Right token
    * @return string : api url
    */
  function baseTokenURI() public view returns (string memory) {
    return _apiBaseUrl;
  }

  /**
    * @notice set the base api url of the Right token
    * @param url : string representing the api url
    */
  function setApiBaseUrl(string calldata url) external onlyOwner {
    _apiBaseUrl = url;
  }

  /**
    * @notice set the registry address that acts as a proxy for the Right token
    * @param registryAddress : address of the proxy registry
    */
  function setProxyRegistryAddress(address registryAddress) external onlyOwner {
    require(registryAddress != address(0), "invalid proxy registry address");
    proxyRegistryAddress = registryAddress;
  }

}
