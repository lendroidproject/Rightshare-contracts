pragma solidity 0.5.11;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './Strings.sol';

contract OwnableDelegateProxy { }

contract ProxyRegistry is Ownable {
  using Address for address;
  mapping(address => OwnableDelegateProxy) public proxies;

  /**
    * @dev whitelist a proxyContractAddress for the given owner
    * @param owner address
    * @param proxyContractAddress address of proxy Contract
    */
  function setProxy(address owner, address proxyContractAddress) external onlyOwner {
    require(proxyContractAddress.isContract(), "invalid proxy contract address");
    proxies[owner] = OwnableDelegateProxy(proxyContractAddress);
  }
}

/**
 * @title TradeableERC721Token
 * TradeableERC721Token - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract TradeableERC721Token is ERC721Full, Ownable {
  using Strings for string;
  using Address for address;

  address proxyRegistryAddress;
  uint256 private _currentTokenId = 0;

  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) ERC721Full(_name, _symbol) public {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
    * @dev Mints a token to a given address
    * @param _to address of the future owner of the token
    */
  function mintTo(address _to) public onlyOwner {
    require(_to != address(0));
    uint256 newTokenId = _getNextTokenId();
    _mint(_to, newTokenId);
    _incrementTokenId();
  }

  function currentTokenId() public view returns (uint256) {
    return _currentTokenId;
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenId
    * @return uint256 for the next token ID
    */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
    * @dev increments the value of _currentTokenId
    */
  function _incrementTokenId() private  {
    _currentTokenId++;
  }

  function baseTokenURI() public view returns (string memory) {
    return "";
  }

  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    return Strings.strConcat(
        baseTokenURI(),
        Strings.uint2str(_tokenId)
    );
  }

  /**
   * Override isApprovedForAll to whitelist user's proxy accounts (useful for sites such as opensea to enable gas-less listings)
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    require(owner != address(0), "owner address cannot be zero");
    require(operator != address(0), "operator address cannot be zero");
    if (proxyRegistryAddress == address(0)) {
      return super.isApprovedForAll(owner, operator);
    }
    // Check if owner has whitelisted proxy contract
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }
    return super.isApprovedForAll(owner, operator);
  }
}
