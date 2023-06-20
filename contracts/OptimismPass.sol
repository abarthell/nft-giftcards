// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
* @title OptimismPass
* @notice OptimismPass is an ERC721 contract that enables users to attach Ether
*         to the L1 NFT and send it to others as a gift card. When the funds are redeemed, 
*         the Ether will automatically be bridged to Optimism. The purpose of this is 
*         to abstract away manual bridging in a fun way and increase L2 adoption.
*/
contract OptimismPass is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    // @notice tokenIdCounter is used to assign a unique ID to each token
    Counters.Counter private tokenIdCounter;

    // @notice tokenValues is a mapping from tokenId to tokenValue (in Wei)
    mapping(uint256 => uint256) private tokenValues;

    // @notice bridgeContract represents the contract to bridge the Ether on L1 to Optimism on L2
    address private bridgeContract = "TODO";

    constructor() ERC721("OptimismPass", "OPP") {}

    /*
    * @notice safeMint mints a token and attaches an Ether amount (in Wei) and uri to it.
    *
    * @param _uri is the reference to a JSON file that represents the associated metadata
    */
    function safeMint(string memory _uri) public payable {
        require(msg.value > 0, "Token must have positive ether value attached");
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _uri);

        tokenValues[tokenId] = msg.value;
    }

    /*
    * @notice redeemValue lets a token owner redeem the attached value by automatically
    * bridging the Ether funds to Optimism.
    *
    * @param _tokenId is the unique Id that refers to this token
    * @param _l2Gas is the gas limit required to complete the deposit on L2
    */
    function redeemValue(uint256 _tokenId, uint32 _l2Gas) public {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the token owner");
        
        uint256 valueInWei = tokenValues[_tokenId];
        require(valueInWei > 0, "Token does not have a value attached");
        require(address(this).balance >= valueInWei, "Insufficient balance");

        // @notice Clear the token's associated balance
        tokenValues[_tokenId] = 0;

        // @notice Call the Optimism L1 bridge contract so the token owner can redeem the funds on L2
        (bool success,) = payable(bridgeContract).call{value: valueInWei}(
            abi.encodeWithSignature(
                "depositETHTo(address,uint32,bytes)", 
                msg.sender, 
                _l2Gas, 
                ""
            )
        );

        require(success, "Failed to bridge funds to Optimism");
    }

    /*
    * @notice getTokenValue returns the ether amount in Wei that is attached to this token.
    *
    * @param _tokenId is the unique Id that refers to this token
    */
    function getTokenValue(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return tokenValues[_tokenId];
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
