pragma solidity 0.5.11;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './Strings.sol';

/**
 * @title OwnableDelegateProxy
 * @notice Proxy contract to act on behalf of a user account
 */
contract OwnableDelegateProxy { }

/**
 * @title ProxyRegistry
 * @notice Registry contract to store delegated proxy contracts
 */
contract ProxyRegistry is Ownable {
  using Address for address;
  mapping(address => OwnableDelegateProxy) public proxies;

  /**
    * @notice whitelist a proxyContractAddress for the given owner
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
 * @notice ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract TradeableERC721Token is ERC721Full, Ownable {
  using Strings for string;

  address proxyRegistryAddress;
  uint256 private _currentTokenId = 0;

  constructor(string memory name, string memory symbol, address registryAddress) ERC721Full(name, symbol) public {
    proxyRegistryAddress = registryAddress;
  }

  /**
    * @notice Allows owner to mint a a token to a given address
    * dev Mints a new token to the given address, increments currentTokenId
    * @param to address of the future owner of the token
    */
  function mintTo(address to) public onlyOwner {
    require(to != address(0));
    uint256 newTokenId = _getNextTokenId();
    _mint(to, newTokenId);
    _incrementTokenId();
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
    * @notice Displays the base api url of the NFT
    * dev This function is overridden by Rights contracts which inherit this contract
    * @return string : an empty string
    */
  function baseTokenURI() public view returns (string memory) {
    return "";
  }

  /**
    * @notice Displays the api uri of a NFT
    * @dev Concatenates the base uri to the given tokenId
    * @param tokenId : uint256 representing the NFT id
    * @return string : api uri
    */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return Strings.strConcat(
        baseTokenURI(),
        Strings.uint2str(tokenId)
    );
  }

  /**
     * @notice Tells whether an operator is approved by a given owner.
     * @dev Overrides isApprovedForAll to whitelist user's proxy accounts (useful for sites such as opensea to enable gas-less listings)
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
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
