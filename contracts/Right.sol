pragma solidity ^0.5.11;

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

  function setApiBaseUrl(string memory _url) public onlyOwner returns (bool) {
    _apiBaseUrl = _url;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner returns (bool _ok) {
    proxyRegistryAddress = _proxyRegistryAddress;
    _ok = true;
  }

}
