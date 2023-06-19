// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
* OptimismPass is an ERC721 contract that enables users to attach Ether
* to the L1 NFT and send it to others as a gift card. When the funds are redeemed, 
* the Ether will automatically be bridged to Optimism. The purpose of this is 
* to abstract away manual bridging in a fun way and increase L2 adoption.
*/
contract OptimismPass is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    // _tokenIdCounter is used to assign a unique ID to each token
    Counters.Counter private _tokenIdCounter;

    // _tokenOwners is a mapping of tokenId to address of owner
    mapping(uint256 => address) private _tokenOwners;

    // _tokenValues is a mapping from tokenId to tokenValue (in Wei)
    mapping(uint256 => uint256) private _tokenValues;

    // _bridgeContract represents the contract to bridge the Ether on L1 to Optimism on L2
    address private _bridgeContract = "TODO";

    constructor() ERC721("OptimismPass", "OPP") {}

    /*
    * @dev safeMint mints a token and attaches an Ether amount (in Wei) and uri to it.
    * @param uri is the reference to the image that is displayed on this token
    */
    function safeMint(string memory uri) public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        _tokenValues[tokenId] = msg.value;
        _tokenOwners[tokenId] = msg.sender;
    }

    /*
    * @dev redeemValue lets a token owner redeem the attached value by automatically
    * bridging the Ether funds to Optimism.
    * @param tokenId is unique Id that refers to this token
    * @param l2Gas is the gas limit required to complete the deposit on L2
    */
    function redeemValue(uint256 tokenId, uint32 l2Gas) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        
        uint256 valueInWei = _tokenValues[tokenId];
        require(valueInWei > 0, "Token does not have a value attached");
        require(address(this).balance >= valueInWei, "Insufficient balance");

        // Set tokenValue to 0
        _tokenValues[tokenId] = 0;

        // Call the Optimism L1 bridge contract so the token owner can redeem the funds on L2
        (bool success,) = payable(_bridgeContract).call{value: valueInWei}(
            abi.encodeWithSignature(
                "depositETHTo(address,uint32,bytes)", 
                msg.sender, 
                l2Gas, 
                ""
            )
        );

        require(success, "Failed to bridge funds to Optimism");
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenOwners[tokenId];
    }

    function getTokenValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenValues[tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
