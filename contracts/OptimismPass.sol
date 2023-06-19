// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./OptimismBridge.sol";

/*
* OptimismPass is an ERC721 contract that enables users to attach Ether
* to the L1 NFT and send it to others as a gift card. When the funds are redeemed, 
* the Ether will automatically be bridged to Optimism. The purpose of this is 
* to abstract away manual bridging in a fun way and increase L2 adoption.
*/
contract OptimismPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    // _tokenIdCounter is used to assign a unique ID to each token
    Counters.Counter private _tokenIdCounter;

    // _tokenOwners is a mapping of tokeknId to address of owner
    mapping(uint256 => address) private _tokenOwners;

    // _tokenValues is a mapping from tokenId to tokenValue (in Wei)
    mapping(uint256 => uint256) private _tokenValues;

    // _bridgeContract represents the contract to bridge the Ether on L1 to Optimism on L2
    address private _bridgeContract = "TODO";

    constructor() ERC721("OptimismPass", "OPP") {}

    // safeMint mints a token and attaches an Ether amount to it (in Wei)
    function safeMint(address to, uint256 valueInWei) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _tokenValues[tokenId] = valueInWei;
        _tokenOwners[tokenId] = to;
    }

    // redeemValue lets a token owner redeem the attached value by automatically
    // bridging the Ether funds to Optimism
    function redeemValue(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        
        uint256 valueInWei = _tokenValues[tokenId];
        require(valueInWei > 0, "Token does not have a value attached");

        // Delete the token value before bridging to prevent reentrancy attacks
        delete _tokenValues[tokenId];

        // Call the Optimism L1 bridge contract to bridge the Ether to Optimism
        // TODO: figure out how to calculate _l2Gas
        _bridgeContract.depositETHTo(msg.sender, "_l2Gas");
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenOwners[tokenId];
    }

    function getTokenValue(uint256 tokenId) public view returns (uint256) {
        return _tokenValues[tokenId];
    }
}
