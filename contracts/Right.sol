pragma solidity ^0.6.0;

import "./TradeableERC721Token.sol";

/**
 * @title Right
 * Right - a contract for NFT Rights
 */
abstract contract Right is TradeableERC721Token {

  string private _apiBaseUrl = "";

  function baseTokenURI() public view override virtual returns (string memory) {
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
