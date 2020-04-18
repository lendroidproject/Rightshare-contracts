pragma solidity 0.5.11;

import "./TradeableERC721Token.sol";

/**
 * @title Right
 * Right - a contract for NFT Rights
 */
contract Right is TradeableERC721Token {

  string private _apiBaseUrl = "";

  function baseTokenURI() public view returns (string memory) {
    return _apiBaseUrl;
  }

  function setApiBaseUrl(string calldata _url) external onlyOwner {
    _apiBaseUrl = _url;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    require(_proxyRegistryAddress != address(0), "invalid proxy registry address");
    proxyRegistryAddress = _proxyRegistryAddress;
  }

}
